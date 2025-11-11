-- Create transcripts table for storing Deepgram transcription results
-- Run this in the Supabase SQL Editor

create table if not exists public.transcripts (
  id uuid primary key default gen_random_uuid(),
  recording_id uuid not null references public.recordings(id) on delete cascade,
  text text not null,
  created_at timestamptz not null default now()
);

alter table public.transcripts enable row level security;

drop policy if exists tr_sel on public.transcripts;
create policy tr_sel on public.transcripts
for select to authenticated
using (exists(select 1 from public.recordings r where r.id=recording_id and r.user_id=auth.uid()));

drop policy if exists tr_ins on public.transcripts;
create policy tr_ins on public.transcripts
for insert to authenticated
with check (exists(select 1 from public.recordings r where r.id=recording_id and r.user_id=auth.uid()));
