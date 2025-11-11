// supabase/functions/sv_metrics/index.ts
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const SB_URL  = Deno.env.get("SUPABASE_URL")!;
const SB_ANON = Deno.env.get("SUPABASE_ANON_KEY")!;

function log(e: Record<string, unknown>) {
  console.log(JSON.stringify({ svc: "sv_metrics", ts: new Date().toISOString(), ...e }));
}

function pct(arr: number[], p: number) {
  if (arr.length === 0) return null;
  const i = Math.min(arr.length - 1, Math.max(0, Math.floor((p / 100) * (arr.length - 1))));
  return arr[i];
}

Deno.serve(async (req) => {
  const reqId = crypto.randomUUID();
  try {
    if (!SB_URL || !SB_ANON) {
      return new Response(JSON.stringify({ error: "Missing SUPABASE_URL/ANON" }), { status: 500, headers: { "Content-Type": "application/json" } });
    }

    // Auth
    const auth = req.headers.get("Authorization") ?? "";
    if (!auth.startsWith("Bearer ")) {
      return new Response(JSON.stringify({ error: "Auth required" }), { status: 401, headers: { "Content-Type": "application/json" } });
    }
    const supabase = createClient(SB_URL, SB_ANON, { global: { headers: { Authorization: auth } } });
    const { data: { user }, error: userErr } = await supabase.auth.getUser();
    if (userErr || !user) {
      return new Response(JSON.stringify({ error: "Invalid token" }), { status: 401, headers: { "Content-Type": "application/json" } });
    }

    // Params
    const url = new URL(req.url);
    const hours = Math.max(1, Math.min(24 * 30, parseInt(url.searchParams.get("hours") ?? "168"))); // default 7d
    const limit = Math.max(1, Math.min(5000, parseInt(url.searchParams.get("limit") ?? "1000")));
    const sinceParam = url.searchParams.get("since");
    const until = new Date();
    const since = sinceParam ? new Date(sinceParam) : new Date(until.getTime() - hours * 3600 * 1000);
    const sinceISO = since.toISOString();

    // Query
    let q = supabase
      .from("sv_runs")
      .select("created_at,status_tag,email_upstream_status,t_total_ms,t_transcribe_ms,t_summarize_ms,t_email_ms")
      .eq("user_id", user.id)
      .gte("created_at", sinceISO)
      .order("created_at", { ascending: false })
      .limit(limit);

    const { data, error } = await q;
    if (error) {
      log({ reqId, level: "error", stage: "query", err: error.message });
      return new Response(JSON.stringify({ error: "Query failed" }), { status: 500, headers: { "Content-Type": "application/json" } });
    }

    const rows = data ?? [];
    const total = rows.length;

    // Success definition: upstream 200 (sent) OR 409 (idempotency duplicate_suppressed)
    let sent200 = 0, dup409 = 0, fail = 0;
    const totals: number[] = [];
    const tTrans: number[] = [], tSum: number[] = [], tEmail: number[] = [];

    for (const r of rows) {
      const up = r.email_upstream_status as number | null;
      if (up === 200) sent200++;
      else if (up === 409) dup409++;
      else fail++;

      if (typeof r.t_total_ms === "number") totals.push(r.t_total_ms);
      if (typeof r.t_transcribe_ms === "number") tTrans.push(r.t_transcribe_ms);
      if (typeof r.t_summarize_ms === "number") tSum.push(r.t_summarize_ms);
      if (typeof r.t_email_ms === "number") tEmail.push(r.t_email_ms);
    }

    totals.sort((a,b)=>a-b);
    const success = sent200 + dup409;
    const successRate = total ? (success / total) : null;

    const avg = (arr: number[]) => arr.length ? Math.round(arr.reduce((a,b)=>a+b,0) / arr.length) : null;
    const max = (arr: number[]) => arr.length ? Math.max(...arr) : null;

    const resp = {
      window: { since: since.toISOString(), until: until.toISOString(), hours, limit },
      counts: { total, success, fail, sent_200: sent200, duplicate_409: dup409 },
      success_rate: successRate,
      t_total_ms: {
        avg: avg(totals),
        p50: pct(totals, 50),
        p90: pct(totals, 90),
        p95: pct(totals, 95),
        max: max(totals),
      },
      stages_avg_ms: {
        transcribe: avg(tTrans),
        summarize: avg(tSum),
        email: avg(tEmail),
      },
      last_run_at: rows[0]?.created_at ?? null,
    };

    log({ reqId, level: "info", userId: user.id, total, success, fail });
    return new Response(JSON.stringify(resp), { status: 200, headers: { "Content-Type": "application/json" } });

  } catch (e) {
    log({ level: "error", msg: "unhandled", err: String(e) });
    return new Response(JSON.stringify({ error: "Unhandled" }), { status: 500, headers: { "Content-Type": "application/json" } });
  }
});
