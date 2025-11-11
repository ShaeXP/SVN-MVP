import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { Document, Packer, Paragraph, HeadingLevel, TextRun } from "npm:docx@8";

function J(status: number, body: unknown) {
  return new Response(JSON.stringify(body), { status, headers: { "Content-Type": "application/json" } });
}

function makeFromHeader(fromEmailRaw?: string | null, fromNameRaw?: string | null): string {
  const rawE = (fromEmailRaw ?? "").trim();
  const rawN = (fromNameRaw ?? "").trim();

  // extract email even if it's inside <>
  const match = rawE.match(/<?\s*([^<>\s]+@[^<>\s]+)\s*>?/);
  const email = match?.[1] ?? "";

  const simple = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
  if (!simple.test(email)) {
    // last resort: verified sender you own
    return "notifications@updates.smartvoicenotes.com";
  }

  // If the env already supplied "Name <email>" or "<email>", normalize it
  const hasAngles = /<.*>/.test(rawE);
  if (hasAngles) {
    const namePart = rawE.replace(/<.*>/, "").trim().replace(/^"+|"+$/g, "");
    return namePart ? `${namePart} <${email}>` : email;
  }

  // Otherwise compose from separate name (if clean)
  const cleanName = rawN.replace(/^"+|"+$/g, "").trim();
  return cleanName && !/[<>]/.test(cleanName) ? `${cleanName} <${email}>` : email;
}

const fname = (s: string) => (s || "summary").replace(/[^\w\- ]+/g, "_").slice(0, 100);
const jwtEmail = (token: string): string | null => {
  try { return JSON.parse(atob(token.split(".")[1]))?.email ?? null; } catch { return null; }
};

