// supabase/functions/sv_run_pipeline/index.ts
// 
// PIPELINE OVERVIEW
// =================
// This edge function orchestrates the complete audio processing pipeline:
// 1. UI Entrypoints: 
//    - Upload Audio File (via AuthoritativeUploadService)
//    - Record Live (via RecordingScreen._stop())
// 2. Storage: Files uploaded to Supabase Storage bucket 'recordings' with path pattern:
//    recordings/<userId>/YYYY/MM/DD/timestamp-traceId-filename.ext
// 3. Deepgram: Transcribes audio using Pre-Recorded API with smart formatting
// 4. OpenAI: Summarizes transcript using GPT-4o-mini with structured JSON output
// 5. Resend: Sends summary email to user (if notifyEmail provided)
// 6. Status Flow: local -> uploading -> transcribing -> summarizing -> ready (or error)
//
// ERROR HANDLING:
// - Deepgram errors: Surface as 'error' status with last_error message
// - Pipeline failures: Logged with trace ID for debugging
// - Email failures: Non-blocking, logged but don't fail pipeline
//
// Pipeline: Storage -> Deepgram transcript -> OpenAI summary -> DB updates
// Enhanced for universal ingestion with fallback transcoding

import 'jsr:@supabase/functions-js/edge-runtime.d.ts';
import { createClient } from 'jsr:@supabase/supabase-js@2';
import { sendSummaryEmail } from './send_email.ts';

type RunBody = {
  storage_path: string;     // e.g. 'recordings/<uid>/YYYY/MM/DD/xyz.m4a'
  recording_id: string;     // UUID of public.recordings row
  run_id?: string;          // optional correlator
  trace_id?: string;        // for tracing
  notify_email?: string;    // email to send summary to
};

const OPENAI_API_KEY = Deno.env.get("OPENAI_API_KEY")!;
const DEEPGRAM_API_KEY = Deno.env.get("DEEPGRAM_API_KEY")!;
const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SERVICE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

