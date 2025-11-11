// supabase/functions/sv_transcode_fallback/index.ts
// Fallback transcoding for unsupported formats - triggers external transcode service

import 'jsr:@supabase/functions-js/edge-runtime.d.ts';
import { createClient } from 'jsr:@supabase/supabase-js@2';

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SERVICE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

const cors = { 
  'access-control-allow-origin': '*', 
  'access-control-allow-headers': 'authorization, x-client-info, apikey, content-type, x-trace-id' 
};

type TranscodeBody = {
  recording_id: string;
  storage_path: string;
  original_format: string;
  trace_id?: string;
};

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: cors });

  const exec = Deno.env.get('SB_EXECUTION_ID') ?? null;
  const trace = req.headers.get('x-trace-id') ?? `${Date.now().toString(36)}-${Math.random().toString(36).slice(2,7)}`;
  console.log('[sv_transcode_fallback] boot', { exec, trace });

  try {
    const body = await req.json().catch(() => ({} as any)) as TranscodeBody;
    
    console.log('[sv_transcode_fallback] transcode request', {
      recording_id: body.recording_id,
      storage_path: body.storage_path,
      original_format: body.original_format,
      trace
    });

    if (!body.recording_id || !body.storage_path) {
      return new Response(JSON.stringify({
        ok: false,
        code: 'missing_params',
        message: 'Missing recording_id or storage_path',
        trace
      }), {
        status: 400,
        headers: { ...cors, 'content-type': 'application/json' }
      });
    }

    const adminClient = createClient(SUPABASE_URL, SERVICE_KEY, {
      auth: { persistSession: false },
    });

    // For now, just log the transcode request and mark as error
    // In production, this would trigger a Cloud Run job or external transcode service
    console.log('[sv_transcode_fallback] transcode needed', {
      recording_id: body.recording_id,
      storage_path: body.storage_path,
      original_format: body.original_format,
      trace
    });

    // Update recording status to indicate transcode needed
    await adminClient
      .from('recordings')
      .update({ 
        status: 'error',
        last_error: `Unsupported format: ${body.original_format}. Transcode required.`
      })
      .eq('id', body.recording_id);

    // In a real implementation, you would:
    // 1. Queue a transcode job (Cloud Run, AWS Batch, etc.)
    // 2. Store the job ID in the database
    // 3. Have the transcoded file trigger the pipeline to resume
    // 4. Use a webhook or polling to check transcode completion

    return new Response(JSON.stringify({ 
      ok: true, 
      message: 'Transcode request logged - implementation needed',
      trace 
    }), {
      headers: { ...cors, 'content-type': 'application/json' }
    });

  } catch (e) {
    console.error('[sv_transcode_fallback] error', { msg: (e as Error).message, trace });
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
