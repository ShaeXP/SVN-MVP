// supabase/functions/sv_delete_run/index.ts
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const SB_URL  = Deno.env.get("SUPABASE_URL")!;
const SB_ANON = Deno.env.get("SUPABASE_ANON_KEY")!;

function log(e: Record<string, unknown>) {
  console.log(JSON.stringify({ svc: "sv_delete_run", ts: new Date().toISOString(), ...e }));
}

Deno.serve(async (req) => {
  const reqId = crypto.randomUUID();
  try {
    if (!SB_URL || !SB_ANON) {
      return new Response(JSON.stringify({ error: "Missing SUPABASE_URL/ANON" }), { status: 500, headers: { "Content-Type": "application/json" } });
    }

    if (req.method !== "DELETE") {
      return new Response(JSON.stringify({ error: "Use DELETE" }), { status: 405, headers: { "Allow": "DELETE", "Content-Type": "application/json" } });
    }

    const auth = req.headers.get("Authorization") ?? "";
    if (!auth.startsWith("Bearer ")) {
      return new Response(JSON.stringify({ error: "Auth required" }), { status: 401, headers: { "Content-Type": "application/json" } });
    }
    const supabase = createClient(SB_URL, SB_ANON, { global: { headers: { Authorization: auth } } });
    const { data: { user }, error: userErr } = await supabase.auth.getUser();
    if (userErr || !user) {
      return new Response(JSON.stringify({ error: "Invalid token" }), { status: 401, headers: { "Content-Type": "application/json" } });
    }

    const url = new URL(req.url);
    const id = url.searchParams.get("id")?.trim();
    const uuidRe = /^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;
    if (!id || !uuidRe.test(id)) {
      return new Response(JSON.stringify({ error: "Missing or invalid 'id' (uuid v4)" }), { status: 400, headers: { "Content-Type": "application/json" } });
    }

    // RLS ensures only the owner can delete; we also filter by user_id.
    const { error, count } = await supabase
      .from("sv_runs")
      .delete({ count: "exact" })
      .eq("user_id", user.id)
      .eq("id", id);

    if (error) {
      log({ reqId, level: "error", stage: "delete", err: error.message, id, userId: user.id });
      return new Response(JSON.stringify({ error: "Delete failed" }), { status: 500, headers: { "Content-Type": "application/json" } });
    }
    if (!count) {
      return new Response(JSON.stringify({ error: "Not found" }), { status: 404, headers: { "Content-Type": "application/json" } });
    }

    log({ reqId, level: "info", stage: "deleted", id, userId: user.id });
    return new Response(JSON.stringify({ deleted: true }), { status: 200, headers: { "Content-Type": "application/json" } });
  } catch (e) {
    log({ level: "error", msg: "unhandled", err: String(e) });
    return new Response(JSON.stringify({ error: "Unhandled" }), { status: 500, headers: { "Content-Type": "application/json" } });
  }
});
