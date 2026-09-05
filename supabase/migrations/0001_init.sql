-- Penumbra schema. Apply on a Frankfurt Supabase project.
-- RLS is the authorization boundary.

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  display_name text,
  locale text,
  created_at timestamptz not null default now()
);

create table if not exists public.boards (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references auth.users(id) on delete cascade,
  title text not null,
  restricted boolean not null default false,
  updated_at timestamptz not null default now()
);

create table if not exists public.board_nodes (
  id uuid primary key default gen_random_uuid(),
  board_id uuid not null references public.boards(id) on delete cascade,
  owner_id uuid not null references auth.users(id) on delete cascade,
  ciphertext text not null
);

create table if not exists public.consent_events (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  kind text not null,
  granted boolean not null,
  at timestamptz not null default now()
);

create table if not exists public.security_events (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users(id) on delete set null,
  type text not null,
  detail text,
  at timestamptz not null default now()
);

alter table public.profiles enable row level security;
alter table public.boards enable row level security;
alter table public.board_nodes enable row level security;
alter table public.consent_events enable row level security;
alter table public.security_events enable row level security;

create policy "own profiles" on public.profiles
  for all using (auth.uid() = id) with check (auth.uid() = id);

create policy "own boards" on public.boards
  for all using (auth.uid() = owner_id) with check (auth.uid() = owner_id);

create policy "own nodes" on public.board_nodes
  for all using (auth.uid() = owner_id) with check (auth.uid() = owner_id);

create policy "own consents" on public.consent_events
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

create policy "own security events" on public.security_events
  for insert with check (auth.uid() = user_id);
create policy "read own security events" on public.security_events
  for select using (auth.uid() = user_id);
