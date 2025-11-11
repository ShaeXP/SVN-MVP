// supabase/functions/sv_list_runs/index.ts
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const SB_URL  = Deno.env.get("SUPABASE_URL")!;
const SB_ANON = Deno.env.get("SUPABASE_ANON_KEY")!;

function log(event: Record<string, unknown>) {
  console.log(JSON.stringify({ svc: "sv_list_runs", ts: new Date().toISOString(), ...event }));
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
    const limit = Math.max(1, Math.min(50, parseInt(url.searchParams.get("limit") ?? "20")));
    const cursor = url.searchParams.get("cursor"); // ISO timestamp of last item from previous page

    // Query
    let q = supabase
      .from("sv_runs")
      .select(
        "id, created_at, audio_url, email_to, email_subject, transcript_len, summary_len, email_upstream_status, email_id, idempotency_key, status_tag",
      )
      .eq("user_id", user.id)
      .order("created_at", { ascending: false })
      .limit(limit);

    if (cursor) q = q.lt("created_at", cursor);

    const { data, error } = await q;
    if (error) {
      log({ reqId, level: "error", stage: "query", err: error.message });
      return new Response(JSON.stringify({ error: "Query failed" }), {
        status: 500, headers: { "Content-Type": "application/json" },
      });
    }

    const next_cursor = (data && data.length === limit) ? data[data.length - 1].created_at : null;

    log({ reqId, level: "info", userId: user.id, count: data?.length ?? 0 });
    return new Response(JSON.stringify({ items: data ?? [], next_cursor }), {
      status: 200, headers: { "Content-Type": "application/json" },
    });
  } catch (e) {
    log({ level: "error", msg: "unhandled", err: String(e) });
    return new Response(JSON.stringify({ error: "Unhandled" }), {
      status: 500, headers: { "Content-Type": "application/json" },
    });
  }
});
