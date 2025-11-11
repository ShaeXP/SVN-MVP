import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';
import { regexRedact, getSyntheticTemplate } from '../_shared/pii_regex.ts';

const cors = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type, idempotency-key',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
};

interface RedactRequest {
  text: string;
  format?: 'pdf' | 'txt';
  context?: {
    vertical?: 'health' | 'legal' | 'ops';
  };
  featureFlag?: boolean;
  synthetic?: boolean;
}

interface RedactResponse {
  redactedText: string;
  entities: Array<{type: string, start: number, end: number}>;
  entitiesCountByType: Record<string, number>;
  usedPresidio: boolean;
  synthetic?: boolean;
}

serve(async (req) => {
  // Handle health check
  if (req.method === 'GET') {
    const presidioConfigured = !!(Deno.env.get('PRESIDIO_ANALYZER_URL') && Deno.env.get('PRESIDIO_ANONYMIZER_URL'));
    return new Response(JSON.stringify({
      ok: true,
      usedPresidio: presidioConfigured,
      serverSidePdf: false
    }), {
      status: 200,
      headers: { ...cors, 'content-type': 'application/json' }
    });
  }

  // Handle CORS preflight
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: cors });
  }

  const startTime = Date.now();
  let inputLength = 0;
  let synthetic = false;
  let usedPresidio = false;

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

    // Parse request body
    const body: RedactRequest = await req.json();
    const { text, format = 'pdf', context, featureFlag = false, synthetic: useSynthetic = false } = body;

    // Input validation
    if (!text || typeof text !== 'string') {
      return new Response(JSON.stringify({
        failure_code: 'UNKNOWN',
        detail: 'Text is required and must be a string',
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

    inputLength = text.length;
    synthetic = useSynthetic;

    // Input size limit (50k chars max)
    const MAX_INPUT_LENGTH = 50000;
    if (inputLength > MAX_INPUT_LENGTH) {
      console.log('[sv_redact] input_too_large', { 
        inputLength, 
        maxLength: MAX_INPUT_LENGTH,
        failure_code: 'REDACTION_413_INPUT_TOO_LARGE'
      });
      return new Response(JSON.stringify({
        failure_code: 'REDACTION_413_INPUT_TOO_LARGE',
        detail: `Input text too long: ${inputLength} chars (max: ${MAX_INPUT_LENGTH})`,
        request_id: crypto.randomUUID()
      }), {
        status: 413,
        headers: { 
          ...cors, 
          'content-type': 'application/json',
          'Access-Control-Allow-Origin': '*',
          'Access-Control-Allow-Headers': '*'
        }
      });
    }

    // Feature flag check - use environment variable
    const redactionEnabled = Deno.env.get('REDACTION_ENABLED')?.toLowerCase() === 'true';
    if (!redactionEnabled) {
      const traceId = req.headers.get('x-trace-id') || crypto.randomUUID();
      console.log('[sv_redact] redaction_bypass', { 
        event: 'redaction_bypass',
        traceId: traceId,
        reason: 'feature_disabled' 
      });
      return new Response(JSON.stringify({
        redactedText: text,
        entities: [],
        entitiesCountByType: {},
        usedPresidio: false,
        synthetic
      }), {
        status: 200,
        headers: { ...cors, 'content-type': 'application/json' }
      });
    }

    // Synthetic mode - return pre-baked template (zero-risk marketing assets)
    if (synthetic) {
      console.log('[sv_redact] synthetic_mode', { inputLength });
      const templateText = getSyntheticTemplate();
      const result = regexRedact(templateText);
      
      return new Response(JSON.stringify({
        redactedText: result.redacted,
        entities: result.entities,
        entitiesCountByType: result.entitiesCountByType,
        usedPresidio: false,
        synthetic: true
      }), {
        status: 200,
        headers: { ...cors, 'content-type': 'application/json' }
      });
    }

    // Apply regex redaction
    console.log('[sv_redact] applying_regex', { inputLength, vertical: context?.vertical });
    const regexResult = regexRedact(text);

    // Try Presidio if configured
    const presidioAnalyzerUrl = Deno.env.get('PRESIDIO_ANALYZER_URL');
    const presidioAnonymizerUrl = Deno.env.get('PRESIDIO_ANONYMIZER_URL');

    // Skip Presidio if either URL is missing or empty
    if (presidioAnalyzerUrl && presidioAnonymizerUrl && presidioAnalyzerUrl.trim() && presidioAnonymizerUrl.trim()) {
      try {
        console.log('[sv_redact] calling_presidio', { inputLength });
        
        // Call Presidio analyzer with 7s budget and retry
        let analyzerResponse;
        try {
          analyzerResponse = await fetch(presidioAnalyzerUrl, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({
              text: text,
              language: 'en'
            }),
            signal: AbortSignal.timeout(3500) // 3.5s timeout for first attempt
          });
        } catch (error) {
          // Retry once with 500ms timeout
          console.log('[sv_redact] presidio_retry', { error: error.message });
          analyzerResponse = await fetch(presidioAnalyzerUrl, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({
              text: text,
              language: 'en'
            }),
            signal: AbortSignal.timeout(500) // 500ms retry timeout
          });
        }

        if (analyzerResponse.ok) {
          const analyzerResult = await analyzerResponse.json();
          
          // Call Presidio anonymizer
          const anonymizerResponse = await fetch(presidioAnonymizerUrl, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({
              text: text,
              analyzer_results: analyzerResult,
              anonymizers: {
                DEFAULT: { type: 'replace', new_value: '[REDACTED]' },
                PERSON: { type: 'replace', new_value: '[NAME]' },
                EMAIL_ADDRESS: { type: 'replace', new_value: '[EMAIL]' },
                PHONE_NUMBER: { type: 'replace', new_value: '[PHONE]' },
                DATE_TIME: { type: 'replace', new_value: '[DATE]' },
                ORGANIZATION: { type: 'replace', new_value: '[ORG]' }
              }
            }),
            signal: AbortSignal.timeout(1000) // 1s timeout
          });

          if (anonymizerResponse.ok) {
            const anonymizerResult = await anonymizerResponse.json();
            usedPresidio = true;
            
            // Merge Presidio results with regex results
            // Prefer broader spans, dedupe by position
            const mergedEntities = [...regexResult.entities];
            const mergedCounts = { ...regexResult.entitiesCountByType };
            
            // Add Presidio entities that don't overlap with regex entities
            if (anonymizerResult.items) {
              for (const item of anonymizerResult.items) {
                const hasOverlap = mergedEntities.some(entity => 
                  (entity.start <= item.start && entity.end > item.start) ||
                  (entity.start < item.end && entity.end >= item.end)
                );
                
                if (!hasOverlap) {
                  mergedEntities.push({
                    type: item.entity_type,
                    start: item.start,
                    end: item.end
                  });
                  mergedCounts[item.entity_type] = (mergedCounts[item.entity_type] || 0) + 1;
                }
              }
            }

            console.log('[sv_redact] presidio_success', { 
              entitiesTotal: mergedEntities.length,
              usedPresidio: true 
            });

            return new Response(JSON.stringify({
              redactedText: anonymizerResult.text || regexResult.redacted,
              entities: mergedEntities.sort((a, b) => a.start - b.start),
              entitiesCountByType: mergedCounts,
              usedPresidio: true,
              synthetic: false
            }), {
              status: 200,
              headers: { ...cors, 'content-type': 'application/json' }
            });
          }
        }
      } catch (error) {
        // Presidio failed - log warning and proceed with regex-only
        console.log('[sv_redact] presidio_failed', { 
          error: error.message,
          fallbackToRegex: true,
          failure_note: 'PRESIDIO_UPSTREAM_ERROR'
        });
      }
    } else {
      console.log('[sv_redact] presidio_skipped', { 
        hasAnalyzerUrl: !!presidioAnalyzerUrl,
        hasAnonymizerUrl: !!presidioAnonymizerUrl 
      });
    }

    // Return regex-only results
    const redactMs = Date.now() - startTime;
    console.log('[sv_redact] regex_complete', { 
      redactMs,
      entitiesTotal: regexResult.entities.length,
      entitiesByType: regexResult.entitiesCountByType,
      usedPresidio: false,
      inputLength,
      synthetic: false
    });

    return new Response(JSON.stringify({
      redactedText: regexResult.redacted,
      entities: regexResult.entities,
      entitiesCountByType: regexResult.entitiesCountByType,
      usedPresidio: false,
      synthetic: false
    }), {
      status: 200,
      headers: { ...cors, 'content-type': 'application/json' }
    });

  } catch (error) {
    const redactMs = Date.now() - startTime;
    const failure_code = error.message?.includes('timeout') ? 'REDACTION_TIMEOUT' : 'UNKNOWN';
    const requestId = crypto.randomUUID();
    
    console.log('[sv_redact] error', { 
      redact_ms: redactMs,
      input_length: inputLength,
      synthetic,
      failure_code,
      request_id: requestId
    });

    return new Response(JSON.stringify({
      failure_code,
      detail: 'Failed to redact PII from text',
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
