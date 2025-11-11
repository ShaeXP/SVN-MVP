// supabase/functions/sv_process_upload/index.ts
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const DG_KEY = Deno.env.get("DEEPGRAM_API_KEY");
const SB_URL = Deno.env.get("SUPABASE_URL")!;
const SB_ANON = Deno.env.get("SUPABASE_ANON_KEY")!;

function summarize(input: string) {
  const text = input.trim().replace(/\s+/g, " ");
  const sentences = text.split(/(?<=[.!?])\s+/).filter(Boolean);
  const summary = sentences.slice(0, 2).join(" ");
  const words = text.toLowerCase().match(/[a-z0-9']+/g) ?? [];
  const stop = new Set(["the","and","to","of","a","in","it","is","that","you","for","on","with","as","are","be","this","i","or","was","at","by","an","from"]);
  const freq = new Map<string, number>();
  for (const w of words) if (!stop.has(w) && w.length > 2) freq.set(w, (freq.get(w) ?? 0) + 1);
  const bullets = [...freq.entries()].sort((a,b)=>b[1]-a[1]).slice(0,5).map(([w])=>`• ${w}`);
  return { summary, bullets };
}

function log(event: Record<string, unknown>) {
  console.log(JSON.stringify({ svc: "sv_process_upload", ts: new Date().toISOString(), ...event }));
}

Deno.serve(async (req) => {
  const reqId = crypto.randomUUID();
  const startedAt = performance.now();

  try {
    if (!DG_KEY || !SB_URL || !SB_ANON) {
      log({ reqId, level: "error", msg: "missing env", hasDG: !!DG_KEY, hasUrl: !!SB_URL, hasAnon: !!SB_ANON });
      return new Response(JSON.stringify({ error: "Missing required env" }), { status: 500, headers: { "Content-Type": "application/json" } });
    }

    // Auth
    const auth = req.headers.get("Authorization") ?? "";
    if (!auth.startsWith("Bearer ")) {
      log({ reqId, level: "warn", stage: "auth", msg: "no bearer" });
      return new Response(JSON.stringify({ error: "Auth required" }), { status: 401, headers: { "Content-Type": "application/json" } });
    }
    const supabase = createClient(SB_URL, SB_ANON, { global: { headers: { Authorization: auth } } });
    const { data: { user }, error: userErr } = await supabase.auth.getUser();
    if (userErr || !user) {
      log({ reqId, level: "warn", stage: "auth", msg: "invalid token", userErr });
      return new Response(JSON.stringify({ error: "Invalid token" }), { status: 401, headers: { "Content-Type": "application/json" } });
    }
    const userId = user.id;

    // Input
    const { storage_path, recording_id, run_id } = await req.json().catch(() => ({}));
    if (!storage_path || !recording_id) {
      log({ reqId, level: "warn", stage: "input", userId, hasStoragePath: !!storage_path, hasRecordingId: !!recording_id });
      return new Response(JSON.stringify({ error: "Missing 'storage_path' or 'recording_id'" }), { status: 400, headers: { "Content-Type": "application/json" } });
    }

    // Get signed URL for the audio file
    const { data: signedUrl, error: urlError } = await supabase.storage
      .from('recordings')
      .createSignedUrl(storage_path.replace('recordings/', ''), 3600); // 1 hour expiry

    if (urlError || !signedUrl?.signedUrl) {
      log({ reqId, level: "error", stage: "signed_url", userId, error: urlError });
      return new Response(JSON.stringify({ error: "Failed to get signed URL" }), { status: 500, headers: { "Content-Type": "application/json" } });
    }

    // Update recording status to transcribing
    await supabase.from('recordings').update({ status: 'transcribing' }).eq('id', recording_id);

    // Transcribe
    const t0 = performance.now();
    const dgReq = { url: signedUrl.signedUrl, model: "general", smart_format: true, punctuate: true };
    const dgRes = await fetch("https://api.deepgram.com/v1/listen", {
      method: "POST",
      headers: { "Authorization": `Token ${DG_KEY}`, "Content-Type": "application/json" },
      body: JSON.stringify(dgReq)
    });
    const dgText = await dgRes.text();
    const t1 = performance.now();
    const tTranscribeMs = Math.round(t1 - t0);

    if (!dgRes.ok) {
      log({ reqId, level: "error", stage: "transcribe", status: dgRes.status, bodyLen: dgText.length, tTranscribeMs });
      await supabase.from('recordings').update({ status: 'error' }).eq('id', recording_id);
      return new Response(JSON.stringify({ stage: "transcribe", upstream_status: dgRes.status, upstream_body: dgText }), { status: 200, headers: { "Content-Type": "application/json" } });
    }

    let transcript = "";
    try { const j = JSON.parse(dgText); transcript = j?.results?.channels?.[0]?.alternatives?.[0]?.transcript ?? ""; } catch {}
    if (!transcript) {
      log({ reqId, level: "warn", stage: "transcribe", msg: "empty transcript", tTranscribeMs });
      await supabase.from('recordings').update({ status: 'error' }).eq('id', recording_id);
      return new Response(JSON.stringify({ stage: "transcribe", error: "No transcript extracted", upstream_body: dgText }), { status: 200, headers: { "Content-Type": "application/json" } });
    }
    log({ reqId, level: "info", stage: "transcribe", transcript_len: transcript.length, tTranscribeMs });

    // Update recording status to summarizing
    await supabase.from('recordings').update({ status: 'summarizing' }).eq('id', recording_id);

    // Summarize
    const s0 = performance.now();
    const { summary, bullets } = summarize(transcript);
    const s1 = performance.now();
    const tSummarizeMs = Math.round(s1 - s0);
    log({ reqId, level: "info", stage: "summarize", summary_len: summary.length, bullets: bullets.length, tSummarizeMs });

    // Insert summary
    const { error: summaryError } = await supabase.from('summaries').insert({
      recording_id: recording_id,
      title: `Recording ${new Date().toLocaleDateString()}`,
      summary: summary,
      bullets: bullets,
      action_items: [], // Could be extracted from transcript in the future
      tags: [],
      confidence: 0.8
    });

    if (summaryError) {
      log({ reqId, level: "error", stage: "summary_insert", error: summaryError });
    }

    // Update recording status to ready
    await supabase.from('recordings').update({ status: 'ready' }).eq('id', recording_id);

    const tTotalMs = Math.round(performance.now() - startedAt);
    log({ reqId, level: "info", stage: "complete", userId, recording_id, tTotalMs });

    return new Response(JSON.stringify({
      status: "ready",
      recording_id: recording_id,
      run_id: run_id,
      transcript_len: transcript.length,
      summary_len: summary.length,
      t_transcribe_ms: tTranscribeMs,
      t_summarize_ms: tSummarizeMs,
      t_total_ms: tTotalMs
    }), { status: 200, headers: { "Content-Type": "application/json" } });

  } catch (e) {
    log({ level: "error", msg: "unhandled", err: String(e) });
    return new Response(JSON.stringify({ error: String(e) }), { status: 500, headers: { "Content-Type": "application/json" } });
  }
});
