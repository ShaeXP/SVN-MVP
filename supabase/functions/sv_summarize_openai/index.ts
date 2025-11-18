// supabase/functions/sv_summarize_openai/index.ts
import 'jsr:@supabase/functions-js/edge-runtime.d.ts'
import { createClient } from 'jsr:@supabase/supabase-js@2'

const cors = {
  'access-control-allow-origin': '*',
  'access-control-allow-headers': 'authorization, x-client-info, apikey, content-type, x-trace-id, x-path',
}

type SummJson = {
  title: string
  summary: string
  bullets: string[]
  actionItems: string[]
  tags: string[]
  confidence: number
}

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: cors })

  const exec = Deno.env.get('SB_EXECUTION_ID') ?? null
  const trace = req.headers.get('x-trace-id') ?? `${Date.now().toString(36)}-${Math.random().toString(36).slice(2,7)}`
  const pathOverride = req.headers.get('x-path')

  // Healthcheck (visible in Functions → Invocations)
  if (req.method === 'GET' || pathOverride === '/health') {
    console.log('[sv_summarize_openai] health', { exec, trace })
    return json({ ok: true, exec, trace })
  }

  try {
    // Auth-context supabase (user JWT is forwarded from client)
    const supabase = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_ANON_KEY')!,
      { global: { headers: { Authorization: req.headers.get('Authorization') ?? '' } } }
    )

    const { data: { user }, error: authErr } = await supabase.auth.getUser()
    if (authErr || !user) return json({ ok:false, code:'unauthorized', message:'No user' }, 401)

    const body = await req.json().catch(() => ({}))
    const recId = String(body?.recordingId ?? '').trim()
    const summaryStyle = String(body?.summary_style ?? body?.summaryStyle ?? 'quick_recap')
    if (!recId || !/^[0-9a-fA-F-]{36}$/.test(recId)) return json({ ok:false, code:'bad_request', message:'recordingId required (uuid)' }, 400)

    console.log('[sv_summarize_openai] start', { recId, userId: user.id, trace })

    // Ownership check
    const { data: rec, error: recErr } = await supabase
      .from('recordings')
      .select('id,user_id')
      .eq('id', recId)
      .eq('user_id', user.id)
      .maybeSingle()
    if (recErr || !rec) return json({ ok:false, code:'not_found', message:'recording not found' }, 404)

    // Transcript lookup by recording_id (not transcript_id)
    const { data: tx, error: txErr } = await supabase
      .from('transcripts')
      .select('text')
      .eq('recording_id', recId)
      .maybeSingle()
    if (txErr || !tx?.text) return json({ ok:false, code:'no_transcript', message:'no transcript' }, 422)

    const transcript = tx.text.trim()
    // Short-circuit: empty transcript
    if (!transcript) return json({ ok:false, code:'empty_transcript', message:'empty transcript' }, 422)

    // Summarize with chunking if long
    const model = Deno.env.get('SUMMARY_MODEL') ?? 'gpt-4o-mini'
    const openaiKey = Deno.env.get('OPENAI_API_KEY')!
    const maxChars = 12000 // safety: rough guard; adjust as needed
    let result: SummJson

    if (transcript.length <= maxChars) {
      result = await llmSummarize(openaiKey, model, transcript, summaryStyle, trace)
    } else {
      // Map-reduce: chunk → partials → merge
      const chunks = splitTranscript(transcript, 3500) // soft chunk size
      const partials: SummJson[] = []
      for (const ch of chunks) {
        partials.push(await llmSummarize(openaiKey, model, ch, summaryStyle, trace))
      }
      const merged = await llmMerge(openaiKey, model, partials, trace)
      result = merged
    }

    // Upsert summary (summaries table has no user_id, security via RLS)
    const { data: up, error: upErr } = await supabase
      .from('summaries')
      .upsert({
        recording_id: recId,
        title: result.title ?? '',
        summary: result.summary ?? '',
        bullets: result.bullets ?? [],
        action_items: result.actionItems ?? [],
        tags: result.tags ?? [],
        confidence: result.confidence ?? 0.0,
        summary_style: summaryStyle,
      }, { onConflict: 'recording_id' })
      .select()
      .maybeSingle()
    
    if (upErr) {
      console.error('[sv_summarize_openai] upsert_failed', { trace, error: upErr })
      return json({ ok:false, code:'upsert_failed', message: String(upErr), trace }, 500)
    }
    
    // Update recording status to ready (completed with summary)
    await supabase.from('recordings').update({ 
      status: 'ready',
      status_changed_at: new Date().toISOString()
    }).eq('id', recId).eq('user_id', user.id)

    console.log('[sv_summarize_openai] ok', { recId, trace })
    return json({ ok: true, trace, summaryId: up?.id ?? null })
  } catch (e) {
    console.error('[sv_summarize_openai] error', { trace, msg: String(e) })
    return json({ ok:false, code:'unhandled', message:String(e), trace }, 500)
  }
})

