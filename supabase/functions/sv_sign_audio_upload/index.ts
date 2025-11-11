// supabase/functions/sv_sign_audio_upload/index.ts
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const SB_URL = Deno.env.get("SUPABASE_URL")!;
const SB_ANON = Deno.env.get("SUPABASE_ANON_KEY")!;

function log(event: Record<string, unknown>) {
  console.log(JSON.stringify({ svc: "sv_sign_audio_upload", ts: new Date().toISOString(), ...event }));
}

// Canonical MIME type mapping
function getContentType(filename: string): string {
  const ext = filename.toLowerCase().split('.').pop() || '';
  switch (ext) {
    case 'm4a':
    case 'mp4':
      return 'audio/mp4';
    case 'mp3':
      return 'audio/mpeg';
    case 'wav':
      return 'audio/wav';
    case 'aac':
      return 'audio/aac';
    default:
      return 'application/octet-stream';
  }
}

// Allowed MIME types for validation
const ALLOWED_MIME_TYPES = [
  'audio/mp4',
  'audio/mpeg', 
  'audio/wav',
  'audio/aac',
  'application/octet-stream'
];

Deno.serve(async (req) => {
  const reqId = crypto.randomUUID();
  
  try {
    if (!SB_URL || !SB_ANON) {
      log({ reqId, level: "error", msg: "missing env", hasUrl: !!SB_URL, hasAnon: !!SB_ANON });
      return new Response(JSON.stringify({ error: "Missing required env" }), { 
        status: 500, 
        headers: { "Content-Type": "application/json" } 
      });
    }

    // Auth
    const auth = req.headers.get("Authorization") ?? "";
    if (!auth.startsWith("Bearer ")) {
      log({ reqId, level: "warn", stage: "auth", msg: "no bearer" });
      return new Response(JSON.stringify({ error: "Auth required" }), { 
        status: 401, 
        headers: { "Content-Type": "application/json" } 
      });
    }
    
    const supabase = createClient(SB_URL, SB_ANON, { 
      global: { headers: { Authorization: auth } } 
    });
    
    const { data: { user }, error: userErr } = await supabase.auth.getUser();
    if (userErr || !user) {
      log({ reqId, level: "warn", stage: "auth", msg: "invalid token", userErr });
      return new Response(JSON.stringify({ error: "Invalid token" }), { 
        status: 401, 
        headers: { "Content-Type": "application/json" } 
      });
    }

    // Parse request body
    const { filename, contentType, size } = await req.json().catch(() => ({}));
    
    if (!filename || typeof filename !== 'string') {
      log({ reqId, level: "warn", stage: "input", msg: "missing filename" });
      return new Response(JSON.stringify({ error: "Missing 'filename'" }), { 
        status: 400, 
        headers: { "Content-Type": "application/json" } 
      });
    }

    // Derive canonical content type
    const canonicalContentType = getContentType(filename);
    
    // Validate content type (allow both provided and canonical)
    const finalContentType = contentType && ALLOWED_MIME_TYPES.includes(contentType) 
      ? contentType 
      : canonicalContentType;
    
    // Add diagnostics logging
    console.log(`[SIGN] method=PUT ct=${finalContentType} path=${storagePath} rec=${recordingId} bucket=recordings`);
    
    if (!ALLOWED_MIME_TYPES.includes(finalContentType)) {
      log({ reqId, level: "warn", stage: "validation", msg: "unsupported mime", contentType: finalContentType });
      return new Response(JSON.stringify({ error: `MIME type ${finalContentType} is not supported` }), { 
        status: 400, 
        headers: { "Content-Type": "application/json" } 
      });
    }

    // Size validation (50MB limit)
    const maxSize = 50 * 1024 * 1024; // 50MB
    if (size && size > maxSize) {
      log({ reqId, level: "warn", stage: "validation", msg: "file too large", size });
      return new Response(JSON.stringify({ error: "File too large (max 50MB)" }), { 
        status: 413, 
        headers: { "Content-Type": "application/json" } 
      });
    }

    // Generate storage path
    const userId = user.id;
    const now = new Date();
    const yyyy = now.getUTCFullYear().toString();
    const mm = (now.getUTCMonth() + 1).toString().padStart(2, '0');
    const dd = now.getUTCDate().toString().padStart(2, '0');
    const uuid = crypto.randomUUID();
    const ext = filename.split('.').pop()?.toLowerCase() || 'mp3';
    const storagePath = `recordings/${userId}/${yyyy}/${mm}/${dd}/${uuid}.${ext}`;

    // Create recording record
    const { data: recording, error: recError } = await supabase
      .from('recordings')
      .insert({
        user_id: userId,
        storage_path: storagePath,
        status: 'uploading',
        mime_type: finalContentType,
        original_filename: filename,
        duration_sec: 0
      })
      .select('id')
      .single();

    if (recError) {
      log({ reqId, level: "error", stage: "recording_insert", error: recError });
      return new Response(JSON.stringify({ error: "Failed to create recording record" }), { 
        status: 500, 
        headers: { "Content-Type": "application/json" } 
      });
    }

    // Create signed upload URL
    const { data: signedUrl, error: urlError } = await supabase.storage
      .from('recordings')
      .createSignedUploadUrl(storagePath.replace('recordings/', ''), 3600); // 1 hour expiry

    if (urlError || !signedUrl?.signedUrl) {
      log({ reqId, level: "error", stage: "signed_url", error: urlError });
      return new Response(JSON.stringify({ error: "Failed to create signed upload URL" }), { 
        status: 500, 
        headers: { "Content-Type": "application/json" } 
      });
    }

    log({ reqId, level: "info", stage: "success", userId, recordingId: recording.id, storagePath, contentType: finalContentType });

    // Guarantee stable contract - all required fields are strings, never null
    const response = {
      success: true,
      recordingId: recording.id as string,
      storagePath: storagePath as string,
      url: signedUrl.signedUrl as string,
      method: 'PUT' as string,
      contentType: finalContentType as string,
      headers: {
        'Content-Type': finalContentType as string
      }
    };

    log({ reqId, level: "info", stage: "response", method: response.method, ct: response.contentType, path: response.storagePath, rec: response.recordingId });

    return new Response(JSON.stringify(response), { 
      status: 200, 
      headers: { "Content-Type": "application/json" } 
    });

  } catch (e) {
    log({ reqId, level: "error", msg: "unhandled", err: String(e) });
    return new Response(JSON.stringify({ error: String(e) }), { 
      status: 500, 
      headers: { "Content-Type": "application/json" } 
    });
  }
});
