-- Guitar Ranked V5.3 — comptes joueurs, progression dynamique, boss, métadonnées et modération
-- À exécuter UNE FOIS dans Supabase > SQL Editor après avoir déployé la V5.3.

-- 1) Métadonnées des morceaux
alter table public.songs add column if not exists technique text not null default '';
alter table public.songs add column if not exists tuning text not null default '';
alter table public.songs add column if not exists bpm integer;
alter table public.songs add column if not exists is_boss boolean not null default false;

-- 2) Profils utilisateurs
create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  username text not null default 'Guitariste' check (char_length(username) between 1 and 40),
  role text not null default 'user' check (role in ('user','admin')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Le premier compte Auth existant est considéré comme le compte admin historique du site.
insert into public.profiles(id,username,role)
select u.id,
       coalesce(nullif(u.raw_user_meta_data->>'username',''), split_part(coalesce(u.email,'admin'),'@',1), 'Admin'),
       'admin'
from auth.users u
where u.id = (select id from auth.users order by created_at asc limit 1)
on conflict (id) do update set role='admin';

-- Les autres comptes déjà existants deviennent des comptes joueurs.
insert into public.profiles(id,username,role)
select u.id,
       coalesce(nullif(u.raw_user_meta_data->>'username',''), split_part(coalesce(u.email,'guitariste'),'@',1), 'Guitariste'),
       'user'
from auth.users u
where not exists (select 1 from public.profiles p where p.id=u.id)
on conflict (id) do nothing;

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles(id,username,role)
  values(new.id, coalesce(nullif(new.raw_user_meta_data->>'username',''), split_part(coalesce(new.email,'guitariste'),'@',1), 'Guitariste'), 'user')
  on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
after insert on auth.users
for each row execute procedure public.handle_new_user();

-- Empêche un joueur de se promouvoir lui-même admin via l'API.
create or replace function public.protect_profile_role()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if tg_op='UPDATE' and new.role is distinct from old.role then
    if not exists(select 1 from public.profiles p where p.id=auth.uid() and p.role='admin') then
      new.role := old.role;
    end if;
  end if;
  if tg_op='INSERT' and new.role='admin' and not exists(select 1 from public.profiles p where p.id=auth.uid() and p.role='admin') then
    new.role := 'user';
  end if;
  return new;
end;
$$;

drop trigger if exists protect_profile_role_trigger on public.profiles;
create trigger protect_profile_role_trigger
before insert or update on public.profiles
for each row execute procedure public.protect_profile_role();

alter table public.profiles enable row level security;
drop policy if exists "Profiles public read" on public.profiles;
drop policy if exists "Users create own profile" on public.profiles;
drop policy if exists "Users update own profile" on public.profiles;
create policy "Profiles public read" on public.profiles for select using (true);
create policy "Users create own profile" on public.profiles for insert to authenticated with check (auth.uid()=id);
create policy "Users update own profile" on public.profiles for update to authenticated using (auth.uid()=id) with check (auth.uid()=id);

-- 3) Progression par morceau
create table if not exists public.song_progress (
  user_id uuid not null references auth.users(id) on delete cascade,
  song_id uuid not null references public.songs(id) on delete cascade,
  mastered boolean not null default true,
  updated_at timestamptz not null default now(),
  primary key(user_id,song_id)
);
alter table public.song_progress enable row level security;
drop policy if exists "Users read own progress" on public.song_progress;
drop policy if exists "Users add own progress" on public.song_progress;
drop policy if exists "Users update own progress" on public.song_progress;
drop policy if exists "Users delete own progress" on public.song_progress;
create policy "Users read own progress" on public.song_progress for select to authenticated using (auth.uid()=user_id);
create policy "Users add own progress" on public.song_progress for insert to authenticated with check (auth.uid()=user_id);
create policy "Users update own progress" on public.song_progress for update to authenticated using (auth.uid()=user_id) with check (auth.uid()=user_id);
create policy "Users delete own progress" on public.song_progress for delete to authenticated using (auth.uid()=user_id);

