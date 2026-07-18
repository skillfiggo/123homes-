-- ================================================================
-- 123Homes Supabase Schema
-- Run this entire script in: Supabase Dashboard → SQL Editor → New query
-- ================================================================

-- 1. AGENTS
create table if not exists agents (
  id          serial primary key,
  name        text not null,
  role        text,
  avatar_url  text,
  rating      numeric default 4.5
);

-- 2. PROPERTIES
create table if not exists properties (
  id          serial primary key,
  name        text not null,
  price       text not null,
  location    text,
  type        text,
  beds        int,
  baths       int,
  rating      numeric,
  image_path  text,
  badge       text,
  description text,
  agent_id    int references agents(id),
  sqft        text,
  floors      text,
  tags        text[],
  lat         double precision,
  lng         double precision
);

-- 3. USER PROFILES (extends Supabase auth.users)
create table if not exists profiles (
  id          uuid primary key references auth.users(id) on delete cascade,
  full_name   text,
  avatar_url  text,
  created_at  timestamptz default now()
);

-- Auto-create a profile row whenever a new user signs up
create or replace function handle_new_user()
returns trigger as $$
begin
  insert into profiles (id, full_name)
  values (
    new.id,
    new.raw_user_meta_data->>'full_name'
  );
  return new;
end;
$$ language plpgsql security definer;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure handle_new_user();

-- 4. WISHLISTS (per user)
create table if not exists wishlists (
  id          serial primary key,
  user_id     uuid references auth.users(id) on delete cascade,
  property_id int  references properties(id) on delete cascade,
  created_at  timestamptz default now(),
  unique(user_id, property_id)
);

-- 5. CONVERSATIONS
create table if not exists conversations (
  id          serial primary key,
  user_id     uuid references auth.users(id) on delete cascade,
  agent_id    int  references agents(id),
  last_msg    text,
  unread      int  default 0,
  updated_at  timestamptz default now()
);

-- 6. MESSAGES
create table if not exists messages (
  id              serial primary key,
  conversation_id int references conversations(id) on delete cascade,
  text            text not null,
  is_sent         boolean default true,
  created_at      timestamptz default now()
);

-- ================================================================
-- ROW LEVEL SECURITY
-- ================================================================

alter table profiles      enable row level security;
alter table wishlists     enable row level security;
alter table conversations enable row level security;
alter table messages      enable row level security;
alter table properties    enable row level security;
alter table agents        enable row level security;

-- Drop existing policies first so this script is safely re-runnable
drop policy if exists "Public read properties" on properties;
drop policy if exists "Public read agents"     on agents;
drop policy if exists "Own profile read"       on profiles;
drop policy if exists "Own profile update"     on profiles;
drop policy if exists "Own wishlist"           on wishlists;
drop policy if exists "Own conversations"      on conversations;
drop policy if exists "Own messages"           on messages;

-- Properties & agents: readable by anyone
create policy "Public read properties" on properties for select using (true);
create policy "Public read agents"     on agents     for select using (true);

-- Profiles: own row only
create policy "Own profile read"   on profiles for select using (auth.uid() = id);
create policy "Own profile update" on profiles for update using (auth.uid() = id);

-- Wishlists: own rows only
create policy "Own wishlist" on wishlists for all using (auth.uid() = user_id);

-- Conversations: own rows only
create policy "Own conversations" on conversations for all using (auth.uid() = user_id);

-- Messages: via own conversations
create policy "Own messages" on messages for all
  using (
    exists (
      select 1 from conversations c
      where c.id = messages.conversation_id
        and c.user_id = auth.uid()
    )
  );


-- ================================================================
-- SEED DATA — the 5 mock properties + 4 agents
-- ================================================================

insert into agents (name, role, avatar_url, rating) values
  ('Jayson Roy',  'Marketer',   'https://api.dicebear.com/7.x/avataaars/svg?seed=Jayson&backgroundColor=c0aede',  4.9),
  ('Sarah Kim',   'Agent',      'https://api.dicebear.com/7.x/avataaars/svg?seed=Sarah&backgroundColor=b6e3f4',   4.8),
  ('Michael Obi', 'Consultant', 'https://api.dicebear.com/7.x/avataaars/svg?seed=Michael&backgroundColor=d1fae5', 4.7),
  ('Amara Nwosu', 'Broker',     'https://api.dicebear.com/7.x/avataaars/svg?seed=Amara&backgroundColor=fde68a',   4.9)
on conflict do nothing;

