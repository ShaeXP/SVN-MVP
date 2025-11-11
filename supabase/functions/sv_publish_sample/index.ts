import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const cors = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type, idempotency-key',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
};

interface PublishRequest {
  recording_id: string;
  redacted_text: string;
  user_id: string;
  vertical?: 'health' | 'legal' | 'ops';
  entities_count_by_type?: Record<string, number>;
  used_presidio?: boolean;
  pdfBytes?: string; // Base64 encoded PDF bytes from client
}

interface PublishResponse {
  publicUrl: string;
  path: string;
  manifestUrl: string;
  idempotencyHit?: boolean;
}

// In-memory cache for idempotency (in production, use Redis or database)
const idempotencyCache = new Map<string, { publicUrl: string; path: string; manifestUrl: string; createdAt: string }>();

serve(async (req) => {
  // Handle health check
  if (req.method === 'GET') {
    const serverSidePdf = Deno.env.get('SVN_SERVER_SIDE_PDF') === 'true';
    return new Response(JSON.stringify({
      ok: true,
      usedPresidio: false,
      serverSidePdf
    }), {
      status: 200,
      headers: { ...cors, 'content-type': 'application/json' }
    });
  }

  // Handle debug echo-error endpoint
  if (req.method === 'POST' && req.url.includes('/echo-error')) {
    if (Deno.env.get('DEBUG_EXPORT_ERRORS') === 'true') {
      return new Response(JSON.stringify({
        failure_code: 'SERVICE_ROLE_MISSING',
        request_id: crypto.randomUUID()
      }), {
        status: 400,
        headers: { 
          ...cors, 
          'content-type': 'application/json',
          'Access-Control-Allow-Origin': '*',
          'Access-Control-Allow-Headers': '*'
        }
      });
    }
  }

  // Handle CORS preflight
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: cors });
  }

  const startTime = Date.now();
  let idempotencyHit = false;

  try {
    // Create Supabase client with user JWT
    const supabase = createClient(
      Deno.env.get('SUPABASE_URL')!, 
      Deno.env.get('SUPABASE_ANON_KEY')!,
      { global: { headers: { Authorization: req.headers.get('Authorization') ?? '' } } }
    );

    // Verify user authentication
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) {
      return new Response(JSON.stringify({
        failure_code: 'AUTHENTICATION_FAILED',
        detail: 'User authentication required',
        request_id: crypto.randomUUID()
      }), {
        status: 401,
        headers: { 
          ...cors, 
          'content-type': 'application/json',
          'Access-Control-Allow-Origin': '*',
          'Access-Control-Allow-Headers': '*'
        }
      });
    }

    // Get Idempotency-Key from headers
    const idempotencyKey = req.headers.get('idempotency-key');
    if (!idempotencyKey) {
      return new Response(JSON.stringify({
        error: 'MISSING_IDEMPOTENCY_KEY',
        message: 'Idempotency-Key header is required'
      }), {
        status: 400,
        headers: { ...cors, 'content-type': 'application/json' }
      });
    }

    // Check idempotency cache
    if (idempotencyCache.has(idempotencyKey)) {
      const cached = idempotencyCache.get(idempotencyKey)!;
      console.log('[sv_publish_sample] idempotency_hit', { 
        idempotencyKey,
        cachedPath: cached.path 
      });
      
      return new Response(JSON.stringify({
        publicUrl: cached.publicUrl,
        path: cached.path,
        manifestUrl: cached.manifestUrl,
        idempotencyHit: true
      }), {
        status: 200,
        headers: { ...cors, 'content-type': 'application/json' }
      });
    }

    // Parse request body
    const body: PublishRequest = await req.json();
    const { 
      recording_id, 
      redacted_text, 
      user_id, 
      vertical = 'health',
      entities_count_by_type = {},
      used_presidio = false,
      pdfBytes
    } = body;

    // Validate required fields
    if (!recording_id || !redacted_text || !user_id) {
      return new Response(JSON.stringify({
        error: 'MISSING_REQUIRED_FIELDS',
        message: 'recording_id, redacted_text, and user_id are required'
      }), {
        status: 400,
        headers: { ...cors, 'content-type': 'application/json' }
      });
    }

    // Create Supabase client with service role - CRITICAL: Must use service role only
    const supabaseUrl = Deno.env.get('SUPABASE_URL');
    const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY');
    
    if (!supabaseUrl || !supabaseServiceKey) {
      const requestId = crypto.randomUUID();
      console.log('[sv_publish_sample] service_role_missing', {
        hasUrl: !!supabaseUrl,
        hasServiceKey: !!supabaseServiceKey,
        request_id: requestId
      });
      return new Response(JSON.stringify({
        failure_code: 'SERVICE_ROLE_MISSING',
        detail: 'Server misconfigured - missing service role credentials',
        request_id: requestId
      }), {
        status: 500,
        headers: { 
          ...cors, 
          'content-type': 'application/json',
          'Access-Control-Allow-Origin': '*',
          'Access-Control-Allow-Headers': '*'
        }
      });
    }

    const supabase = createClient(supabaseUrl, supabaseServiceKey);

    // Generate file paths - CRITICAL: Must match path-scoped RLS policy
    const now = new Date();
    const yyyy = now.getFullYear().toString();
    const mm = (now.getMonth() + 1).toString().padStart(2, '0');
    const dd = now.getDate().toString().padStart(2, '0');
    const uuid = crypto.randomUUID();
    const shortId = uuid.substring(0, 8);
    const dateStr = `${yyyy}${mm}${dd}`;
    
    // Path MUST be: samples/{userId}/{yyyy}/{MM}/{dd}/{uuid}.pdf
    const pdfPath = `samples/${user_id}/${yyyy}/${mm}/${dd}/${uuid}.pdf`;
    const manifestPath = `samples/${user_id}/${yyyy}/${mm}/${dd}/${uuid}.json`;
    
    // Verify path matches RLS policy
    if (!pdfPath.startsWith('samples/')) {
      const requestId = crypto.randomUUID();
      console.log('[sv_publish_sample] path_rls_denied', {
        path: pdfPath,
        request_id: requestId
      });
      return new Response(JSON.stringify({
        failure_code: 'PATH_RLS_DENIED',
        detail: 'Invalid storage path',
        request_id: requestId
      }), {
        status: 400,
        headers: { 
          ...cors, 
          'content-type': 'application/json',
          'Access-Control-Allow-Origin': '*',
          'Access-Control-Allow-Headers': '*'
        }
      });
    }

    // Generate or use provided PDF content
    let pdfContent: Uint8Array;
    const serverSidePdf = Deno.env.get('SVN_SERVER_SIDE_PDF') === 'true';
    
    if (pdfBytes && !serverSidePdf) {
      // Use client-provided PDF bytes
      try {
        pdfContent = new Uint8Array(Buffer.from(pdfBytes, 'base64'));
      } catch (error) {
        console.log('[sv_publish_sample] pdf_decode_error', {
          error: error.message,
          failure_code: 'PDF_RENDER_ERROR'
        });
        return new Response(JSON.stringify({
          failure_code: 'PDF_RENDER_ERROR',
          detail: 'Failed to decode PDF bytes',
          request_id: crypto.randomUUID()
        }), {
          status: 500,
          headers: { 
            ...cors, 
            'content-type': 'application/json',
            'Access-Control-Allow-Origin': '*',
            'Access-Control-Allow-Headers': '*'
          }
        });
      }
    } else {
      // Generate server-side PDF
      let textToRender = redacted_text;
      
      // If synthetic mode, use template text
      if (body.synthetic) {
        const { getSyntheticTemplate } = await import('../_shared/pii_regex.ts');
        textToRender = getSyntheticTemplate(vertical as 'health' | 'legal' | 'ops');
      }
      
      pdfContent = generatePDF(textToRender, vertical);
    }
    
    // Validate PDF content
    if (!pdfContent || pdfContent.length === 0) {
      console.log('[sv_publish_sample] pdf_render_error', {
        hasContent: !!redacted_text,
        hasPdfBytes: !!pdfBytes,
        serverSidePdf,
        failure_code: 'PDF_RENDER_ERROR'
      });
      return new Response(JSON.stringify({
        failure_code: 'PDF_RENDER_ERROR',
        detail: 'Failed to generate PDF',
        request_id: crypto.randomUUID()
      }), {
        status: 500,
        headers: { 
          ...cors, 
          'content-type': 'application/json',
          'Access-Control-Allow-Origin': '*',
          'Access-Control-Allow-Headers': '*'
        }
      });
    }

    // Generate manifest with timings
    const sha256 = await calculateSHA256(pdfContent);
    const manifest = {
      version: "1.0",
      createdAt: now.toISOString(),
      entitiesCountByType: entities_count_by_type,
      usedPresidio: used_presidio,
      sha256: sha256,
      idempotencyKey: idempotencyKey,
      vertical: vertical,
      recordingId: recording_id,
      userId: user_id,
      redact_ms: 0, // Will be provided by client in future
      publish_ms: 0  // Will be calculated below
    };

    // Upload PDF to storage with proper headers
    const safeFilename = `SVN-sample-${vertical}-${dateStr}-${shortId}.pdf`;
    const pdfUploadResult = await supabase.storage
      .from('public_redacted_samples')
      .upload(pdfPath, pdfContent, {
        contentType: 'application/pdf',
        cacheControl: 'public, max-age=31536000, immutable',
        contentDisposition: `inline; filename="${safeFilename}"`,
        upsert: false
      });

    if (pdfUploadResult.error) {
      const failure_code = pdfUploadResult.error.message?.includes('forbidden') || pdfUploadResult.error.message?.includes('permission')
        ? 'STORAGE_WRITE_FORBIDDEN'
        : 'UNKNOWN';
      console.log('[sv_publish_sample] pdf_upload_failed', {
        error: pdfUploadResult.error.message,
        path: pdfPath,
        failure_code
      });
      return new Response(JSON.stringify({
        failure_code,
        detail: 'Failed to upload PDF to storage',
        request_id: crypto.randomUUID()
      }), {
        status: 500,
        headers: { 
          ...cors, 
          'content-type': 'application/json',
          'Access-Control-Allow-Origin': '*',
          'Access-Control-Allow-Headers': '*'
        }
      });
    }

    // Upload manifest
    const manifestUploadResult = await supabase.storage
      .from('public_redacted_samples')
      .upload(manifestPath, JSON.stringify(manifest, null, 2), {
        contentType: 'application/json',
        cacheControl: 'public, max-age=31536000, immutable',
        upsert: false
      });

    if (manifestUploadResult.error) {
      // Clean up PDF if manifest upload fails
      await supabase.storage.from('public_redacted_samples').remove([pdfPath]);
      const failure_code = 'STORAGE_WRITE_FORBIDDEN';
      console.log('[sv_publish_sample] manifest_upload_failed', {
        error: manifestUploadResult.error.message,
        path: manifestPath,
        failure_code
      });
      return new Response(JSON.stringify({
        failure_code,
        detail: 'Failed to upload manifest',
        request_id: crypto.randomUUID()
      }), {
        status: 500,
        headers: { 
          ...cors, 
          'content-type': 'application/json',
          'Access-Control-Allow-Origin': '*',
          'Access-Control-Allow-Headers': '*'
        }
      });
    }

    // Get public URLs
    const publicUrl = supabase.storage
      .from('public_redacted_samples')
      .getPublicUrl(pdfPath);

    const manifestUrl = supabase.storage
      .from('public_redacted_samples')
      .getPublicUrl(manifestPath);

    // Cache the result for idempotency
    const result = {
      publicUrl: publicUrl.data.publicUrl,
      path: pdfPath,
      manifestUrl: manifestUrl.data.publicUrl,
      createdAt: now.toISOString()
    };
    
    idempotencyCache.set(idempotencyKey, result);

    const publishMs = Date.now() - startTime;
    manifest.publish_ms = publishMs;
    
    console.log('[sv_publish_sample] success', { 
      publish_ms: publishMs,
      pdf_size_bytes: pdfContent.length,
      used_presidio: usedPresidio,
      entities_total: Object.values(entities_count_by_type).reduce((a, b) => a + b, 0),
      idempotency_hit: false,
      idempotencyKey,
      path: pdfPath,
      vertical,
      sha256
    });

    return new Response(JSON.stringify({
      publicUrl: result.publicUrl,
      path: result.path,
      manifestUrl: result.manifestUrl,
      sha256: sha256,
      idempotencyHit: false
    }), {
      status: 200,
      headers: { ...cors, 'content-type': 'application/json' }
    });

  } catch (error) {
    const publishMs = Date.now() - startTime;
    const requestId = crypto.randomUUID();
    
    // Extract failure code from error message if present
    let failure_code = 'UNKNOWN';
    const errorMsg = error.message || '';
    if (errorMsg.includes('SERVICE_ROLE_MISSING')) failure_code = 'SERVICE_ROLE_MISSING';
    else if (errorMsg.includes('STORAGE_WRITE_FORBIDDEN')) failure_code = 'STORAGE_WRITE_FORBIDDEN';
    else if (errorMsg.includes('PDF_RENDER_ERROR')) failure_code = 'PDF_RENDER_ERROR';
    else if (errorMsg.includes('PATH_RLS_DENIED')) failure_code = 'PATH_RLS_DENIED';
    
    console.log('[sv_publish_sample] error', { 
      publish_ms: publishMs,
      idempotency_hit: idempotencyHit,
      failure_code,
      request_id: requestId
    });

    return new Response(JSON.stringify({
      failure_code,
      detail: 'Failed to publish sample',
      request_id: requestId
    }), {
      status: 500,
      headers: { 
        ...cors, 
        'content-type': 'application/json',
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Headers': '*'
      }
    });
  }
});

/**
 * Generate a simple PDF with the redacted text
 * This is a basic implementation - in production, use a proper PDF library
 */
function generatePDF(text: string, vertical: string): Uint8Array {
  // Simple PDF generation (minimal implementation)
  // In production, this would use a proper PDF library
  const header = `De-identified sample — PII removed or generalized\nVertical: ${vertical}\n\n`;
  const content = header + text;
  
  // Convert to bytes (this is a simplified approach)
  // In the Flutter client, we'll use the proper pdf package
  return new TextEncoder().encode(content);
}

/**
 * Calculate SHA256 hash of content
 */
async function calculateSHA256(content: Uint8Array): Promise<string> {
  const hashBuffer = await crypto.subtle.digest('SHA-256', content);
  const hashArray = Array.from(new Uint8Array(hashBuffer));
  return hashArray.map(b => b.toString(16).padStart(2, '0')).join('');
}
