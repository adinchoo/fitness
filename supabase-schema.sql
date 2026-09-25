-- Fitness AI Hub - complete Supabase schema
-- Run this entire file once in Supabase Dashboard > SQL Editor.

create extension if not exists pgcrypto;

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  full_name text not null check (char_length(full_name) between 1 and 80),
  date_of_birth date not null,
  sex_at_birth text not null check (sex_at_birth in ('Male','Female','Prefer not to say')),
  height_cm numeric(5,1) not null check (height_cm between 80 and 250),
  target_weight_kg numeric(5,1) not null check (target_weight_kg between 25 and 400),
  primary_goal text not null check (primary_goal in ('lose_weight','maintain','gain_muscle','improve_fitness','general_health')),
  activity_level text not null check (activity_level in ('sedentary','light','moderate','very_active')),
  target_calories integer not null default 2000 check (target_calories between 800 and 6000),
  target_protein_g integer not null default 120 check (target_protein_g between 20 and 500),
  target_water_ml integer not null default 2500 check (target_water_ml between 500 and 10000),
  target_activity_minutes integer not null default 30 check (target_activity_minutes between 5 and 600),
  diet_preference text,
  allergies text,
  health_notes text,
  timezone text not null default 'Asia/Kuala_Lumpur',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.meal_logs (
  id uuid primary key default gen_random_uuid(), user_id uuid not null references auth.users(id) on delete cascade,
  meal_name text not null, meal_type text not null default 'Meal', calories integer not null check(calories>=0),
  protein_g numeric(7,1) not null default 0, carbs_g numeric(7,1) not null default 0, fat_g numeric(7,1) not null default 0,
  source text not null default 'Manual', photo_path text, logged_at timestamptz not null default now(), created_at timestamptz not null default now()
);
create table if not exists public.activity_logs (
  id uuid primary key default gen_random_uuid(), user_id uuid not null references auth.users(id) on delete cascade,
  activity_name text not null, duration_minutes integer not null check(duration_minutes>0), calories_burned integer not null default 0,
  distance_km numeric(8,2) default 0, source text not null default 'Manual', external_id text, logged_at timestamptz not null default now(), created_at timestamptz not null default now(),
  unique(user_id,source,external_id)
);
create table if not exists public.body_logs (
  id uuid primary key default gen_random_uuid(), user_id uuid not null references auth.users(id) on delete cascade,
  weight_kg numeric(5,1) not null check(weight_kg between 25 and 400), body_fat_percent numeric(4,1), muscle_mass_kg numeric(5,1), bmi numeric(4,1),
  source text not null default 'Manual', logged_at timestamptz not null default now(), created_at timestamptz not null default now()
);
create table if not exists public.sleep_logs (
  id uuid primary key default gen_random_uuid(), user_id uuid not null references auth.users(id) on delete cascade,
  duration_hours numeric(4,1) not null check(duration_hours between 0 and 24), quality integer not null check(quality between 1 and 5),
  source text not null default 'Manual', logged_at timestamptz not null default now(), created_at timestamptz not null default now()
);
create table if not exists public.water_logs (
  id uuid primary key default gen_random_uuid(), user_id uuid not null references auth.users(id) on delete cascade,
  amount_ml integer not null check(amount_ml between 1 and 5000), logged_at timestamptz not null default now(), created_at timestamptz not null default now()
);

create index if not exists meal_logs_user_date_idx on public.meal_logs(user_id,logged_at desc);
create index if not exists activity_logs_user_date_idx on public.activity_logs(user_id,logged_at desc);
create index if not exists body_logs_user_date_idx on public.body_logs(user_id,logged_at desc);
create index if not exists sleep_logs_user_date_idx on public.sleep_logs(user_id,logged_at desc);
create index if not exists water_logs_user_date_idx on public.water_logs(user_id,logged_at desc);

alter table public.profiles enable row level security;
alter table public.meal_logs enable row level security;
alter table public.activity_logs enable row level security;
alter table public.body_logs enable row level security;
alter table public.sleep_logs enable row level security;
alter table public.water_logs enable row level security;

drop policy if exists "profiles_own_all" on public.profiles;
create policy "profiles_own_all" on public.profiles for all to authenticated using ((select auth.uid())=id) with check ((select auth.uid())=id);

do $$ declare t text; begin
  foreach t in array array['meal_logs','activity_logs','body_logs','sleep_logs','water_logs'] loop
    execute format('drop policy if exists %I on public.%I', t||'_own_all', t);
    execute format('create policy %I on public.%I for all to authenticated using ((select auth.uid())=user_id) with check ((select auth.uid())=user_id)', t||'_own_all', t);
  end loop;
end $$;

grant usage on schema public to authenticated;
grant select,insert,update,delete on public.profiles,public.meal_logs,public.activity_logs,public.body_logs,public.sleep_logs,public.water_logs to authenticated;
revoke all on public.profiles,public.meal_logs,public.activity_logs,public.body_logs,public.sleep_logs,public.water_logs from anon;

create or replace function public.handle_new_user() returns trigger language plpgsql security definer set search_path=public as $$
begin
  insert into public.profiles(id,full_name,date_of_birth,sex_at_birth,height_cm,target_weight_kg,primary_goal,activity_level,target_calories,target_protein_g,target_water_ml,target_activity_minutes,diet_preference,allergies,health_notes,timezone)
  values(new.id,coalesce(new.raw_user_meta_data->>'full_name','User'),(new.raw_user_meta_data->>'date_of_birth')::date,coalesce(new.raw_user_meta_data->>'sex_at_birth','Prefer not to say'),(new.raw_user_meta_data->>'height_cm')::numeric,(new.raw_user_meta_data->>'target_weight_kg')::numeric,coalesce(new.raw_user_meta_data->>'primary_goal','general_health'),coalesce(new.raw_user_meta_data->>'activity_level','light'),coalesce((new.raw_user_meta_data->>'target_calories')::integer,2000),coalesce((new.raw_user_meta_data->>'target_protein_g')::integer,120),coalesce((new.raw_user_meta_data->>'target_water_ml')::integer,2500),coalesce((new.raw_user_meta_data->>'target_activity_minutes')::integer,30),nullif(new.raw_user_meta_data->>'diet_preference',''),nullif(new.raw_user_meta_data->>'allergies',''),nullif(new.raw_user_meta_data->>'health_notes',''),coalesce(new.raw_user_meta_data->>'timezone','Asia/Kuala_Lumpur'));
  insert into public.body_logs(user_id,weight_kg,source,logged_at) values(new.id,(new.raw_user_meta_data->>'current_weight_kg')::numeric,'Signup',now());
  return new;
end $$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created after insert on auth.users for each row execute procedure public.handle_new_user();
