-- =========================================================================
-- HOODLY PROTOTYPE DATABASE SCHEMA
-- Execute this script in the Supabase Dashboard SQL Editor.
-- =========================================================================

-- Enable UUID extension if not enabled
create extension if not exists "uuid-ossp";

-- ── 1. PROFILES TABLE ────────────────────────────────────────────────────
create table if not exists public.profiles (
  id uuid references auth.users on delete cascade primary key,
  name text not null,
  email text not null,
  role text not null default 'user' check (role in ('user', 'business_owner')),
  phone text,
  avatar_url text,
  created_at timestamptz not null default now()
);

-- Enable RLS for profiles
alter table public.profiles enable row level security;

-- Policies for profiles
create policy "Allow read access to profiles for authenticated users"
  on public.profiles for select
  to authenticated
  using (true);

create policy "Allow users to insert their own profile"
  on public.profiles for insert
  to authenticated
  with check (auth.uid() = id);

create policy "Allow users to update their own profile"
  on public.profiles for update
  to authenticated
  using (auth.uid() = id)
  with check (auth.uid() = id);

-- Trigger to sync profiles when auth.users is created
create or replace function public.handle_new_user()
returns trigger as $$
begin
  insert into public.profiles (id, name, email, role)
  values (
    new.id,
    coalesce(new.raw_user_meta_data->>'name', new.raw_user_meta_data->>'full_name', 'New User'),
    new.email,
    coalesce(new.raw_user_meta_data->>'role', 'user')
  )
  on conflict (id) do nothing;
  return new;
end;
$$ language plpgsql security definer;

-- Recreate trigger (drop first if exists)
drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();

-- ── 2. CATEGORIES TABLE ──────────────────────────────────────────────────
create table if not exists public.categories (
  id uuid primary key default gen_random_uuid(),
  name text not null unique,
  created_at timestamptz not null default now()
);

-- Enable RLS for categories
alter table public.categories enable row level security;

create policy "Allow read access to categories for authenticated users"
  on public.categories for select
  to authenticated
  using (true);

-- Seed initial categories
insert into public.categories (name) values
  ('Food'),
  ('Restaurant'),
  ('Café'),
  ('Bakery'),
  ('Shopping'),
  ('Clothing'),
  ('Services'),
  ('Home Business'),
  ('Beauty'),
  ('Electronics'),
  ('Hangout'),
  ('Other')
on conflict (name) do nothing;

-- ── 3. BUSINESSES TABLE ──────────────────────────────────────────────────
create table if not exists public.businesses (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid references public.profiles(id) on delete cascade not null,
  name text not null,
  category_id uuid references public.categories(id) on delete set null,
  description text not null,
  phone text,
  website text, -- Added to support the website field in the UI
  address text not null,
  latitude double precision not null,
  longitude double precision not null,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Enable RLS for businesses
alter table public.businesses enable row level security;

-- Policies for businesses
create policy "Allow read access to active businesses for authenticated users"
  on public.businesses for select
  to authenticated
  using (is_active = true or auth.uid() = owner_id);

create policy "Allow business owners to create businesses"
  on public.businesses for insert
  to authenticated
  with check (auth.uid() = owner_id);

create policy "Allow business owners to update their own businesses"
  on public.businesses for update
  to authenticated
  using (auth.uid() = owner_id)
  with check (auth.uid() = owner_id);

create policy "Allow business owners to delete/deactivate their own businesses"
  on public.businesses for delete
  to authenticated
  using (auth.uid() = owner_id);

-- ── 4. BUSINESS IMAGES TABLE ─────────────────────────────────────────────
create table if not exists public.business_images (
  id uuid primary key default gen_random_uuid(),
  business_id uuid references public.businesses(id) on delete cascade not null,
  image_url text not null,
  created_at timestamptz not null default now()
);

-- Enable RLS for business images
alter table public.business_images enable row level security;

-- Policies for business images
create policy "Allow read access to business images for authenticated users"
  on public.business_images for select
  to authenticated
  using (true);

create policy "Allow owners to insert images for their businesses"
  on public.business_images for insert
  to authenticated
  with check (
    exists (
      select 1 from public.businesses
      where id = business_id and owner_id = auth.uid()
    )
  );

create policy "Allow owners to delete images of their businesses"
  on public.business_images for delete
  to authenticated
  using (
    exists (
      select 1 from public.businesses
      where id = business_id and owner_id = auth.uid()
    )
  );

-- ── 5. STORAGE BUCKET POLICIES ──────────────────────────────────────────
-- Note: Make sure to create the 'business-images' bucket in the Supabase Dashboard
-- and set its access level to PUBLIC. The policies below enable uploads/deletes.

-- Allow public access to read images from the business-images bucket
create policy "Allow public access to business images"
  on storage.objects for select
  to authenticated
  using (bucket_id = 'business-images');

-- Allow authenticated users to upload images to the business-images bucket
create policy "Allow authenticated users to upload business images"
  on storage.objects for insert
  to authenticated
  with check (bucket_id = 'business-images');

-- Allow users to delete their uploaded images
create policy "Allow users to delete their own business images"
  on storage.objects for delete
  to authenticated
  using (bucket_id = 'business-images' and auth.uid()::text = owner);

-- ── 6. COMMUNITY SERVICES (POSTS & CATEGORIES) ──────────────────────────
create table if not exists public.community_service_categories (
  id uuid primary key default gen_random_uuid(),
  name text not null unique,
  created_at timestamptz not null default now()
);

alter table public.community_service_categories enable row level security;

create policy "Allow read access to community categories"
  on public.community_service_categories for select
  to authenticated
  using (true);

insert into public.community_service_categories (name) values
  ('Tutoring'),
  ('Babysitting'),
  ('Plumbing'),
  ('Electrical'),
  ('Cleaning'),
  ('Pet Care'),
  ('Cooking'),
  ('Music & Arts'),
  ('Gardening'),
  ('Delivery'),
  ('Repairs'),
  ('Other')
on conflict (name) do nothing;

create table if not exists public.community_posts (
  id uuid primary key default gen_random_uuid(),
  author_id uuid references auth.users(id) on delete cascade not null,
  author_name text default '',
  author_avatar_url text default '',
  title text not null,
  description text not null,
  category text default 'General',
  category_id uuid references public.community_service_categories(id) on delete set null,
  post_type text not null check (post_type in ('offering', 'requesting')),
  fee_payment text not null default 'Free',
  contact_method text not null default 'both' check (contact_method in ('both', 'phone', 'email')),
  contact_phone text default '',
  contact_email text default '',
  address text not null default '',
  latitude double precision not null default 0.0,
  longitude double precision not null default 0.0,
  photo_urls text[] not null default '{}',
  status text not null default 'active' check (status in ('active', 'closed', 'expired', 'draft')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.community_posts enable row level security;

create policy "Allow read access to community posts"
  on public.community_posts for select
  to authenticated
  using (true);

create policy "Allow authenticated users to create community posts"
  on public.community_posts for insert
  to authenticated
  with check (auth.uid() = author_id);

create policy "Allow authors to update their own community posts"
  on public.community_posts for update
  to authenticated
  using (auth.uid() = author_id)
  with check (auth.uid() = author_id);

create policy "Allow authors to delete their own community posts"
  on public.community_posts for delete
  to authenticated
  using (auth.uid() = author_id);

