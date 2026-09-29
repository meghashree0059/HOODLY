-- =========================================================================
-- HOODLY — COMMUNITY SERVICES SCHEMA EXTENSION
-- Run this script in the Supabase Dashboard SQL Editor.
-- =========================================================================

-- ── 1. COMMUNITY SERVICE CATEGORIES ──────────────────────────────────────
create table if not exists public.community_service_categories (
  id uuid primary key default gen_random_uuid(),
  name text not null unique,
  created_at timestamptz not null default now()
);

alter table public.community_service_categories enable row level security;

drop policy if exists "Allow read access to community categories" on public.community_service_categories;
create policy "Allow read access to community categories"
  on public.community_service_categories for select
  to authenticated
  using (true);

-- Seed initial categories
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

-- ── 2. COMMUNITY POSTS TABLE ──────────────────────────────────────────────
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

-- Safely add any new columns if the table already existed previously
alter table public.community_posts add column if not exists author_name text default '';
alter table public.community_posts add column if not exists author_avatar_url text default '';
alter table public.community_posts add column if not exists category text default 'General';
alter table public.community_posts add column if not exists fee_payment text not null default 'Free';
alter table public.community_posts add column if not exists contact_method text not null default 'both';
alter table public.community_posts add column if not exists contact_phone text default '';
alter table public.community_posts add column if not exists contact_email text default '';

alter table public.community_posts enable row level security;

-- Policies for community_posts:
-- 1. All authenticated users can view active posts (or their own posts)
drop policy if exists "Allow read access to community posts" on public.community_posts;
create policy "Allow read access to community posts"
  on public.community_posts for select
  to authenticated
  using (true);

-- 2. Authenticated users can insert posts where author_id is their own auth.uid()
drop policy if exists "Allow authenticated users to create community posts" on public.community_posts;
create policy "Allow authenticated users to create community posts"
  on public.community_posts for insert
  to authenticated
  with check (auth.uid() = author_id);

-- 3. Users can only update their own posts
drop policy if exists "Allow authors to update their own community posts" on public.community_posts;
create policy "Allow authors to update their own community posts"
  on public.community_posts for update
  to authenticated
  using (auth.uid() = author_id)
  with check (auth.uid() = author_id);

-- 4. Users can only delete their own posts
drop policy if exists "Allow authors to delete their own community posts" on public.community_posts;
create policy "Allow authors to delete their own community posts"
  on public.community_posts for delete
  to authenticated
  using (auth.uid() = author_id);

-- ── 3. AUTO-UPDATE updated_at TRIGGER ────────────────────────────────────
create or replace function public.handle_community_post_updated()
returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql;

drop trigger if exists on_community_post_updated on public.community_posts;
create trigger on_community_post_updated
  before update on public.community_posts
  for each row execute procedure public.handle_community_post_updated();