// ---------- helpers ----------
function json(data: unknown, status = 200) {
  return new Response(JSON.stringify(data), { status, headers: { ...cors, 'content-type':'application/json' } })
}

function splitTranscript(s: string, size: number) {
  const out: string[] = []
  for (let i = 0; i < s.length; i += size) out.push(s.slice(i, i + size))
  return out
}

function styleInstruction(key: string): string {
  switch (key) {
    case 'organized_by_topic':
      return 'Group bullets by topic sections (Agenda & Context, Main Discussion, Decisions, Risks/Concerns). Keep the same JSON keys.'
    case 'decisions_next_steps':
      return 'Start with a one-sentence TL;DR, enumerate Decisions, Next steps (actionItems), and Open questions within bullets. Keep the same JSON keys.'
    case 'quick_recap':
    default:
      return 'Short summary, crisp bullets, and clear actionItems. Keep JSON tight.'
  }
}

async function llmSummarize(key: string, model: string, text: string, summaryStyle: string, trace: string): Promise<SummJson> {
  const system = `You are a surgical editor for meeting/voice notes. Return STRICT JSON only with keys:
- title: short, informative
- summary: 3–6 sentences max
- bullets: 4–8 crisp bullets of key points
- actionItems: concrete next steps with verbs
- tags: 3–6 topical tags (lowercase)
- confidence: number 0.0–1.0 based on transcript clarity and decisiveness
No prose outside JSON.`
  const user = `TRANSCRIPT:\n${text}\n\nSTYLE: ${styleInstruction(summaryStyle)}\nReturn JSON only.`
  const resp = await fetch('https://api.openai.com/v1/chat/completions', {
    method:'POST',
    headers:{ 'Content-Type':'application/json', 'Authorization':`Bearer ${key}` },
    body: JSON.stringify({
      model,
      temperature: 0.2,
      response_format: { type: 'json_object' },
      messages: [
        { role: 'system', content: system },
        { role: 'user', content: user },
      ]
    })
  })
  if (!resp.ok) throw new Error(`llmSummarize failed: ${await resp.text()}`)
  const data = await resp.json()
  const content = data.choices?.[0]?.message?.content ?? '{}'
  return safeParse(content)
}

async function llmMerge(key: string, model: string, parts: SummJson[], trace: string): Promise<SummJson> {
  const system = `You merge multiple partial summaries into one FINAL JSON. Keep it tight and non-redundant. Same schema as before.`
  const user = `PARTIALS (JSON array):\n${JSON.stringify(parts)}\n\nReturn merged JSON only.`
  const resp = await fetch('https://api.openai.com/v1/chat/completions', {
    method:'POST',
    headers:{ 'Content-Type':'application/json', 'Authorization':`Bearer ${key}` },
    body: JSON.stringify({
      model,
      temperature: 0.2,
      response_format: { type: 'json_object' },
      messages: [
        { role: 'system', content: system },
        { role: 'user', content: user },
      ]
    })
  })
  if (!resp.ok) throw new Error(`llmMerge failed: ${await resp.text()}`)
  const data = await resp.json()
  const content = data.choices?.[0]?.message?.content ?? '{}'
  return safeParse(content)
}

function safeParse(s: string): SummJson {
  try { return JSON.parse(s) } catch { return { title:'', summary:'', bullets:[], actionItems:[], tags:[], confidence:0 } }
}
