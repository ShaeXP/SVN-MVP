// supabase/functions/sv_transcription_webhook/index.ts
// Webhook handler for Deepgram transcription results with idempotency

import 'jsr:@supabase/functions-js/edge-runtime.d.ts';
import { createClient } from 'jsr:@supabase/supabase-js@2';

const OPENAI_API_KEY = Deno.env.get("OPENAI_API_KEY")!;
const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SERVICE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

const cors = { 
  'access-control-allow-origin': '*', 
  'access-control-allow-headers': 'authorization, x-client-info, apikey, content-type, x-trace-id' 
};

type DeepgramWebhook = {
  job_id: string;
  status: 'processing' | 'completed' | 'failed';
  results?: {
    channels: Array<{
      alternatives: Array<{
        transcript: string;
        confidence: number;
        words?: Array<{
          word: string;
          start: number;
          end: number;
          confidence: number;
        }>;
      }>;
    }>;
  };
  error?: string;
};

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: cors });

  const exec = Deno.env.get('SB_EXECUTION_ID') ?? null;
  const trace = req.headers.get('x-trace-id') ?? `${Date.now().toString(36)}-${Math.random().toString(36).slice(2,7)}`;
  console.log('[sv_transcription_webhook] boot', { exec, trace });

  try {
    const body = await req.json().catch(() => ({} as any)) as DeepgramWebhook;
    
    console.log('[sv_transcription_webhook] webhook received', {
      job_id: body.job_id,
      status: body.status,
      has_results: !!body.results,
      trace
    });

    if (!body.job_id) {
      return new Response(JSON.stringify({
        ok: false,
        code: 'missing_job_id',
        message: 'Missing job_id in webhook payload',
        trace
      }), {
        status: 400,
        headers: { ...cors, 'content-type': 'application/json' }
      });
    }

    const adminClient = createClient(SUPABASE_URL, SERVICE_KEY, {
      auth: { persistSession: false },
    });

    // Check for idempotency using job_id
    const existingResult = await adminClient
      .from('transcript_jobs')
      .select('recording_id, status')
      .eq('job_id', body.job_id)
      .maybeSingle();

    if (existingResult.data && existingResult.data.status === 'completed') {
      console.log('[sv_transcription_webhook] already processed', { job_id: body.job_id, trace });
      return new Response(JSON.stringify({ ok: true, message: 'Already processed', trace }), {
        headers: { ...cors, 'content-type': 'application/json' }
      });
    }

    if (body.status === 'failed') {
      console.log('[sv_transcription_webhook] job failed', { job_id: body.job_id, error: body.error, trace });
      
      // Update recording status to error
      if (existingResult.data?.recording_id) {
        await setStatus(adminClient, existingResult.data.recording_id, 'error', trace);
      }
      
      return new Response(JSON.stringify({ ok: true, message: 'Job failed, status updated', trace }), {
        headers: { ...cors, 'content-type': 'application/json' }
      });
    }

    if (body.status === 'completed' && body.results) {
      const transcript = body.results.channels?.[0]?.alternatives?.[0]?.transcript ?? '';
      const confidence = body.results.channels?.[0]?.alternatives?.[0]?.confidence ?? 0;

      if (!transcript || transcript.length < 2) {
        console.log('[sv_transcription_webhook] empty transcript', { job_id: body.job_id, trace });
        
        if (existingResult.data?.recording_id) {
          await setStatus(adminClient, existingResult.data.recording_id, 'error', trace);
        }
        
        return new Response(JSON.stringify({ ok: true, message: 'Empty transcript, status updated', trace }), {
          headers: { ...cors, 'content-type': 'application/json' }
        });
      }

      // Save transcript to database
      if (existingResult.data?.recording_id) {
        const recordingId = existingResult.data.recording_id;
        
        console.log('[sv_transcription_webhook] saving transcript', { recording_id: recordingId, trace });
        await adminClient.from("transcripts").insert({ 
          recording_id: recordingId, 
          text: transcript,
          confidence: confidence
        });

        // Summarize with OpenAI
        console.log('[sv_transcription_webhook] summarizing', { recording_id: recordingId, trace });
        const summary = await openaiSummarize(transcript, trace);
        
        // Save summary
        console.log('[sv_transcription_webhook] saving summary', { recording_id: recordingId, trace });
        await upsertSummary(adminClient, recordingId, summary, trace);
        
        // Mark as ready
        console.log('[sv_transcription_webhook] marking ready', { recording_id: recordingId, trace });
        await setStatus(adminClient, recordingId, 'ready', trace);
        
        // Update job status
        await adminClient
          .from('transcript_jobs')
          .update({ status: 'completed' })
          .eq('job_id', body.job_id);
      }
    }

    return new Response(JSON.stringify({ ok: true, trace }), {
      headers: { ...cors, 'content-type': 'application/json' }
    });

  } catch (e) {
    console.error('[sv_transcription_webhook] error', { msg: (e as Error).message, trace });
    return new Response(JSON.stringify({ 
      ok: false, 
      code: 'unhandled', 
      message: String(e), 
      trace 
    }), { 
      status: 500, 
      headers: { ...cors, 'content-type': 'application/json' } 
    });
  }
});

// ---------- Helpers ----------

async function setStatus(client: any, recordingId: string, status: "transcribing" | "ready" | "error", trace: string) {
  try {
    const { error } = await client
      .from("recordings")
      .update({ status })
      .eq("id", recordingId);
    if (error) throw new Error(`DB status update failed: ${error.message}`);
  } catch (e) {
    console.error('[sv_transcription_webhook] step:setStatus fail', { error: (e as Error)?.message, trace });
    throw e;
  }
}

async function openaiSummarize(transcript: string, trace: string) {
  try {
    const system = `You are an expert meeting/voice-note summarizer.
Return ONLY JSON with keys: title (string), summary (string),
bullets (array of concise points), action_items (array of tasks),
tags (array of short topic tags), confidence (0..1).`;

    const user = `Transcript:\n"""${transcript}"""\n
Summarize for a busy founder. Avoid fluff.`;

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
    console.error('[sv_transcription_webhook] step:openaiSummarize fail', { error: (e as Error)?.message, trace });
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
}, trace: string) {
  try {
    const { error } = await client.from("summaries").insert({
      recording_id: recordingId,
      title: s.title,
      summary: s.summary,
      bullets: s.bullets,
      action_items: s.action_items,
      tags: s.tags,
      confidence: s.confidence,
    });
    if (error) throw new Error(`DB insert summary failed: ${error.message}`);
  } catch (e) {
    console.error('[sv_transcription_webhook] step:upsertSummary fail', { error: (e as Error)?.message, trace });
    throw e;
  }
}
