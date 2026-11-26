-- مخطط قاعدة البيانات الموحد لتطبيق شلونكم چات - IQ (عام لكل العراق بدون محافظات)
create extension if not exists "pgcrypto";

-- 1. جدول الملفات الشخصية للمستخدمين
create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  phone text,
  display_name text not null default 'مستخدم شلونكم',
  username text unique,
  bio text default 'أهلاً بكم في شلونكم چات - IQ',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.profiles
add column if not exists username text unique;

alter table public.profiles
add column if not exists bio text default 'أهلاً بكم في شلونكم چات - IQ';

alter table public.profiles
add column if not exists updated_at timestamptz not null default now();

-- دالة إنشاء البروفايل تلقائياً عند تسجيل مستخدم جديد
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, phone, display_name, username)
  values (
    new.id,
    new.phone,
    coalesce(new.raw_user_meta_data->>'display_name', 'مستخدم شلونكم'),
    nullif(lower(trim(new.raw_user_meta_data->>'username')), '')
  )
  on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
after insert on auth.users
for each row execute function public.handle_new_user();

-- تفعيل RLS وسياسات جدول profiles
alter table public.profiles enable row level security;

drop policy if exists "read profiles" on public.profiles;
create policy "read profiles"
on public.profiles for select
using (true);

drop policy if exists "insert own profile" on public.profiles;
create policy "insert own profile"
on public.profiles for insert
with check (auth.uid() = id);

drop policy if exists "update own profile" on public.profiles;
create policy "update own profile"
on public.profiles for update
using (auth.uid() = id)
with check (auth.uid() = id);

-- 2. جدول الرسائل المباشرة
create table if not exists public.messages (
  id uuid primary key default gen_random_uuid(),
  sender_id uuid not null references auth.users(id) on delete cascade,
  receiver_id uuid not null references auth.users(id) on delete cascade,
  content text not null check (char_length(trim(content)) > 0),
  created_at timestamptz not null default now()
);

create index if not exists idx_messages_sender_receiver_time
on public.messages (sender_id, receiver_id, created_at desc);

create index if not exists idx_messages_receiver_sender_time
on public.messages (receiver_id, sender_id, created_at desc);

-- تفعيل RLS وسياسات جدول messages
alter table public.messages enable row level security;

drop policy if exists "read own messages" on public.messages;
create policy "read own messages"
on public.messages for select
using (auth.uid() = sender_id or auth.uid() = receiver_id);

drop policy if exists "send own messages" on public.messages;
create policy "send own messages"
on public.messages for insert
with check (auth.uid() = sender_id);

-- تفعيل Realtime على جدول messages
do $$
begin
  if not exists (
    select 1
    from pg_publication_tables
    where pubname = 'supabase_realtime'
      and schemaname = 'public'
      and tablename = 'messages'
  ) then
    alter publication supabase_realtime add table public.messages;
  end if;
end $$;
