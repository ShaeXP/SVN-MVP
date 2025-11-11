// supabase/functions/sv_get_run/index.ts
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const SB_URL  = Deno.env.get("SUPABASE_URL")!;
const SB_ANON = Deno.env.get("SUPABASE_ANON_KEY")!;

function log(event: Record<string, unknown>) {
  console.log(JSON.stringify({ svc: "sv_get_run", ts: new Date().toISOString(), ...event }));
}

Deno.serve(async (req) => {
  const reqId = crypto.randomUUID();
  try {
    if (!SB_URL || !SB_ANON) {
      log({ reqId, level: "error", msg: "missing env", hasUrl: !!SB_URL, hasAnon: !!SB_ANON });
      return new Response(JSON.stringify({ error: "Missing SUPABASE_URL or SUPABASE_ANON_KEY" }), {
        status: 500, headers: { "Content-Type": "application/json" },
      });
    }

    // Auth
    const auth = req.headers.get("Authorization") ?? "";
    if (!auth.startsWith("Bearer ")) {
      return new Response(JSON.stringify({ error: "Auth required" }), {
        status: 401, headers: { "Content-Type": "application/json" },
      });
    }
    const supabase = createClient(SB_URL, SB_ANON, { global: { headers: { Authorization: auth } } });
    const { data: { user }, error: userErr } = await supabase.auth.getUser();
    if (userErr || !user) {
      return new Response(JSON.stringify({ error: "Invalid token" }), {
        status: 401, headers: { "Content-Type": "application/json" },
      });
    }

    // Params
    const url = new URL(req.url);
    const id = url.searchParams.get("id")?.trim();
    const uuidRe = /^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;
    if (!id || !uuidRe.test(id)) {
      return new Response(JSON.stringify({ error: "Missing or invalid 'id' (uuid v4)" }), {
        status: 400, headers: { "Content-Type": "application/json" },
      });
    }

    // Query (RLS ensures user can only see their own)
    const { data, error } = await supabase
      .from("sv_runs")
      .select("id, created_at, audio_url, email_to, email_subject, transcript_len, summary_len, email_upstream_status, email_id, idempotency_key, status_tag")
      .eq("user_id", user.id)
      .eq("id", id)
      .maybeSingle();

    if (error) {
      log({ reqId, level: "error", stage: "query", err: error.message, id });
      return new Response(JSON.stringify({ error: "Query failed" }), {
        status: 500, headers: { "Content-Type": "application/json" },
      });
    }
    if (!data) {
      return new Response(JSON.stringify({ error: "Not found" }), {
        status: 404, headers: { "Content-Type": "application/json" },
      });
    }

    log({ reqId, level: "info", userId: user.id, id });
    return new Response(JSON.stringify(data), {
      status: 200, headers: { "Content-Type": "application/json" },
    });

  } catch (e) {
    log({ level: "error", msg: "unhandled", err: String(e) });
    return new Response(JSON.stringify({ error: "Unhandled" }), {
      status: 500, headers: { "Content-Type": "application/json" },
    });
  }
});
