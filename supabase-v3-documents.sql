-- Guitar Ranked V3 — documents illimités par morceau
-- À exécuter UNE FOIS dans Supabase > SQL Editor avant d'utiliser la V3.
-- Ce script conserve les morceaux existants et migre l'ancienne tablature unique vers la nouvelle liste de documents.

alter table public.songs
  add column if not exists documents jsonb not null default '[]'::jsonb;

-- Migre automatiquement l'ancienne tablature unique, si elle existe, uniquement quand documents est encore vide.
do $$
begin
  if exists (
    select 1 from information_schema.columns
    where table_schema = 'public' and table_name = 'songs' and column_name = 'tab_url'
  ) then
    execute $sql$
      update public.songs
      set documents = jsonb_build_array(
        jsonb_build_object(
          'id', 'legacy-' || id::text,
          'name', coalesce(nullif(tab_name,''), 'Tablature'),
          'url', tab_url,
          'type', coalesce(tab_type,''),
          'path', ''
        )
      )
      where coalesce(documents, '[]'::jsonb) = '[]'::jsonb
        and coalesce(tab_url,'') <> ''
    $sql$;
  end if;
end $$;

alter table public.songs enable row level security;

drop policy if exists "Public can read songs" on public.songs;
create policy "Public can read songs" on public.songs for select using (true);

drop policy if exists "Authenticated admins can insert songs" on public.songs;
create policy "Authenticated admins can insert songs" on public.songs for insert to authenticated with check (true);

drop policy if exists "Authenticated admins can update songs" on public.songs;
create policy "Authenticated admins can update songs" on public.songs for update to authenticated using (true) with check (true);

drop policy if exists "Authenticated admins can delete songs" on public.songs;
create policy "Authenticated admins can delete songs" on public.songs for delete to authenticated using (true);

insert into storage.buckets (id, name, public)
values ('tabs', 'tabs', true)
on conflict (id) do update set public = true;

drop policy if exists "Public can read tabs" on storage.objects;
create policy "Public can read tabs" on storage.objects for select using (bucket_id = 'tabs');

drop policy if exists "Authenticated admins can upload tabs" on storage.objects;
create policy "Authenticated admins can upload tabs" on storage.objects for insert to authenticated with check (bucket_id = 'tabs');

drop policy if exists "Authenticated admins can update tabs" on storage.objects;
create policy "Authenticated admins can update tabs" on storage.objects for update to authenticated using (bucket_id = 'tabs') with check (bucket_id = 'tabs');

drop policy if exists "Authenticated admins can delete tabs" on storage.objects;
create policy "Authenticated admins can delete tabs" on storage.objects for delete to authenticated using (bucket_id = 'tabs');
