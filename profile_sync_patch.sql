-- =========================================================================
-- HOODLY — PROFILE SYNC PATCH
-- Run this script in the Supabase Dashboard → SQL Editor.
-- Safe to run multiple times (idempotent).
-- =========================================================================

-- ── 1. Allow authenticated users to UPDATE (replace) their own storage objects
--       This is needed for avatar upserts (overwriting the same avatar file).
--       Skip if the policy already exists.
do $$
begin
  if not exists (
    select 1 from pg_policies
    where schemaname = 'storage'
      and tablename  = 'objects'
      and policyname = 'Allow users to update their own uploads'
  ) then
    execute $pol$
      create policy "Allow users to update their own uploads"
        on storage.objects for update
        to authenticated
        using (bucket_id = 'business-images' and auth.uid()::text = owner);
    $pol$;
  end if;
end $$;

-- ── 2. Ensure profiles.avatar_url column exists (no-op if it already does)
alter table public.profiles
  add column if not exists avatar_url text;

-- ── 3. Ensure community_posts has a foreign-key-compatible author_id column
--       that Supabase PostgREST can use to JOIN profiles via the FK relationship.
--       The FK from community_posts.author_id → auth.users.id already exists.
--       PostgREST discovers FK relationships automatically; no extra SQL needed.

-- ── 4. (Optional) Back-fill author_name on existing posts from profiles
--       so the old stale values are overwritten with current names.
--       Community posts going forward will always JOIN live from profiles,
--       but this cleans up any data displayed via the stale columns.
update public.community_posts cp
set
  author_name       = p.name,
  author_avatar_url = coalesce(p.avatar_url, '')
from public.profiles p
where cp.author_id = p.id;