-- 4) Signalements communauté
create table if not exists public.community_reports (
  id uuid primary key default gen_random_uuid(),
  reporter_user_id uuid not null references auth.users(id) on delete cascade,
  entity_type text not null check(entity_type in ('song_comment','faq_topic','faq_reply')),
  entity_id text not null,
  reason text not null check(char_length(reason) between 1 and 500),
  created_at timestamptz not null default now()
);
alter table public.community_reports enable row level security;
drop policy if exists "Users create reports" on public.community_reports;
drop policy if exists "Admins read reports" on public.community_reports;
drop policy if exists "Admins delete reports" on public.community_reports;
create policy "Users create reports" on public.community_reports for insert to authenticated with check(auth.uid()=reporter_user_id);
create policy "Admins read reports" on public.community_reports for select to authenticated using(exists(select 1 from public.profiles p where p.id=auth.uid() and p.role='admin'));
create policy "Admins delete reports" on public.community_reports for delete to authenticated using(exists(select 1 from public.profiles p where p.id=auth.uid() and p.role='admin'));

-- 5) Sécurisation des écritures admin (important maintenant qu'il existe des comptes joueurs)
alter table public.songs enable row level security;
drop policy if exists "Authenticated admins can insert songs" on public.songs;
drop policy if exists "Authenticated admins can update songs" on public.songs;
drop policy if exists "Authenticated admins can delete songs" on public.songs;
create policy "Admins can insert songs" on public.songs for insert to authenticated with check(exists(select 1 from public.profiles p where p.id=auth.uid() and p.role='admin'));
create policy "Admins can update songs" on public.songs for update to authenticated using(exists(select 1 from public.profiles p where p.id=auth.uid() and p.role='admin')) with check(exists(select 1 from public.profiles p where p.id=auth.uid() and p.role='admin'));
create policy "Admins can delete songs" on public.songs for delete to authenticated using(exists(select 1 from public.profiles p where p.id=auth.uid() and p.role='admin'));

alter table public.site_content enable row level security;
drop policy if exists "Authenticated can insert site content" on public.site_content;
drop policy if exists "Authenticated can update site content" on public.site_content;
drop policy if exists "Authenticated admins can insert site content" on public.site_content;
drop policy if exists "Authenticated admins can update site content" on public.site_content;
create policy "Admins can insert site content" on public.site_content for insert to authenticated with check(exists(select 1 from public.profiles p where p.id=auth.uid() and p.role='admin'));
create policy "Admins can update site content" on public.site_content for update to authenticated using(exists(select 1 from public.profiles p where p.id=auth.uid() and p.role='admin')) with check(exists(select 1 from public.profiles p where p.id=auth.uid() and p.role='admin'));

-- Commentaires / FAQ : lecture et ajout restent publics, suppression réservée à l'admin.
drop policy if exists "Authenticated admins can delete song comments" on public.song_comments;
create policy "Admins delete song comments" on public.song_comments for delete to authenticated using(exists(select 1 from public.profiles p where p.id=auth.uid() and p.role='admin'));
drop policy if exists "Authenticated admins can delete faq topics" on public.faq_topics;
create policy "Admins delete faq topics" on public.faq_topics for delete to authenticated using(exists(select 1 from public.profiles p where p.id=auth.uid() and p.role='admin'));
drop policy if exists "Authenticated admins can delete faq replies" on public.faq_replies;
create policy "Admins delete faq replies" on public.faq_replies for delete to authenticated using(exists(select 1 from public.profiles p where p.id=auth.uid() and p.role='admin'));

-- Storage tabs : les joueurs ne peuvent pas modifier les tablatures.
drop policy if exists "Authenticated can upload tabs" on storage.objects;
drop policy if exists "Authenticated can update tabs" on storage.objects;
drop policy if exists "Authenticated can delete tabs" on storage.objects;
drop policy if exists "Authenticated admins can upload tabs" on storage.objects;
drop policy if exists "Authenticated admins can update tabs" on storage.objects;
drop policy if exists "Authenticated admins can delete tabs" on storage.objects;
create policy "Admins upload tabs" on storage.objects for insert to authenticated with check(bucket_id='tabs' and exists(select 1 from public.profiles p where p.id=auth.uid() and p.role='admin'));
create policy "Admins update tabs" on storage.objects for update to authenticated using(bucket_id='tabs' and exists(select 1 from public.profiles p where p.id=auth.uid() and p.role='admin')) with check(bucket_id='tabs' and exists(select 1 from public.profiles p where p.id=auth.uid() and p.role='admin'));
create policy "Admins delete tabs" on storage.objects for delete to authenticated using(bucket_id='tabs' and exists(select 1 from public.profiles p where p.id=auth.uid() and p.role='admin'));

notify pgrst, 'reload schema';
