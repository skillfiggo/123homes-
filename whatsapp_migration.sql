-- ================================================================
-- DATABASE SCHEMA FOR WHATSAPP BOT + LEAD MANAGEMENT
-- ================================================================

-- 1. LEADS TABLE
-- Stores contacts captured via WhatsApp
create table if not exists leads (
  id                  serial primary key,
  name                text,
  phone               text not null unique,
  email               text,
  status              text default 'new', -- 'new' | 'contacted' | 'inspected' | 'closed'
  assigned_agent_id   uuid references profiles(id) on delete set null,
  created_at          timestamptz default now()
);

-- Enable RLS for leads
alter table leads enable row level security;
create policy "Service role full access on leads" on leads for all using (true) with check (true);

-- 2. INSPECTION BOOKINGS
-- Tracks scheduled property visits
create table if not exists inspection_bookings (
  id                  serial primary key,
  lead_id             int references leads(id) on delete cascade,
  listing_id          int references user_listings(id) on delete cascade,
  preferred_date      timestamptz not null,
  status              text default 'pending', -- 'pending' | 'scheduled' | 'completed' | 'cancelled'
  notes               text,
  created_at          timestamptz default now()
);

-- Enable RLS for inspection bookings
alter table inspection_bookings enable row level security;
create policy "Service role full access on bookings" on inspection_bookings for all using (true) with check (true);

-- 3. INQUIRIES
-- Chat transcripts or specific listing requests
create table if not exists inquiries (
  id                  serial primary key,
  lead_id             int references leads(id) on delete cascade,
  listing_id          int references user_listings(id) on delete set null,
  message             text not null,
  created_at          timestamptz default now()
);

-- Enable RLS for inquiries
alter table inquiries enable row level security;
create policy "Service role full access on inquiries" on inquiries for all using (true) with check (true);

-- 4. CHATBOT SESSIONS (STATE MACHINE MANAGER)
-- Keeps track of the state of the conversation per user
create table if not exists bot_sessions (
  phone               text primary key,
  state               text not null default 'welcome', -- 'welcome' | 'browsing' | 'booking_date' | 'booking_confirm' | 'human_handover'
  last_property_id    int,
  metadata            jsonb default '{}'::jsonb,
  updated_at          timestamptz default now()
);

-- Enable RLS for bot sessions
alter table bot_sessions enable row level security;
create policy "Service role full access on sessions" on bot_sessions for all using (true) with check (true);