serve(async (req) => {
  try {
    if (req.method !== "POST") return J(405, { ok: false, error: "Method Not Allowed" });

    const auth = req.headers.get("Authorization") ?? "";
    const jwt = auth.startsWith("Bearer ") ? auth.slice(7) : null;
    if (!jwt) return J(401, { ok: false, error: "Missing Bearer token" });

    const { recordingId, summaryId, test } = await req.json().catch(() => ({}));
    if (!recordingId && !summaryId) return J(400, { ok: false, error: "recordingId or summaryId required" });

    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const apiKey = Deno.env.get("PUBLISHABLE_KEY"); // <-- new key model
    if (!apiKey) return J(500, { ok: false, error: "PUBLISHABLE_KEY missing" });

    // Use publishable key; pass user JWT so RLS runs as the caller
    const supabase = createClient(supabaseUrl, apiKey, {
      global: { headers: { Authorization: `Bearer ${jwt}` } },
    });

    // Resolve user email (SDK first; JWT fallback)
    const { data: u } = await supabase.auth.getUser();
    const userEmail = u?.user?.email ?? jwtEmail(jwt);
    if (!userEmail) return J(401, { ok: false, error: "No user email on token" });

    // Resolve recording id (accept recordingId or summaryId)
    let recId: string | null = recordingId ?? null;
    if (!recId && summaryId) {
      const { data: sumRow, error: sumErr } = await supabase
        .from("summaries")
        .select("recording_id")
        .eq("id", summaryId)
        .maybeSingle();
      if (sumErr) return J(500, { ok: false, error: `summary lookup failed: ${sumErr.message}` });
      recId = sumRow?.recording_id ?? null;
    }
    if (!recId) return J(404, { ok: false, error: "Recording not found" });

    // Verify recording (RLS-protected)
    const { data: recBasic, error: recErr } = await supabase
      .from("recordings")
      .select("id, user_id, created_at, duration_sec, status")
      .eq("id", recId)
      .maybeSingle();
    if (recErr) return J(500, { ok: false, error: `recording lookup failed: ${recErr.message}` });
    if (!recBasic) return J(404, { ok: false, error: "Recording not found" });

    // Latest summary (your schema)
    const { data: sumLatest, error: sErr } = await supabase
      .from("summaries")
      .select("id, title, summary, bullets, action_items, created_at")
      .eq("recording_id", recId)
      .order("created_at", { ascending: false })
      .limit(1)
      .maybeSingle();
    if (sErr) return J(500, { ok: false, error: `summary fetch failed: ${sErr.message}` });

    // Optional transcript (ignore if table missing)
    let transcriptText = "Transcript will appear when ready.";
    const { data: tr } = await supabase
      .from("transcripts")
      .select("text, created_at")
      .eq("recording_id", recId)
      .order("created_at", { ascending: false })
      .limit(1)
      .maybeSingle();
    if (tr?.text) transcriptText = tr.text;

    // Map to DOCX
    const title: string = sumLatest?.title ?? "Recording Summary";
    const summaryText: string = sumLatest?.summary ?? "No summary yet.";
    const bullets: string[] = Array.isArray(sumLatest?.bullets)
      ? (sumLatest!.bullets as string[])
      : (typeof sumLatest?.bullets === "string"
          ? (sumLatest!.bullets as string).split(/\r?\n/).filter(Boolean)
          : []);
    const createdAt = new Date(recBasic.created_at).toLocaleString();
    const status = recBasic.status ?? "unknown";

    const doc = new Document({
      sections: [{
        children: [
          new Paragraph({ text: title, heading: HeadingLevel.HEADING_1 }),
          new Paragraph({ text: `Created: ${createdAt}` }),
          new Paragraph({ text: `Status: ${status}` }),
          ...(recBasic.duration_sec ? [new Paragraph({ text: `Duration: ${recBasic.duration_sec} sec` })] : []),
          new Paragraph({ text: "" }),
          new Paragraph({ text: "Summary", heading: HeadingLevel.HEADING_2 }),
          new Paragraph({ children: [new TextRun(summaryText)] }),
          new Paragraph({ text: "" }),
          new Paragraph({ text: "Key Points", heading: HeadingLevel.HEADING_2 }),
          ...(bullets.length ? bullets.map((x) => new Paragraph({ text: x, bullet: { level: 0 } })) : [new Paragraph({ text: "—" })]),
          new Paragraph({ text: "" }),
          new Paragraph({ text: "Transcript", heading: HeadingLevel.HEADING_2 }),
          new Paragraph({ children: [new TextRun(transcriptText.slice(0, 100000))] }),
        ],
      }],
    });

    const buf = await Packer.toBuffer(doc);
    const b64 = btoa(String.fromCharCode(...new Uint8Array(buf)));

    const RESEND_API_KEY = Deno.env.get("RESEND_API_KEY");
    const FROM_EMAIL = Deno.env.get("FROM_EMAIL"); // may be "email" or "Name <email>"
    const FROM_NAME  = Deno.env.get("FROM_NAME");  // optional separate name
    if (!RESEND_API_KEY) return J(500, { ok: false, error: "RESEND_API_KEY missing" });

    const fromHeader = makeFromHeader(FROM_EMAIL, FROM_NAME);
    // DEBUG (safe to log): show what we're sending
    console.log("[EMAIL_DOCX] fromHeader:", fromHeader);
    console.log("[EMAIL_DOCX] sending to:", userEmail);

    // Optional test endpoint for isolation testing
    if (test) {
      console.log("[EMAIL_DOCX] test mode - sending plain text email");
      const testRes = await fetch("https://api.resend.com/emails", {
        method: "POST",
        headers: {
          "Authorization": `Bearer ${RESEND_API_KEY}`,
          "Content-Type": "application/json"
        },
        body: JSON.stringify({
          from: fromHeader,
          to: [userEmail],
          subject: `Test Email — SmartVoiceNotes`,
          text: "This is a test email to verify delivery without attachments.",
        }),
      });
      const testText = await testRes.text();
      let testJson: any = {};
      try { testJson = JSON.parse(testText); } catch {}
      console.log("[EMAIL_DOCX] test resend status:", testRes.status, "body:", testText.slice(0, 400));
      
      if (!testRes.ok) return J(502, { ok: false, error: testJson?.message ?? testText ?? "Test email send failed" });
      
      return J(200, { ok: true, id: testJson?.id ?? null, to: userEmail, test: true });
    }

    const res = await fetch("https://api.resend.com/emails", {
      method: "POST",
      headers: {
        "Authorization": `Bearer ${RESEND_API_KEY}`,
        "Content-Type": "application/json",
        "Idempotency-Key": crypto.randomUUID()
      },
      body: JSON.stringify({
        from: fromHeader,
        to: [userEmail],
        subject: `${title} — SmartVoiceNotes`,
        text: "Your summary is attached as a .docx file.",
        reply_to: "support@updates.smartvoicenotes.com",
        attachments: [{
          filename: `${fname(title)}.docx`,
          content: b64,
          contentType: "application/vnd.openxmlformats-officedocument.wordprocessingml.document"
        }],
      }),
    });

    const resText = await res.text();
    let resJson: any = {};
    try { resJson = JSON.parse(resText); } catch {}
    console.log("[EMAIL_DOCX] resend status:", res.status, "body:", resText.slice(0, 400));

    if (!res.ok) return J(res.status, { ok: false, error: resJson?.message ?? resText ?? "Email send failed" });

    return J(200, { ok: true, id: resJson?.id ?? null, to: userEmail });
  } catch (e) {
    return J(500, { ok: false, error: String(e) });
  }
});