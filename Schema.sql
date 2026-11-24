
-- Shlonkum Chat - IQ - Supabase Schema - Phase 1
-- Enable extensions
create extension if not exists "pgcrypto";

-- 1. Profiles - المستخدمين
create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  phone text unique not null,
  display_name text not null,
  avatar_url text,
  governorate text, -- البصرة، بغداد، أربيل... 18 محافظة
  is_verified boolean default false,
  created_at timestamptz default now()
);

-- 2. Chats - المحادثات الفردية والجماعية
create table public.chats (
  id uuid primary key default gen_random_uuid(),
  type text check (type in ('direct','group')) not null,
  title text,
  avatar_url text,
  created_by uuid references public.profiles(id),
  created_at timestamptz default now()
);

-- 3. Chat members
create table public.chat_members (
  chat_id uuid references public.chats(id) on delete cascade,
  user_id uuid references public.profiles(id) on delete cascade,
  role text default 'member',
  joined_at timestamptz default now(),
  primary key (chat_id, user_id)
);

-- 4. Messages - الرسائل
create table public.messages (
  id uuid primary key default gen_random_uuid(),
  chat_id uuid references public.chats(id) on delete cascade,
  sender_id uuid references public.profiles(id),
  content text,
  media_url text, -- صورة / فيديو بجودة كاملة من Supabase Storage / Cloudflare R2
  media_type text check (media_type in ('text','image','video','voice','file')),
  created_at timestamptz default now()
);

-- 5. Official Channels - القنوات الرسمية العراقية - الميزة الذهبية
create table public.official_channels (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  slug text unique not null,
  governorate text not null, -- 18 محافظة
  category text check (category in ('education','government','health','emergency','municipality','other')) not null,
  description text,
  avatar_url text,
  is_verified boolean default true, -- علامة صح زرقاء
  owner_name text, -- اسم الجهة الرسمية
  owner_document_url text, -- الكتاب الرسمي
  admin_id uuid references public.profiles(id),
  subscribers_count int default 0,
  created_at timestamptz default now()
);

-- 6. Channel Posts - منشورات القنوات الرسمية
create table public.channel_posts (
  id uuid primary key default gen_random_uuid(),
  channel_id uuid references public.official_channels(id) on delete cascade,
  author_id uuid references public.profiles(id),
  content text not null,
  media_url text,
  is_official boolean default true,
  created_at timestamptz default now()
);

-- 7. Channel Subscribers
create table public.channel_subscribers (
  channel_id uuid references public.official_channels(id) on delete cascade,
  user_id uuid references public.profiles(id) on delete cascade,
  subscribed_at timestamptz default now(),
  primary key (channel_id, user_id)
);

-- Storage buckets (create in Supabase Dashboard):
-- avatars, chat-media, channel-media, official-documents

-- RLS: تفعيل الحماية - كل واحد يشوف بس رسائله
alter table public.profiles enable row level security;
alter table public.chats enable row level security;
alter table public.messages enable row level security;
alter table public.official_channels enable row level security;
alter table public.channel_posts enable row level security;
