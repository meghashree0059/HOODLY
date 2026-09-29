-- =========================================================================
-- HOODLY — STORAGE BUCKET & IMAGE POLICIES
-- Run this script in the Supabase Dashboard SQL Editor.
-- =========================================================================

-- ── 1. CREATE 'business-images' BUCKET ──────────────────────────────────
insert into storage.buckets (id, name, public)
values ('business-images', 'business-images', true)
on conflict (id) do update set public = true;

-- ── 2. CONFIGURE STORAGE POLICIES ────────────────────────────────────────
-- Enable RLS on storage.objects
alter table storage.objects enable row level security;

-- Drop previous policies to avoid duplicates
drop policy if exists "Allow public access to business images" on storage.objects;
drop policy if exists "Allow authenticated users to upload business images" on storage.objects;
drop policy if exists "Allow users to update their own uploads" on storage.objects;
drop policy if exists "Allow users to delete their own business images" on storage.objects;

-- Policy 1: Anyone (authenticated or guest) can view uploaded images
create policy "Allow public access to business images"
  on storage.objects for select
  using (bucket_id = 'business-images');

-- Policy 2: Authenticated users can upload photos
create policy "Allow authenticated users to upload business images"
  on storage.objects for insert
  to authenticated
  with check (bucket_id = 'business-images');

-- Policy 3: Authenticated users can update/replace photos
create policy "Allow users to update their own uploads"
  on storage.objects for update
  to authenticated
  using (bucket_id = 'business-images');

-- Policy 4: Authenticated users can delete photos
create policy "Allow users to delete their own business images"
  on storage.objects for delete
  to authenticated
  using (bucket_id = 'business-images');

-- ── 3. ENSURE avatar_url EXISTS ON PROFILES ─────────────────────────────
alter table public.profiles
  add column if not exists avatar_url text;
