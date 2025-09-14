// supabase/functions/deepgram-transcribe/index.ts
// CORS-safe Deepgram proxy: POST { audio_url } -> returns Deepgram JSON
// No custom auth: Supabase gateway verifies the JWT (anon is fine).

import { serve } from "https://deno.land/std@0.224.0/http/server.ts";

const ALLOW_ORIGIN = "*"; // tighten to your domain later

function j(body: unknown, status = 200, extraHeaders: Record<string, string> = {}) {
  return new Response(JSON.stringify(body), {
    status,
    headers: {
      "content-type": "application/json",
      "access-control-allow-origin": ALLOW_ORIGIN,
      "access-control-allow-headers": "authorization,apikey,content-type",
      "access-control-allow-methods": "POST,OPTIONS,GET",
      ...extraHeaders,
    },
  });
}

serve(async (req: Request) => {
  // CORS preflight
  if (req.method === "OPTIONS") {
    return new Response(null, {
      status: 204,
      headers: {
        "access-control-allow-origin": ALLOW_ORIGIN,
        "access-control-allow-headers": "authorization,apikey,content-type",
        "access-control-allow-methods": "POST,OPTIONS,GET",
      },
    });
  }

  if (req.method === "GET") {
    return j({ ok: true, route: "deepgram-transcribe" });
  }

  if (req.method !== "POST") {
    return j({ error: "Method not allowed" }, 405);
  }

  const dgKey = Deno.env.get("DEEPGRAM_API_KEY");
  if (!dgKey) return j({ error: "Missing DEEPGRAM_API_KEY" }, 500);

  const ct = req.headers.get("content-type") ?? "";
  if (!ct.includes("application/json")) {
    return j({ error: "Send JSON with { audio_url: <url> }" }, 400);
  }

  let audio_url: string | undefined;
  try {
    const body = await req.json();
    audio_url = body?.audio_url ?? body?.url ?? body?.audioUrl;
  } catch {
    return j({ error: "Invalid JSON body" }, 400);
  }

  if (!audio_url || typeof audio_url !== "string") {
    return j({ error: "Missing audio_url" }, 400);
  }

  const endpoint =
    "https://api.deepgram.com/v1/listen?punctuate=true&smart_format=true";

  const dgResp = await fetch(endpoint, {
    method: "POST",
    headers: {
      Authorization: `Token ${dgKey}`,
      "content-type": "application/json",
    },
    body: JSON.stringify({ url: audio_url }),
  });

  const dgJson = await dgResp.json().catch(() => ({ error: "Non-JSON from Deepgram" }));
  return j(dgJson, dgResp.status);
});
