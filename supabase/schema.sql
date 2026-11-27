-- Run in the Supabase SQL Editor, then set up Email auth in Authentication -> Providers.

create type public.app_role as enum ('customer', 'student');

create table if not exists public.customer_profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  full_name text,
  phone text,
  company text,
  created_at timestamptz not null default now()
);

create table if not exists public.student_profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  full_name text,
  phone text,
  course_interest text,
  created_at timestamptz not null default now()
);

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if coalesce(new.raw_user_meta_data ->> 'role', 'customer') = 'student' then
    insert into public.student_profiles (id, full_name, phone, course_interest)
    values (new.id, new.raw_user_meta_data ->> 'full_name', new.raw_user_meta_data ->> 'phone', new.raw_user_meta_data ->> 'course_interest')
    on conflict (id) do nothing;
  else
    insert into public.customer_profiles (id, full_name, phone, company)
    values (new.id, new.raw_user_meta_data ->> 'full_name', new.raw_user_meta_data ->> 'phone', new.raw_user_meta_data ->> 'company')
    on conflict (id) do nothing;
  end if;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

alter table public.customer_profiles enable row level security;
alter table public.student_profiles enable row level security;

drop policy if exists "Customers read own profile" on public.customer_profiles;
create policy "Customers read own profile" on public.customer_profiles for select using (auth.uid() = id);

drop policy if exists "Customers update own profile" on public.customer_profiles;
create policy "Customers update own profile" on public.customer_profiles for update using (auth.uid() = id);

drop policy if exists "Students read own profile" on public.student_profiles;
create policy "Students read own profile" on public.student_profiles for select using (auth.uid() = id);

drop policy if exists "Students update own profile" on public.student_profiles;
create policy "Students update own profile" on public.student_profiles for update using (auth.uid() = id);