const cors = { 
  'access-control-allow-origin': '*', 
  'access-control-allow-headers': 'authorization, x-client-info, apikey, content-type, x-trace-id, x-path' 
};

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: cors });

  const exec = Deno.env.get('SB_EXECUTION_ID') ?? null;
  const trace = req.headers.get('x-trace-id') ?? `${Date.now().toString(36)}-${Math.random().toString(36).slice(2,7)}`;
  console.log('[sv_run_pipeline] boot', { exec, trace });

  const pathOverride = req.headers.get('x-path');
  if (req.method === 'GET' || pathOverride === '/health') {
    console.log('[sv_run_pipeline] health', { exec, trace });
    return new Response(JSON.stringify({ ok: true, exec, trace, ts: Date.now() }), { 
      headers: { ...cors, 'content-type': 'application/json' } 
    });
  }

  // Define traceContext as a const object to ensure it's always accessible
  // This avoids ReferenceError issues - the object is always in scope, we just update its value property
  const traceContext = { value: trace };
  
  try {
    // Log incoming method and headers (omit auth token)
    const headers = Object.fromEntries(req.headers);
    delete headers.authorization; // Remove auth token from logs
    console.log('[sv_run_pipeline] request', { 
      method: req.method, 
      headers, 
      trace 
    });

    const supabase = createClient(
      Deno.env.get('SUPABASE_URL')!, 
      Deno.env.get('SUPABASE_ANON_KEY')!,
      { global: { headers: { Authorization: req.headers.get('Authorization') ?? '' } } }
    );

    const { data: { user } } = await supabase.auth.getUser();
    console.log('[sv_run_pipeline] auth', { hasUser: !!user, trace });

    const adminClient = createClient(SUPABASE_URL, SERVICE_KEY, {
      auth: { persistSession: false },
    });

    const body = await req.json().catch(() => ({} as any));

    // accept snake_case or camelCase from clients
    let recordingId = body.recording_id ?? body.recordingId ?? null;
    let storagePath = body.storage_path ?? body.storagePath ?? null;
    const runId = body.run_id ?? body.runId ?? null;
    const traceId = body.trace_id ?? body.traceId ?? trace;
    // Accept summary_style_key, summary_style, or summaryStyle (for backward compatibility)
    const summaryStyleKey = (body.summary_style_key ?? body.summary_style ?? body.summaryStyle ?? 'quick_recap_action_items') as string;
    console.log('[sv_run_pipeline] summary_style_key from client:', summaryStyleKey);
    // Update traceContext.value with the actual traceId from body or fallback to trace
    // This ensures it's always in scope for error handling and logging
    traceContext.value = traceId || trace;
    // Use provided notifyEmail, or fallback to authenticated user's email
    let notifyEmail = body.notify_email ?? body.notifyEmail ?? null;
    if (!notifyEmail && user?.email) {
      notifyEmail = user.email;
      console.log('[sv_run_pipeline] Using authenticated user email for notifications', { email: notifyEmail, trace: traceContext.value });
    }

    console.log('[sv_run_pipeline] body', {
      keys: Object.keys(body || {}),
      has_storage_path: !!storagePath,
      recording_id: recordingId,
      run_id: runId,
      trace,
      summary_style: summaryStyleKey
    });

    // If we have recordingId but not storagePath, fetch it from DB (self-heal)
    if (!storagePath && recordingId) {
      try {
        const { data: rec, error: recErr } = await adminClient
          .from('recordings')
          .select('storage_path')
          .eq('id', recordingId)
          .maybeSingle();
        if (recErr) throw recErr;
        if (rec?.storage_path) {
          storagePath = rec.storage_path as string;
          console.log('[sv_run_pipeline] filled storage_path from DB', { trace: traceContext.value });
        }
      } catch (e) {
        console.log('[sv_run_pipeline] storage_path lookup failed', { error: (e as Error)?.message, trace: traceContext.value });
      }
    }

    storagePath = normalizeStoragePath(storagePath);

    // Validate required parameters (after self-heal)
    if (!storagePath || !recordingId) {
      console.log('[sv_run_pipeline] validation_failed', {
        hasStoragePath: !!storagePath,
        hasRecordingId: !!recordingId,
        trace: traceContext.value
      });
      return new Response(JSON.stringify({
        ok: false,
        code: 'missing_params',
        message: 'Missing storage_path or recording_id',
        trace: traceContext.value
      }), {
        status: 400,
        headers: { ...cors, 'content-type': 'application/json' }
      });
    }

    // Parse bucket/object from storagePath
    const [bucket, ...rest] = storagePath.split('/');
    const objectName = rest.join('/');
    if (bucket !== 'recordings' || !objectName) {
      console.log('[sv_run_pipeline] invalid_storage_path', { bucket, objectName, trace: traceContext.value });
      return new Response(JSON.stringify({
        ok: false,
        code: 'invalid_path',
        message: "storage_path must start with 'recordings/'",
        trace: traceContext.value
      }), {
        status: 400,
        headers: { ...cors, 'content-type': 'application/json' }
      });
    }

    console.log('[sv_run_pipeline] pipeline_start', {
      recording_id: recordingId,
      storage_path: storagePath,
      run_id: runId,
      trace: traceContext.value
    });

    const pipelineRunId = crypto.randomUUID();

    // Verify recording exists before starting pipeline
    console.log('[sv_run_pipeline] step:verify_recording start', { recording_id: recordingId, trace: traceContext.value });
    const { data: recording, error: recordingError } = await adminClient
      .from("recordings")
      .select("id, status, storage_path, user_id")
      .eq("id", recordingId)
      .maybeSingle();
    
    if (recordingError) {
      console.error('[sv_run_pipeline] step:verify_recording error', { 
        error: recordingError.message, 
        recording_id: recordingId, 
        trace: traceContext.value 
      });
      return new Response(JSON.stringify({
        ok: false,
        code: 'recording_lookup_failed',
        message: `Failed to lookup recording: ${recordingError.message}`,
        trace: traceContext.value
      }), {
        status: 500,
        headers: { ...cors, 'content-type': 'application/json' }
      });
    }
    
    if (!recording) {
      console.error('[sv_run_pipeline] step:verify_recording not_found', { 
        recording_id: recordingId, 
        trace: traceContext.value 
      });
      return new Response(JSON.stringify({
        ok: false,
        code: 'recording_not_found',
        message: `Recording not found with id: ${recordingId}`,
        trace: traceContext.value
      }), {
        status: 404,
        headers: { ...cors, 'content-type': 'application/json' }
      });
    }
    
    console.log('[sv_run_pipeline] step:verify_recording ok', { 
      recording_id: recordingId, 
      current_status: recording.status, 
      storage_path: recording.storage_path,
      trace: traceContext.value 
    });

    const { error: runError } = await adminClient.from('pipeline_runs').insert({
      id: pipelineRunId,
      recording_id: recordingId,
      user_id: recording.user_id,
      stage: 'queued',
      progress: 0,
      step: 0,
      trace_id: traceContext.value,
    });
    
    if (runError) {
      console.error('[sv_run_pipeline] pipeline_run creation failed', { error: runError, trace: traceContext.value });
      throw new Error(`Pipeline run creation failed: ${runError.message}`);
    }
    
    console.log('[sv_run_pipeline] pipeline_run created', { run_id: pipelineRunId, trace: traceContext.value });

    // 0) Mark uploading (pipeline started)
    console.log('[sv_run_pipeline] step:status_uploading start', { 
      recording_id: recordingId, 
      storage_path: storagePath, 
      trace 
    });
    const startUploading = Date.now();
    await setStatus(adminClient, recordingId, "uploading", trace, 1, 0.15);
    console.log('[sv_run_pipeline] step:status_uploading ok', { ms: Date.now() - startUploading, trace });

    // 1) Mark transcribing
    console.log('[sv_run_pipeline] step:status_transcribing start', { 
      recording_id: recordingId, 
      storage_path: storagePath, 
      trace 
    });
    const startTranscribing = Date.now();
    await setStatus(adminClient, recordingId, "transcribing", trace, 2, 0.45);
    console.log('[sv_run_pipeline] step:status_transcribing ok', { ms: Date.now() - startTranscribing, trace });

    // 2) Create a signed URL and hand it to Deepgram
    console.log('[sv_run_pipeline] step:signed_url start', { trace });
    const startSignedUrl = Date.now();
    const signed = await signedUrl(adminClient, objectName, 60 * 60, trace); // 1 hour
    console.log('[sv_run_pipeline] step:signed_url ok', { ms: Date.now() - startSignedUrl, trace });

    console.log('[sv_run_pipeline] step:deepgram_transcribe start', { trace });
    const startDeepgram = Date.now();
    const transcriptResult = await deepgramTranscribeWithFallback(signed, trace, adminClient, recordingId, storagePath);
    console.log('[sv_run_pipeline] step:deepgram_transcribe ok', { ms: Date.now() - startDeepgram, trace });

    // Save transcript to database
    console.log('[sv_run_pipeline] step:save_transcript start', { trace });
    const startSaveTranscript = Date.now();
    await adminClient.from("transcripts").insert({ recording_id: recordingId, text: transcriptResult.transcript });
    console.log('[sv_run_pipeline] step:save_transcript ok', { ms: Date.now() - startSaveTranscript, trace });

    // 3) Mark summarizing
    console.log('[sv_run_pipeline] step:status_summarizing start', { trace });
    const startSummarizing = Date.now();
    await setStatus(adminClient, recordingId, "summarizing", trace, 4, 0.75);
    console.log('[sv_run_pipeline] step:status_summarizing ok', { ms: Date.now() - startSummarizing, trace });

    // 4) Summarize with OpenAI (structured JSON)
    console.log('[sv_run_pipeline] step:openai_summarize start', { trace });
    const startOpenAI = Date.now();
    const summary = await openaiSummarize(transcriptResult.transcript, summaryStyleKey, trace);
    console.log('[sv_run_pipeline] step:openai_summarize ok', { ms: Date.now() - startOpenAI, trace });

    // 4) Write summary & flip to ready
    console.log('[sv_run_pipeline] step:save_summary start', { trace });
    const startSaveSummary = Date.now();
    await upsertSummary(adminClient, recordingId, summary, summaryStyleKey, trace);
    console.log('[sv_run_pipeline] step:save_summary ok', { ms: Date.now() - startSaveSummary, trace });

    // Mark as ready (completed) - keep status simple, valid enum values only
    console.log('[sv_run_pipeline] step:status_ready start', { trace });
    const startReady = Date.now();
    await setStatus(adminClient, recordingId, "ready", trace, 5, 1.0);
    console.log('[sv_run_pipeline] step:status_ready ok', { ms: Date.now() - startReady, trace });

    console.log('[sv_run_pipeline] pipeline_complete', { recording_id: recordingId, trace });

    // Send email notification if requested
    let messageId: string | null = null;
    if (notifyEmail) {
      try {
        // Validate email format
        const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
        if (!emailRegex.test(notifyEmail)) {
          console.log('[sv_run_pipeline] invalid_email', { notifyEmail, trace: traceContext.value });
          return new Response(JSON.stringify({
            ok: false,
            code: 'invalid_email',
            message: 'Invalid email format',
            trace: traceContext.value
          }), {
            status: 400,
            headers: { ...cors, 'content-type': 'application/json' }
          });
        }

        // traceContext.value is always accessible - use it
        const emailTraceId = traceContext.value || traceId || trace;
        
        // Build email content from summary
        const subject = `Your SmartVoiceNotes summary — ${summary.title}`;
        
        const html = `
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>${summary.title}</title>
</head>
<body style="font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; line-height: 1.6; color: #333; max-width: 600px; margin: 0 auto; padding: 20px;">
  <h1 style="color: #2563eb; margin-bottom: 20px;">${summary.title}</h1>
  
  <div style="background: #f8fafc; padding: 20px; border-radius: 8px; margin-bottom: 20px;">
    <h2 style="margin-top: 0; color: #1e293b;">Summary</h2>
    <p style="margin: 0;">${summary.summary}</p>
  </div>

  ${summary.bullets.length > 0 ? `
  <div style="margin-bottom: 20px;">
    <h3 style="color: #1e293b; margin-bottom: 10px;">Key Points</h3>
    <ul style="margin: 0; padding-left: 20px;">
      ${summary.bullets.map((bullet: any) => `<li style="margin-bottom: 5px;">${bullet}</li>`).join('')}
    </ul>
  </div>
  ` : ''}

  ${summary.action_items.length > 0 ? `
  <div style="margin-bottom: 20px;">
    <h3 style="color: #1e293b; margin-bottom: 10px;">Action Items</h3>
    <ul style="margin: 0; padding-left: 20px;">
      ${summary.action_items.map((item: any) => `<li style="margin-bottom: 5px;">${item}</li>`).join('')}
    </ul>
  </div>
  ` : ''}

  ${summary.tags.length > 0 ? `
  <div style="margin-bottom: 20px;">
    <h3 style="color: #1e293b; margin-bottom: 10px;">Tags</h3>
    <div>
      ${summary.tags.map((tag: any) => `<span style="background: #e2e8f0; color: #475569; padding: 4px 8px; border-radius: 4px; font-size: 12px; margin-right: 8px; display: inline-block; margin-bottom: 4px;">${tag}</span>`).join('')}
    </div>
  </div>
  ` : ''}

  <hr style="border: none; border-top: 1px solid #e2e8f0; margin: 30px 0;">
  <p style="font-size: 12px; color: #64748b; margin: 0;">
    Generated by SmartVoiceNotes • Trace ID: ${emailTraceId}
  </p>
</body>
</html>`;

        const text = `
${summary.title}

Summary:
${summary.summary}

${summary.bullets.length > 0 ? `Key Points:\n${summary.bullets.map((bullet: any) => `• ${bullet}`).join('\n')}\n` : ''}

${summary.action_items.length > 0 ? `Action Items:\n${summary.action_items.map((item: any) => `• ${item}`).join('\n')}\n` : ''}

${summary.tags.length > 0 ? `Tags: ${summary.tags.join(', ')}\n` : ''}

---
Generated by SmartVoiceNotes • Trace ID: ${emailTraceId}
`;

        const emailResult = await sendSummaryEmail({
          to: notifyEmail,
          subject,
          html,
          text,
          traceId: emailTraceId,
          replyTo: "support@updates.smartvoicenotes.com"
        });

        messageId = emailResult.id;
        console.log('[EMAIL] delivered', { traceId: emailTraceId, messageId, to: notifyEmail });
      } catch (emailError) {
        // Email failures are non-blocking - log but don't fail the pipeline
        // The recording is already processed and saved successfully
        // traceContext.value is always accessible
        const emailErrorTraceId = traceContext.value || traceId || trace;
        console.error('[EMAIL] failed (non-blocking)', { 
          traceId: emailErrorTraceId, 
          to: notifyEmail, 
          err: emailError instanceof Error ? emailError.message : String(emailError) 
        });
        // Continue pipeline - email failure doesn't affect transcription/summarization success
      }
    }

    // Ensure we have a valid trace ID for the response
    // Use safe access pattern to avoid ReferenceError
    // traceContext.value is always accessible
    const responseTraceId = traceContext.value || traceId || trace;
    return new Response(JSON.stringify({ 
      ok: true, 
      trace: responseTraceId, 
      recording_id: recordingId,
      runId: pipelineRunId, // Add the pipeline run ID for UI streaming
      ...(messageId && { messageId })
    }), { 
      headers: { ...cors, 'content-type': 'application/json' } 
    });

  } catch (e) {
    // Safely get trace ID - use helper function to avoid ReferenceError
    // Access variables in order of scope to avoid ReferenceError
    // traceContext.value is always accessible (const object defined before try block)
    const errorTraceId = traceContext.value || trace;
    const errorMessage = e instanceof Error ? e.message : String(e);
    console.error('[sv_run_pipeline] error', { 
      msg: errorMessage, 
      trace: errorTraceId,
      stack: e instanceof Error ? e.stack : undefined
    });
    return new Response(JSON.stringify({ 
      ok: false, 
      code: 'unhandled', 
      message: errorMessage, 
      trace: errorTraceId
    }), { 
      status: 500, 
      headers: { ...cors, 'content-type': 'application/json' } 
    });
  }
});

