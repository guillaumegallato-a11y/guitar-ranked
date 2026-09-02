-- Guitar Ranked V5.4.1 — FAQ liée aux comptes, réponses directes, likes et suppression par auteur
-- À exécuter UNE FOIS dans Supabase > SQL Editor après le déploiement de la V5.4.1.

alter table public.faq_topics
  add column if not exists user_id uuid references auth.users(id) on delete set null;

alter table public.faq_replies
  add column if not exists user_id uuid references auth.users(id) on delete set null,
  add column if not exists parent_id uuid references public.faq_replies(id) on delete cascade;

create index if not exists faq_topics_user_id_idx on public.faq_topics(user_id);
create index if not exists faq_replies_user_id_idx on public.faq_replies(user_id);
create index if not exists faq_replies_parent_id_idx on public.faq_replies(parent_id);

create or replace function public.prepare_faq_topic()
returns trigger language plpgsql security definer set search_path=public as $$
declare v_username text;
begin
  if auth.uid() is null then raise exception 'Connexion requise pour publier dans la FAQ'; end if;
  new.user_id:=auth.uid();
  select p.username into v_username from public.profiles p where p.id=auth.uid();
  new.author_name:=coalesce(nullif(v_username,''),'Guitariste');
  return new;
end; $$;

drop trigger if exists prepare_faq_topic_trigger on public.faq_topics;
create trigger prepare_faq_topic_trigger before insert on public.faq_topics
for each row execute procedure public.prepare_faq_topic();

create or replace function public.prepare_faq_reply()
returns trigger language plpgsql security definer set search_path=public as $$
declare v_username text;
begin
  if auth.uid() is null then raise exception 'Connexion requise pour répondre dans la FAQ'; end if;
  new.user_id:=auth.uid();
  select p.username into v_username from public.profiles p where p.id=auth.uid();
  new.author_name:=coalesce(nullif(v_username,''),'Guitariste');
  if new.parent_id is not null and not exists(
    select 1 from public.faq_replies r where r.id=new.parent_id and r.topic_id=new.topic_id
  ) then raise exception 'Réponse parente invalide'; end if;
  return new;
end; $$;

drop trigger if exists prepare_faq_reply_trigger on public.faq_replies;
create trigger prepare_faq_reply_trigger before insert on public.faq_replies
for each row execute procedure public.prepare_faq_reply();

alter table public.faq_topics enable row level security;
drop policy if exists "Public can add faq topics" on public.faq_topics;
drop policy if exists "Authenticated admins can delete faq topics" on public.faq_topics;
drop policy if exists "Public can read faq topics" on public.faq_topics;
drop policy if exists "Users add faq topics" on public.faq_topics;
drop policy if exists "Users delete own faq topics" on public.faq_topics;
drop policy if exists "Admins delete faq topics" on public.faq_topics;
create policy "Public can read faq topics" on public.faq_topics for select using(true);
create policy "Users add faq topics" on public.faq_topics for insert to authenticated with check(user_id=auth.uid());
create policy "Users delete own faq topics" on public.faq_topics for delete to authenticated using(user_id=auth.uid());
create policy "Admins delete faq topics" on public.faq_topics for delete to authenticated using(exists(select 1 from public.profiles p where p.id=auth.uid() and p.role='admin'));

alter table public.faq_replies enable row level security;
drop policy if exists "Public can add faq replies" on public.faq_replies;
drop policy if exists "Authenticated admins can delete faq replies" on public.faq_replies;
drop policy if exists "Public can read faq replies" on public.faq_replies;
drop policy if exists "Users add faq replies" on public.faq_replies;
drop policy if exists "Users delete own faq replies" on public.faq_replies;
drop policy if exists "Admins delete faq replies" on public.faq_replies;
create policy "Public can read faq replies" on public.faq_replies for select using(true);
create policy "Users add faq replies" on public.faq_replies for insert to authenticated with check(user_id=auth.uid());
create policy "Users delete own faq replies" on public.faq_replies for delete to authenticated using(user_id=auth.uid());
create policy "Admins delete faq replies" on public.faq_replies for delete to authenticated using(exists(select 1 from public.profiles p where p.id=auth.uid() and p.role='admin'));

create table if not exists public.faq_topic_likes(
  topic_id uuid not null references public.faq_topics(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key(topic_id,user_id)
);
alter table public.faq_topic_likes enable row level security;
create policy "Public read faq topic likes" on public.faq_topic_likes for select using(true);
create policy "Users add own faq topic likes" on public.faq_topic_likes for insert to authenticated with check(user_id=auth.uid());
create policy "Users delete own faq topic likes" on public.faq_topic_likes for delete to authenticated using(user_id=auth.uid());

create table if not exists public.faq_reply_likes(
  reply_id uuid not null references public.faq_replies(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key(reply_id,user_id)
);
alter table public.faq_reply_likes enable row level security;
create policy "Public read faq reply likes" on public.faq_reply_likes for select using(true);
create policy "Users add own faq reply likes" on public.faq_reply_likes for insert to authenticated with check(user_id=auth.uid());
create policy "Users delete own faq reply likes" on public.faq_reply_likes for delete to authenticated using(user_id=auth.uid());

insert into public.site_content(id,value) values
('dev_notice','🚧 Guitar Ranked est encore en développement : de nombreux morceaux et de nouvelles fonctionnalités arrivent bientôt !')
on conflict(id) do nothing;

notify pgrst, 'reload schema';
