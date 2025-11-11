import { serve } from "https://deno.land/std@0.177.0/http/server.ts";

const RESEND_API_KEY = Deno.env.get("RESEND_API_KEY");

serve(async (req) => {
  try {
    if (!RESEND_API_KEY) {
      return new Response(JSON.stringify({ error: "Missing RESEND_API_KEY" }), { status: 500, headers: { "Content-Type": "application/json" } });
    }

    const { to, subject, text } = await req.json().catch(() => ({}));

    if (!to) {
      return new Response(JSON.stringify({ error: "Missing 'to'" }), { status: 400, headers: { "Content-Type": "application/json" } });
    }

    const payload = {
      from: "SmartVoiceNotes Support <support@updates.smartvoicenotes.com>", // verified subdomain
      to: [to],
      subject: subject ?? "SVN smoke test",
      text: text ?? "Email pipeline OK."
    };

    const r = await fetch("https://api.resend.com/emails", {
      method: "POST",
      headers: {
        "Authorization": `Bearer ${RESEND_API_KEY}`,
        "Content-Type": "application/json"
      },
      body: JSON.stringify(payload)
    });

    const body = await r.text();
    return new Response(JSON.stringify({ upstream_status: r.status, upstream_body: body }), {
      status: 200,
      headers: { "Content-Type": "application/json" }
    });
  } catch (e) {
    return new Response(JSON.stringify({ error: String(e) }), { status: 500, headers: { "Content-Type": "application/json" } });
  }
});