// ---------- Helpers ----------

function normalizeStoragePath(path?: string | null): string | null {
  if (typeof path !== 'string') return null;
  let normalized = path.trim();
  if (!normalized) return null;
  normalized = normalized.replace(/^\/+/, '');
  if (!normalized.startsWith('recordings/')) {
    normalized = `recordings/${normalized}`;
  }
  normalized = normalized.replace(/\/{2,}/g, '/');
  return normalized;
}

async function setStatus(client: any, recordingId: string, status: "uploading" | "transcribing" | "summarizing" | "ready" | "error", trace: string, step: number = 1, progress?: number) {
  try {
    // First check if the recording exists
    const { data: existingRecording, error: checkError } = await client
      .from("recordings")
      .select("id, status")
      .eq("id", recordingId)
      .maybeSingle();
    
    if (checkError) {
      throw new Error(`Failed to check recording existence: ${checkError.message}`);
    }
    
    if (!existingRecording) {
      throw new Error(`Recording not found with id: ${recordingId}`);
    }
    
    console.log('[sv_run_pipeline] setStatus', { 
      recording_id: recordingId, 
      current_status: existingRecording.status, 
      new_status: status, 
      step,
      progress,
      trace 
    });
    
    // Update the recordings status with timestamp for Realtime events
    const { error: recordingsError } = await client
      .from("recordings")
      .update({ 
        status,
        status_changed_at: new Date().toISOString()
      })
      .eq("id", recordingId);
    if (recordingsError) throw new Error(`DB status update failed: ${recordingsError.message}`);
    
    // Update pipeline_runs for UI state streaming
    const { error: runsError } = await client
      .from("pipeline_runs")
      .update({
        stage: status,
        progress: progress ?? getDefaultProgress(status),
        step: step,
        updated_at: new Date().toISOString()
      })
      .eq("recording_id", recordingId)
      .order("created_at", { ascending: false })
      .limit(1);
    
    if (runsError) {
      console.warn('[sv_run_pipeline] pipeline_runs update failed', { error: runsError.message, trace });
      // Don't throw - this is for UI only
    }
    
    console.log('[sv_run_pipeline] setStatus success', { recording_id: recordingId, status, step, progress, trace });
  } catch (e) {
    console.error('[sv_run_pipeline] step:setStatus fail', { 
      error: (e as Error)?.message, 
      recording_id: recordingId, 
      status, 
      trace 
    });
    throw e;
  }
}

