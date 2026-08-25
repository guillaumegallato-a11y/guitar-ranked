-- Guitar Ranked — Supabase setup
-- 1) Exécute ce fichier dans Supabase > SQL Editor.
-- 2) Crée un utilisateur admin dans Authentication > Users.
-- 3) Ajoute les variables VITE_SUPABASE_URL et VITE_SUPABASE_ANON_KEY dans Vercel.

create extension if not exists pgcrypto;

create table if not exists public.songs (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  artist text default '',
  level text not null,
  youtube text default '',
  description text default '',
  tab_name text default '',
  tab_url text default '',
  tab_type text default '',
  created_at timestamptz not null default now()
);

alter table public.songs enable row level security;

drop policy if exists "Public can read songs" on public.songs;
create policy "Public can read songs"
  on public.songs for select
  using (true);

drop policy if exists "Authenticated admins can insert songs" on public.songs;
create policy "Authenticated admins can insert songs"
  on public.songs for insert
  to authenticated
  with check (true);

drop policy if exists "Authenticated admins can update songs" on public.songs;
create policy "Authenticated admins can update songs"
  on public.songs for update
  to authenticated
  using (true)
  with check (true);

drop policy if exists "Authenticated admins can delete songs" on public.songs;
create policy "Authenticated admins can delete songs"
  on public.songs for delete
  to authenticated
  using (true);

insert into storage.buckets (id, name, public)
values ('tabs', 'tabs', true)
on conflict (id) do update set public = true;

drop policy if exists "Public can read tabs" on storage.objects;
create policy "Public can read tabs"
  on storage.objects for select
  using (bucket_id = 'tabs');

drop policy if exists "Authenticated admins can upload tabs" on storage.objects;
create policy "Authenticated admins can upload tabs"
  on storage.objects for insert
  to authenticated
  with check (bucket_id = 'tabs');

drop policy if exists "Authenticated admins can update tabs" on storage.objects;
create policy "Authenticated admins can update tabs"
  on storage.objects for update
  to authenticated
  using (bucket_id = 'tabs')
  with check (bucket_id = 'tabs');

drop policy if exists "Authenticated admins can delete tabs" on storage.objects;
create policy "Authenticated admins can delete tabs"
  on storage.objects for delete
  to authenticated
  using (bucket_id = 'tabs');
