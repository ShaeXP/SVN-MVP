// supabase/functions/sv_delete_recording/index.ts
import 'jsr:@supabase/functions-js/edge-runtime.d.ts'
import { createClient } from 'jsr:@supabase/supabase-js@2'

const cors = {
  'access-control-allow-origin': '*',
  'access-control-allow-headers': 'authorization, x-client-info, apikey, content-type, x-trace-id, x-path',
}

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: cors })

  const exec = Deno.env.get('SB_EXECUTION_ID') ?? null
  const trace = req.headers.get('x-trace-id') ?? `${Date.now().toString(36)}-${Math.random().toString(36).slice(2,7)}`
  const pathOverride = req.headers.get('x-path')
  if (req.method === 'GET' || pathOverride === '/health') {
    console.log('[sv_delete_recording] health', { exec, trace })
    return json({ ok: true, exec, trace })
  }

  if (req.method !== 'POST') return json({ ok:false, code:'method', message:'POST required' }, 405)

  try {
    const supabase = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_ANON_KEY')!,
      { global: { headers: { Authorization: req.headers.get('Authorization') ?? '' } } }
    )

    const { data: { user }, error: authErr } = await supabase.auth.getUser()
    if (authErr || !user) return json({ ok:false, code:'unauthorized', message:'No user' }, 401)

    const body = await req.json().catch(() => ({}))
    const recId = String(body?.recordingId ?? '').trim()
    if (!recId || !/^[0-9a-fA-F-]{36}$/.test(recId)) return json({ ok:false, code:'bad_request', message:'recordingId required (uuid)' }, 400)

    // Fetch recording to confirm ownership and get storage/transcript links
    const { data: rec, error: recErr } = await supabase
      .from('recordings')
      .select('id,user_id,storage_path,status')
      .eq('id', recId)
      .eq('user_id', user.id)
      .maybeSingle()
    if (recErr || !rec) return json({ ok:false, code:'not_found', message:'recording not found' }, 404)

    console.log('[sv_delete_recording] start', { recId, userId: user.id, trace, status: rec.status })

    // Best-effort deletes. Each step is isolated; failures are logged but do not abort the whole deletion.
    // 1) summaries (no user_id column, RLS handles ownership)
    try {
      await supabase.from('summaries').delete().eq('recording_id', recId)
    } catch (e) {
      console.error('[sv_delete_recording] summaries delete fail', { trace, msg: String(e) })
    }

    // 2) notes (optional table)
    try {
      await supabase.from('notes').delete().eq('recording_id', recId)
    } catch (_) {
      // ignore if table doesn't exist
    }

    // 3) transcripts (by recording_id)
    try {
      await supabase.from('transcripts').delete().eq('recording_id', recId)
    } catch (e) {
      console.error('[sv_delete_recording] transcript delete fail', { trace, msg: String(e) })
    }

    // 4) storage object
    if (rec.storage_path && typeof rec.storage_path === 'string') {
      try {
        const sp: string = rec.storage_path as string
        const [bucket, ...rest] = sp.split('/')
        const objectPath = rest.join('/')
        if (bucket && objectPath) {
          const rm = await supabase.storage.from(bucket).remove([objectPath])
          if (rm?.error) console.error('[sv_delete_recording] storage remove error', { trace, msg: rm.error.message })
        }
      } catch (e) {
        console.error('[sv_delete_recording] storage remove fail', { trace, msg: String(e) })
      }
    }

    // 5) recording row
    const { error: delErr } = await supabase.from('recordings').delete().eq('id', recId).eq('user_id', user.id)
    if (delErr) return json({ ok:false, code:'delete_failed', message: delErr.message, trace }, 500)

    console.log('[sv_delete_recording] ok', { recId, trace })
    return json({ ok: true, trace })
  } catch (e) {
    console.error('[sv_delete_recording] error', { trace, msg: String(e) })
    return json({ ok:false, code:'unhandled', message:String(e), trace }, 500)
  }
})

function json(data: unknown, status = 200) {
  return new Response(JSON.stringify(data), { status, headers: { ...cors, 'content-type':'application/json' } })
}

