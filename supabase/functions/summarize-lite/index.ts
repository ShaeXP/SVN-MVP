import { serve } from "https://deno.land/std@0.177.0/http/server.ts";

// naive, deterministic "summary" so we can smoke-test without LLMs
function summarize(input: string) {
  const text = input.trim().replace(/\s+/g, " ");
  const sentences = text.split(/(?<=[.!?])\s+/).filter(Boolean);
  const summary = sentences.slice(0, 2).join(" ");
  const words = text.toLowerCase().match(/[a-z0-9']+/g) ?? [];
  const freq = new Map<string, number>();
  for (const w of words) freq.set(w, (freq.get(w) ?? 0) + 1);
  const stop = new Set(["the","and","to","of","a","in","it","is","that","you","for","on","with","as","are","be","this","i","or","was","at","by","an","from"]);
  const top = [...freq.entries()]
    .filter(([w]) => !stop.has(w) && w.length > 2)
    .sort((a,b) => b[1]-a[1])
    .slice(0,5)
    .map(([w]) => `• ${w}`);
  return { summary, bullets: top };
}

serve(async (req) => {
  try {
    const body = await req.json().catch(() => ({} as any));
    const transcript = body.transcript ?? body.text ?? body.content;
    if (!transcript || typeof transcript !== "string") {
      return new Response(JSON.stringify({ error: "Provide transcript/text/content string" }), { status: 400, headers: { "Content-Type": "application/json" } });
    }
    const out = summarize(transcript);
    return new Response(JSON.stringify(out), { status: 200, headers: { "Content-Type": "application/json" } });
  } catch (e) {
    return new Response(JSON.stringify({ error: String(e) }), { status: 500, headers: { "Content-Type": "application/json" } });
  }
});


