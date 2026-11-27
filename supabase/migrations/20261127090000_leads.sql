create table if not exists public.leads (
  id uuid primary key default gen_random_uuid(),
  created_at timestamptz not null default now(),
  name text not null,
  email text not null,
  phone text,
  interest text,
  message text,
  source text,
  status text not null default 'new'
);

create index if not exists leads_created_at_idx on public.leads (created_at desc);

alter table public.leads enable row level security;

drop policy if exists "Anyone can submit a lead" on public.leads;
create policy "Anyone can submit a lead" on public.leads for insert to anon with check (true);