insert into properties (name, price, location, type, beds, baths, rating, image_path, badge, description, agent_id, sqft, floors, tags, lat, lng) values
  ('Aaradhya Homes',    '₦440,000', 'Ananda', 'house',     4, 3, 4.5, 'house1.png',     'Best Deal', 'A stunning modern home nestled in a peaceful neighborhood with premium finishes throughout.', 1, '21k', '2 Floor',  ARRAY['4 Rooms','210 Sqm','Furnished'], 6.45, 3.40),
  ('Sunset Villa',      '₦780,000', 'Lekki',  'villa',     5, 4, 4.8, 'villa1.png',      'Hot',       'Luxurious villa with a resort-style pool, breathtaking sunset views and expansive outdoor entertaining areas.', 2, '35k', '1 Floor',  ARRAY['5 Rooms','350 Sqm','Pool'],      6.46, 3.48),
  ('Skyline Apartment', '₦220,000', 'VI',     'apartment', 2, 2, 4.3, 'apartment1.png',  'New',       'Sleek high-rise apartment with panoramic city views, modern amenities and concierge service 24/7.', 3, '12k', '14 Floor', ARRAY['2 Rooms','110 Sqm','Gym'],       6.43, 3.42),
  ('Heritage House',    '₦350,000', 'Ikoyi',  'house',     3, 2, 4.6, 'house2.png',      'Best Deal', 'Classic architectural style meets contemporary comfort in this beautifully maintained family home.', 4, '18k', '2 Floor',  ARRAY['3 Rooms','180 Sqm','Garden'],    6.44, 3.43),
  ('Ocean Condo',       '₦550,000', 'Oniru',  'condo',     3, 3, 4.7, 'condo1.png',      'Featured',  'Premium ocean-facing condominium with direct beach access, private balcony and world-class amenities.',  1, '25k', '18 Floor', ARRAY['3 Rooms','250 Sqm','Sea View'],  6.47, 3.44)
on conflict do nothing;

