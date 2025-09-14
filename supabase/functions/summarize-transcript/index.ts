import { serve } from "https://deno.land/std@0.224.0/http/server.ts";

const ALLOW_ORIGIN = "*"; // tighten later

function json(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: {
      "content-type": "application/json",
      "access-control-allow-origin": ALLOW_ORIGIN,
      "access-control-allow-headers": "authorization,apikey,content-type",
      "access-control-allow-methods": "POST,OPTIONS",
    },
  });
}

serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response(null, {
      status: 204,
      headers: {
        "access-control-allow-origin": ALLOW_ORIGIN,
        "access-control-allow-headers": "authorization,apikey,content-type",
        "access-control-allow-methods": "POST,OPTIONS",
      },
    });
  }

  if (req.method !== "POST") return json({ error: "Method not allowed" }, 405);

  const key = Deno.env.get("OPENAI_API_KEY");
  if (!key) return json({ error: "Missing OPENAI_API_KEY" }, 500);

  let transcriptText = "";
  try {
    const body = await req.json();
    transcriptText = (body?.transcript_text ?? "").toString();
  } catch {
    return json({ error: "Invalid JSON body" }, 400);
  }
  if (!transcriptText) return json({ error: "Missing transcript_text" }, 400);

  const userPrompt = [
    "You summarize voice notes for busy founders.",
    "Return a compact summary (3–6 bullets) plus 3 action items with owners if present.",
    "No fluff. Use the speaker’s language. If uncertain, say so briefly.",
    "",
    "TRANSCRIPT:",
    transcriptText.slice(0, 20000)
  ].join("\n");

  const resp = await fetch("https://api.openai.com/v1/chat/completions", {
    method: "POST",
    headers: { "Authorization": `Bearer ${key}`, "Content-Type": "application/json" },
    body: JSON.stringify({
      model: "gpt-4o-mini",
      messages: [
        { role: "system", content: "You are a precise meeting/voice-note summarizer." },
        { role: "user", content: userPrompt }
      ],
      temperature: 0.2,
      max_tokens: 600
    })
  });

  if (!resp.ok) {
    const err = await resp.text().catch(() => "");
    return json({ error: "LLM_ERROR", detail: err }, resp.status);
  }

  const data = await resp.json();
  const summary = data?.choices?.[0]?.message?.content ?? "";
  return json({ summary });
});
