-- Guitar Ranked V5.2 — commentaires + FAQ / communauté
-- À exécuter UNE FOIS dans Supabase > SQL Editor.

create table if not exists public.song_comments (
  id uuid primary key default gen_random_uuid(),
  song_id uuid not null references public.songs(id) on delete cascade,
  author_name text not null check (char_length(author_name) between 1 and 60),
  message text not null check (char_length(message) between 1 and 1500),
  created_at timestamptz not null default now()
);

create index if not exists song_comments_song_id_created_at_idx
  on public.song_comments(song_id, created_at);

alter table public.song_comments enable row level security;
drop policy if exists "Public can read song comments" on public.song_comments;
drop policy if exists "Public can add song comments" on public.song_comments;
drop policy if exists "Authenticated admins can delete song comments" on public.song_comments;
create policy "Public can read song comments" on public.song_comments for select using (true);
create policy "Public can add song comments" on public.song_comments for insert with check (true);
create policy "Authenticated admins can delete song comments" on public.song_comments for delete to authenticated using (true);

create table if not exists public.faq_topics (
  id uuid primary key default gen_random_uuid(),
  author_name text not null check (char_length(author_name) between 1 and 60),
  question text not null check (char_length(question) between 1 and 1200),
  created_at timestamptz not null default now()
);

alter table public.faq_topics enable row level security;
drop policy if exists "Public can read faq topics" on public.faq_topics;
drop policy if exists "Public can add faq topics" on public.faq_topics;
drop policy if exists "Authenticated admins can delete faq topics" on public.faq_topics;
create policy "Public can read faq topics" on public.faq_topics for select using (true);
create policy "Public can add faq topics" on public.faq_topics for insert with check (true);
create policy "Authenticated admins can delete faq topics" on public.faq_topics for delete to authenticated using (true);

create table if not exists public.faq_replies (
  id uuid primary key default gen_random_uuid(),
  topic_id uuid not null references public.faq_topics(id) on delete cascade,
  author_name text not null check (char_length(author_name) between 1 and 60),
  message text not null check (char_length(message) between 1 and 1500),
  created_at timestamptz not null default now()
);

create index if not exists faq_replies_topic_id_created_at_idx
  on public.faq_replies(topic_id, created_at);

alter table public.faq_replies enable row level security;
drop policy if exists "Public can read faq replies" on public.faq_replies;
drop policy if exists "Public can add faq replies" on public.faq_replies;
drop policy if exists "Authenticated admins can delete faq replies" on public.faq_replies;
create policy "Public can read faq replies" on public.faq_replies for select using (true);
create policy "Public can add faq replies" on public.faq_replies for insert with check (true);
create policy "Authenticated admins can delete faq replies" on public.faq_replies for delete to authenticated using (true);

-- Ajoute les textes de la FAQ à l’éditeur admin si la table site_content existe.
insert into public.site_content (id,value) values
  ('faq_title','FAQ · LE COIN DES MUSICIENS'),
  ('faq_intro','Pose tes questions, partage tes astuces et échange avec les autres guitaristes.')
on conflict (id) do nothing;

-- Renomme l’ancien titre par défaut, sans écraser une éventuelle personnalisation.
update public.site_content
set value='PARTIE RAPIDE', updated_at=now()
where id='tabs_title' and value='TABLATURES';

notify pgrst, 'reload schema';
