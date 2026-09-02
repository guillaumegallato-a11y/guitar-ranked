-- Guitar Ranked V5.4 — commentaires avec compte, réponses, likes et suppression par auteur
-- À exécuter UNE FOIS dans Supabase > SQL Editor après le déploiement de la V5.4.

-- Lie chaque nouveau commentaire à son compte. Les anciens commentaires anonymes restent visibles.
alter table public.song_comments
  add column if not exists user_id uuid references auth.users(id) on delete set null,
  add column if not exists parent_id uuid references public.song_comments(id) on delete cascade;

create index if not exists song_comments_parent_id_idx on public.song_comments(parent_id);
create index if not exists song_comments_user_id_idx on public.song_comments(user_id);

-- Le pseudo affiché est toujours celui du profil connecté : le navigateur ne peut pas en inventer un.
create or replace function public.prepare_song_comment()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_username text;
begin
  if auth.uid() is null then
    raise exception 'Connexion requise pour commenter';
  end if;

  new.user_id := auth.uid();
  select p.username into v_username from public.profiles p where p.id = auth.uid();
  new.author_name := coalesce(nullif(v_username,''), 'Guitariste');

  -- Une réponse doit viser un commentaire principal du même morceau.
  if new.parent_id is not null then
    if not exists(
      select 1 from public.song_comments c
      where c.id = new.parent_id and c.song_id = new.song_id and c.parent_id is null
    ) then
      raise exception 'Commentaire parent invalide';
    end if;
  end if;

  return new;
end;
$$;

drop trigger if exists prepare_song_comment_trigger on public.song_comments;
create trigger prepare_song_comment_trigger
before insert on public.song_comments
for each row execute procedure public.prepare_song_comment();

-- Plus aucun commentaire anonyme : lecture publique, écriture uniquement avec un compte.
alter table public.song_comments enable row level security;
drop policy if exists "Public can add song comments" on public.song_comments;
drop policy if exists "Authenticated users add song comments" on public.song_comments;
drop policy if exists "Users delete own song comments" on public.song_comments;
drop policy if exists "Admins delete song comments" on public.song_comments;
create policy "Authenticated users add song comments"
  on public.song_comments for insert to authenticated
  with check (user_id = auth.uid());
create policy "Users delete own song comments"
  on public.song_comments for delete to authenticated
  using (user_id = auth.uid());
create policy "Admins delete song comments"
  on public.song_comments for delete to authenticated
  using (exists(select 1 from public.profiles p where p.id=auth.uid() and p.role='admin'));

-- Likes : un utilisateur ne peut liker qu'une fois un commentaire.
create table if not exists public.song_comment_likes (
  comment_id uuid not null references public.song_comments(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key(comment_id,user_id)
);

alter table public.song_comment_likes enable row level security;
drop policy if exists "Public read song comment likes" on public.song_comment_likes;
drop policy if exists "Users add own song comment likes" on public.song_comment_likes;
drop policy if exists "Users delete own song comment likes" on public.song_comment_likes;
create policy "Public read song comment likes" on public.song_comment_likes for select using (true);
create policy "Users add own song comment likes" on public.song_comment_likes for insert to authenticated with check (user_id=auth.uid());
create policy "Users delete own song comment likes" on public.song_comment_likes for delete to authenticated using (user_id=auth.uid());

notify pgrst, 'reload schema';