-- ================================================================
-- 7. USER LISTINGS (properties submitted by users)
-- type can be: house | apartment | villa | condo | land
-- beds/baths are nullable (land parcels don't have them)
-- ================================================================

create table if not exists user_listings (
  id          serial primary key,
  user_id     uuid references auth.users(id) on delete cascade,
  title       text not null,
  price       text not null,
  location    text,
  type        text,                  -- 'house','apartment','villa','condo','land'
  beds        int,                   -- null for land
  baths       int,                   -- null for land
  sqft        text,
  floors      text,
  description text,
  badge       text default 'New',
  image_urls  text[],                -- public URLs from Supabase Storage
  status      text default 'pending', -- pending | approved | rejected
  is_promoted boolean default false,   -- true when user has boosted this listing
  promoted_at timestamptz,             -- timestamp of last boost (for ordering)
  created_at  timestamptz default now()
);

alter table user_listings enable row level security;

drop policy if exists "Own listings all"    on user_listings;
drop policy if exists "Public read listings" on user_listings;

-- Users can read, insert, update and delete their own listings
create policy "Own listings all"
  on user_listings for all
  using  (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- Anyone can read approved listings (for future public browse)
create policy "Public read listings"
  on user_listings for select
  using (status = 'approved');

-- ================================================================
-- 8. STORAGE — property-images bucket
--    Run ONCE in Supabase Dashboard → Storage → New bucket,
--    OR via SQL as below (requires pg_storage extension enabled).
-- ================================================================

-- Create bucket if it doesn't exist (idempotent)
insert into storage.buckets (id, name, public)
values ('property-images', 'property-images', true)
on conflict (id) do nothing;

-- Drop old storage policies first (safe re-run)
drop policy if exists "Authenticated users can upload property images" on storage.objects;
drop policy if exists "Anyone can read property images"               on storage.objects;
drop policy if exists "Owner can delete property images"              on storage.objects;

-- Allow signed-in users to upload under their own uid folder
create policy "Authenticated users can upload property images"
  on storage.objects for insert
  to authenticated
  with check (bucket_id = 'property-images' AND (storage.foldername(name))[1] = 'listings');

-- Public read for all images in the bucket
create policy "Anyone can read property images"
  on storage.objects for select
  using (bucket_id = 'property-images');

-- Users can delete only their own uploads
create policy "Owner can delete property images"
  on storage.objects for delete
  to authenticated
  using (bucket_id = 'property-images' AND auth.uid()::text = (storage.foldername(name))[2]);


-- ================================================================
-- 9. AGENT VERIFICATION SYSTEM
-- Run this block in Supabase Dashboard → SQL Editor
-- ================================================================

-- 9a. Extend profiles with verification fields
alter table profiles
  add column if not exists is_verified   boolean default false,
  add column if not exists phone         text,
  add column if not exists business_name text;

-- 9b. Agent applications (allows re-application after rejection)
create table if not exists agent_applications (
  id               serial primary key,
  user_id          uuid references auth.users(id) on delete cascade,
  full_name        text not null,
  business_name    text not null,
  phone            text not null,
  experience_years int  not null,
  cac_doc_url      text,
  status           text default 'pending',  -- pending | approved | rejected
  admin_note       text,
  submitted_at     timestamptz default now(),
  reviewed_at      timestamptz
);

alter table agent_applications enable row level security;

drop policy if exists "Own application read"   on agent_applications;
drop policy if exists "Own application insert"  on agent_applications;

create policy "Own application read"
  on agent_applications for select
  using (auth.uid() = user_id);

create policy "Own application insert"
  on agent_applications for insert
  with check (auth.uid() = user_id);

-- 9c. Track whether the poster was verified at time of listing
alter table user_listings
  add column if not exists poster_verified boolean default false;

-- 9d. Private storage bucket for CAC certificate uploads
insert into storage.buckets (id, name, public)
values ('agent-docs', 'agent-docs', false)
on conflict (id) do nothing;

drop policy if exists "Own doc upload" on storage.objects;
drop policy if exists "Own doc read"   on storage.objects;

create policy "Own doc upload"
  on storage.objects for insert
  to authenticated
  with check (
    bucket_id = 'agent-docs'
    AND (storage.foldername(name))[1] = auth.uid()::text
  );

create policy "Own doc read"
  on storage.objects for select
  to authenticated
  using (
    bucket_id = 'agent-docs'
    AND (storage.foldername(name))[1] = auth.uid()::text
  );


-- ================================================================
-- 10. REAL-TIME CHAT
-- Run this block in Supabase Dashboard → SQL Editor
-- ================================================================

-- 10a. Conversations (one per user–agent pair)
create table if not exists conversations (
  id         serial primary key,
  user_id    uuid references auth.users(id) on delete cascade,
  agent_id   int  references agents(id),
  created_at timestamptz default now(),
  unique(user_id, agent_id)
);

alter table conversations enable row level security;

drop policy if exists "Own conversations" on conversations;
create policy "Own conversations"
  on conversations for all
  using  (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- 10b. Chat Messages
create table if not exists chat_messages (
  id         serial primary key,
  conv_id    int  references conversations(id) on delete cascade,
  sender_id  uuid references auth.users(id),
  text       text not null,
  is_read    boolean default false,
  created_at timestamptz default now()
);

alter table chat_messages enable row level security;

drop policy if exists "Conv member read"   on chat_messages;
drop policy if exists "Conv member insert" on chat_messages;

create policy "Conv member read"
  on chat_messages for select
  using (
    conv_id in (select id from conversations where user_id = auth.uid())
  );

create policy "Conv member insert"
  on chat_messages for insert
  with check (
    auth.uid() = sender_id
    AND conv_id in (select id from conversations where user_id = auth.uid())
  );

-- 10c. Enable Realtime on chat_messages table
alter publication supabase_realtime add table chat_messages;

-- ================================================================
-- 11. PROFILE AVATARS STORAGE BUCKET
-- Run this block in Supabase Dashboard → SQL Editor
-- ================================================================
insert into storage.buckets (id, name, public)
values ('avatars', 'avatars', true)
on conflict (id) do nothing;

drop policy if exists "Anyone can read avatars" on storage.objects;
drop policy if exists "Authenticated users can upload avatars" on storage.objects;
drop policy if exists "Owner can delete avatars" on storage.objects;

create policy "Anyone can read avatars"
  on storage.objects for select
  using (bucket_id = 'avatars');

create policy "Authenticated users can upload avatars"
  on storage.objects for insert
  to authenticated
  with check (
    bucket_id = 'avatars'
    AND (storage.foldername(name))[1] = auth.uid()::text
  );

create policy "Owner can delete avatars"
  on storage.objects for delete
  to authenticated
  using (
    bucket_id = 'avatars'
    AND (storage.foldername(name))[1] = auth.uid()::text
  );

-- ================================================================
-- 12. PHOTOS STORAGE BUCKET
-- Run this block in Supabase Dashboard → SQL Editor
-- ================================================================
insert into storage.buckets (id, name, public)
values ('photos', 'photos', true)
on conflict (id) do nothing;

drop policy if exists "Anyone can read photos" on storage.objects;
drop policy if exists "Authenticated users can upload photos" on storage.objects;
drop policy if exists "Owner can delete photos" on storage.objects;

create policy "Anyone can read photos"
  on storage.objects for select
  using (bucket_id = 'photos');

create policy "Authenticated users can upload photos"
  on storage.objects for insert
  to authenticated
  with check (
    bucket_id = 'photos'
    AND (storage.foldername(name))[1] = auth.uid()::text
  );

create policy "Owner can delete photos"
  on storage.objects for delete
  to authenticated
  using (
    bucket_id = 'photos'
    AND (storage.foldername(name))[1] = auth.uid()::text
  );

-- ================================================================
-- 13. LISTING PROMOTION (Mini Ads)
-- Run this block in Supabase Dashboard → SQL Editor to migrate
-- existing databases that already have user_listings created.
-- ================================================================
alter table user_listings
  add column if not exists is_promoted boolean default false,
  add column if not exists promoted_at timestamptz;


