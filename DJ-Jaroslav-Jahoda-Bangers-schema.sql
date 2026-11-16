-- DJ Jaroslav Jahoda Bangers — databáze + veřejná hudební knihovna
-- Spusť celý soubor v Supabase Dashboard > SQL Editor.

create extension if not exists pgcrypto;

create table if not exists public.tracks (
  id uuid primary key default gen_random_uuid(),
  title text not null check (char_length(title) between 1 and 120),
  artist text not null check (char_length(artist) between 1 and 120),
  storage_path text not null unique,
  created_at timestamptz not null default now()
);

alter table public.tracks enable row level security;

drop policy if exists "Anyone can read tracks" on public.tracks;
create policy "Anyone can read tracks"
  on public.tracks for select
  to anon, authenticated
  using (true);

grant select on public.tracks to anon, authenticated;

-- Veřejné čtení souborů kvůli přehrávání; nahrávání nových souborů
-- je povoleno jen přes Edge Function, která vydává jednorázový upload token.
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'tracks',
  'tracks',
  true,
  52428800,
  array[
    'audio/mpeg', 'audio/mp3', 'audio/wav', 'audio/x-wav', 'audio/wave',
    'audio/mp4', 'audio/aac', 'audio/ogg', 'application/ogg',
    'audio/opus', 'audio/flac', 'audio/x-flac', 'application/octet-stream'
  ]::text[]
)
on conflict (id) do update set
  public = excluded.public,
  file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;