// Helper function to get default progress for each stage
function getDefaultProgress(status: string): number {
  switch (status) {
    case 'uploading': return 0.15;
    case 'transcribing': return 0.45;
    case 'summarizing': return 0.75;
    case 'ready': return 1.0;
    case 'error': return 0.0;
    default: return 0.0;
  }
}

async function signedUrl(client: any, objectName: string, expiresIn: number, trace: string) {
  try {
    const { data, error } = await client.storage.from('recordings').createSignedUrl(objectName, expiresIn);
    if (error || !data?.signedUrl) throw new Error(`Signed URL failed: ${error?.message}`);
    return data.signedUrl;
  } catch (e) {
    console.error('[sv_run_pipeline] step:signedUrl fail', { error: (e as Error)?.message, trace });
    throw e;
  }
}

async function deepgramTranscribeWithFallback(fileUrl: string, trace: string, adminClient: any, recordingId: string, storagePath: string): Promise<{ transcript: string; confidence?: number }> {
  try {
    // Deepgram remote URL transcription with smart_format
    const resp = await fetch("https://api.deepgram.com/v1/listen?model=nova-2&smart_format=true", {
      method: "POST",
      headers: {
        "Authorization": `Token ${DEEPGRAM_API_KEY}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({ url: fileUrl }),
    });
    
    if (!resp.ok) {
      const text = await resp.text();
      
      // Check if it's an unsupported format error
      if (resp.status === 400 && (text.includes('unsupported') || text.includes('invalid'))) {
        console.log('[sv_run_pipeline] unsupported format, triggering fallback transcode', { trace });
        
        // Trigger fallback transcode
        try {
          await triggerFallbackTranscode(adminClient, recordingId, storagePath, trace);
        } catch (transcodeError) {
          console.error('[sv_run_pipeline] fallback transcode failed', { error: transcodeError, trace });
        }
        
        await setStatus(adminClient, recordingId, "error", trace, 99, 0.0);
        throw new Error(`Unsupported format: ${text}`);
      }
      
      throw new Error(`Deepgram failed: ${resp.status} ${text}`);
    }
    
    const dg = await resp.json();
    // Typical path: results.channels[0].alternatives[0].transcript
    const transcript =
      dg?.results?.channels?.[0]?.alternatives?.[0]?.transcript ??
      dg?.results?.channels?.[0]?.alternatives?.[0]?.paragraphs?.transcript ??
      "";
    
    const confidence = dg?.results?.channels?.[0]?.alternatives?.[0]?.confidence;
    
    if (!transcript || transcript.length < 2) {
      throw new Error("Deepgram returned empty transcript");
    }
    
    return { transcript: transcript as string, confidence };
  } catch (e) {
    console.error('[sv_run_pipeline] step:deepgramTranscribeWithFallback fail', { error: (e as Error)?.message, trace });
    try {
      await setStatus(adminClient, recordingId, "error", trace, 99, 0.0);
    } catch (statusError) {
      console.error('[sv_run_pipeline] setStatus error after Deepgram failure', { error: (statusError as Error)?.message, trace });
    }
    throw e;
  }
}

async function deepgramTranscribe(fileUrl: string, trace: string): Promise<string> {
  try {
    // Deepgram remote URL transcription
    const resp = await fetch("https://api.deepgram.com/v1/listen?model=nova-2&smart_format=true", {
      method: "POST",
      headers: {
        "Authorization": `Token ${DEEPGRAM_API_KEY}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({ url: fileUrl }),
    });
    if (!resp.ok) {
      const text = await resp.text();
      throw new Error(`Deepgram failed: ${resp.status} ${text}`);
    }
    const dg = await resp.json();
    // Typical path: results.channels[0].alternatives[0].transcript
    const transcript =
      dg?.results?.channels?.[0]?.alternatives?.[0]?.transcript ??
      dg?.results?.channels?.[0]?.alternatives?.[0]?.paragraphs?.transcript ??
      "";
    if (!transcript || transcript.length < 2) {
      throw new Error("Deepgram returned empty transcript");
    }
    return transcript as string;
  } catch (e) {
    console.error('[sv_run_pipeline] step:deepgramTranscribe fail', { error: (e as Error)?.message, trace });
    throw e;
  }
}

function styleInstruction(key: string): string {
  switch (key) {
    case 'organized_by_topic':
      return 'Organize bullets by topic sections (Agenda & Context, Main Discussion, Decisions, Risks/Concerns). Keep the same JSON keys.';
    case 'decisions_next_steps':
      return 'Emphasize a one-sentence TL;DR, list Decisions made, Next steps (action_items), and Open questions within bullets. Keep the same JSON keys.';
    case 'quick_recap_action_items':
    case 'quick_recap': // Legacy key support
    default:
      return 'Keep it concise: short summary, 4–8 key bullets, and clear action_items.';
  }
}

async function openaiSummarize(transcript: string, summaryStyleKey: string, trace: string) {
  try {
    const system = `You are an expert meeting/voice-note summarizer.
Return ONLY JSON with keys: title (string), summary (string),
bullets (array of concise points), action_items (array of tasks),
tags (array of short topic tags), confidence (0..1).`;

    const user = `Transcript:\n"""${transcript}"""\n
Summarize for a busy founder. Avoid fluff.
STYLE: ${styleInstruction(summaryStyleKey)}\n`;

    const resp = await fetch("https://api.openai.com/v1/chat/completions", {
      method: "POST",
      headers: {
        "Authorization": `Bearer ${OPENAI_API_KEY}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        model: "gpt-4o-mini", // fast, cheap, good-enough
        temperature: 0.2,
        messages: [
          { role: "system", content: system },
          { role: "user", content: user },
        ],
        response_format: { type: "json_object" },
      }),
    });

    if (!resp.ok) {
      const text = await resp.text();
      throw new Error(`OpenAI failed: ${resp.status} ${text}`);
    }
    const data = await resp.json();
    const content = data?.choices?.[0]?.message?.content;
    if (!content) throw new Error("OpenAI returned no content");
    const parsed = JSON.parse(content);

    // Normalize shapes
    return {
      title: (parsed.title ?? "Summary").toString(),
      summary: (parsed.summary ?? "").toString(),
      bullets: Array.isArray(parsed.bullets) ? parsed.bullets : [],
      action_items: Array.isArray(parsed.action_items) ? parsed.action_items : [],
      tags: Array.isArray(parsed.tags) ? parsed.tags : [],
      confidence: Number(parsed.confidence ?? 0.8),
    };
  } catch (e) {
    console.error('[sv_run_pipeline] step:openaiSummarize fail', { error: (e as Error)?.message, trace });
    throw e;
  }
}

async function upsertSummary(client: any, recordingId: string, s: {
  title: string;
  summary: string;
  bullets: unknown[];
  action_items: unknown[];
  tags: unknown[];
  confidence: number;
}, summaryStyleKey: string, trace: string) {
  try {
    console.log('[sv_run_pipeline] upsertSummary storing summary_style_key', summaryStyleKey);
    console.log('[PIPELINE] stored summary with style_key=', summaryStyleKey, 'for recording', recordingId);
    const { error } = await client.from("summaries").insert({
      recording_id: recordingId,
      title: s.title,
      summary: s.summary,
      bullets: s.bullets,
      action_items: s.action_items,
      tags: s.tags,
      confidence: s.confidence,
      summary_style: summaryStyleKey,
      summary_style_key: summaryStyleKey, // Store in both fields for compatibility
    });
    if (error) throw new Error(`DB insert summary failed: ${error.message}`);
  } catch (e) {
    console.error('[sv_run_pipeline] step:upsertSummary fail', { error: (e as Error)?.message, trace });
    throw e;
  }
}

async function triggerFallbackTranscode(client: any, recordingId: string, storagePath: string, trace: string) {
  try {
    // Extract file extension from storage path
    const parts = storagePath.split('.');
    const originalFormat = parts.length > 1 ? parts[parts.length - 1] : 'unknown';
    
    // Call the transcode fallback function
    const response = await fetch(`${SUPABASE_URL}/functions/v1/sv_transcode_fallback`, {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${SERVICE_KEY}`,
        'Content-Type': 'application/json',
        'x-trace-id': trace,
      },
      body: JSON.stringify({
        recording_id: recordingId,
        storage_path: storagePath,
        original_format: originalFormat,
        trace_id: trace,
      }),
    });

    if (!response.ok) {
      const text = await response.text();
      throw new Error(`Transcode fallback failed: ${response.status} ${text}`);
    }

    console.log('[sv_run_pipeline] fallback transcode triggered', { recording_id: recordingId, trace });
  } catch (e) {
    console.error('[sv_run_pipeline] triggerFallbackTranscode fail', { error: (e as Error)?.message, trace });
    throw e;
  }
}