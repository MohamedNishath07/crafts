-- ============================================================================
-- Supabase Schema for Crafts (Debit Recovery System)
-- Run this entire file in your Supabase project's SQL Editor.
-- https://app.supabase.com/project/<your-ref>/sql
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1. Enable the uuid extension (needed for auth.users references)
-- ----------------------------------------------------------------------------
create extension if not exists "uuid-ossp";

-- ----------------------------------------------------------------------------
-- 2. public.profiles table
--    One row per authenticated user. Linked 1:1 to auth.users.id.
-- ----------------------------------------------------------------------------
create table if not exists public.profiles (
  id uuid references auth.users not null primary key,
  tenant_id text not null default 'default_tenant',
  email text,
  full_name text,
  role text not null default 'recovery_officer', -- admin | recovery_officer | finance_officer
  is_active boolean not null default true,
  created_at timestamp with time zone not null default timezone('utc'::text, now()),
  updated_at timestamp with time zone not null default timezone('utc'::text, now())
);

-- ----------------------------------------------------------------------------
-- 3. Row Level Security (RLS)
--    - Anyone can read profiles (needed for lookups)
--    - Users can insert their own profile on sign-up
--    - Users can update their own profile
-- ----------------------------------------------------------------------------
alter table public.profiles enable row level security;

create policy "Profiles are viewable by everyone"
  on public.profiles for select
  using ( true );

create policy "Users can insert their own profile"
  on public.profiles for insert
  with check ( auth.uid() = id );

create policy "Users can update their own profile"
  on public.profiles for update
  using ( auth.uid() = id );

-- ----------------------------------------------------------------------------
-- 4. Auto-create a profile whenever a new user signs up via Supabase Auth
--    This guarantees the profile row exists even if the Flutter app
--    upsert logic is bypassed.
-- ----------------------------------------------------------------------------
create or replace function public.handle_new_user()
returns trigger as $$
begin
  insert into public.profiles (
    id,
    email,
    full_name,
    role,
    tenant_id,
    is_active
  ) values (
    new.id,
    new.email,
    coalesce(new.raw_user_meta_data->>'full_name', ''),
    'recovery_officer',
    'default_tenant',
    true
  );
  return new;
end;
$$ language plpgsql security definer;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();

-- ----------------------------------------------------------------------------
-- 5. Indexes
-- ----------------------------------------------------------------------------
create index if not exists profiles_email_idx on public.profiles (email);
create index if not exists profiles_tenant_id_idx on public.profiles (tenant_id);

-- ============================================================================
-- Done. Now:
--   1. Enable Email/Password provider: Authentication → Providers → Email → ON
--   2. (Optional) Disable email confirmations for instant sign-in:
--      Authentication → Settings → "Enable email confirmations" → OFF
-- ============================================================================
