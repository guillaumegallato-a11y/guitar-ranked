-- Guitar Ranked V5 — textes du site modifiables depuis l'admin
create table if not exists public.site_content (
  id text primary key,
  value text not null default '',
  updated_at timestamptz not null default now()
);

alter table public.site_content enable row level security;
drop policy if exists "Public can read site content" on public.site_content;
create policy "Public can read site content" on public.site_content for select using (true);
drop policy if exists "Authenticated admins can insert site content" on public.site_content;
create policy "Authenticated admins can insert site content" on public.site_content for insert to authenticated with check (true);
drop policy if exists "Authenticated admins can update site content" on public.site_content;
create policy "Authenticated admins can update site content" on public.site_content for update to authenticated using (true) with check (true);

insert into public.site_content (id,value) values
('home_title','APPRENDS. PROGRESSE. MONTE EN RANK.'),
('home_intro','Guitar Ranked est né des morceaux avec lesquels j’ai grandi et appris la guitare. Ce sont eux qui m’ont donné envie de jouer, de travailler et de progresser.'),
('home_concept','J’ai classé ces morceaux par ordre de difficulté et transformé le parcours en jeu : commence en Bronze, franchis les ranks Argent, Or, Platine et Diamant, puis tente d’atteindre Guitar Hero.'),
('home_help','Choisis ton niveau, sélectionne un morceau, regarde la vidéo et utilise la tablature pour le travailler à ton rythme.'),
('ranking_title','CLASSEMENT DES MORCEAUX'),
('ranking_subtitle','Progresse morceau après morceau, du Bronze jusqu’à Guitar Hero.'),
('tabs_title','TABLATURES'),
('tabs_intro','Retrouve ici toutes les tablatures disponibles et choisis directement le morceau que tu veux travailler.')
on conflict (id) do nothing;
