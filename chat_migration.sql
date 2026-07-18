-- ================================================================
-- CHAT MESSAGES & CONSTRAINTS MIGRATION
-- Run this in Supabase Dashboard → SQL Editor
-- ================================================================

-- Create chat_messages table
create table if not exists chat_messages (
  id         serial primary key,
  conv_id    int  references conversations(id) on delete cascade,
  sender_id  uuid references auth.users(id),
  text       text not null,
  is_read    boolean default false,
  created_at timestamptz default now()
);

-- Enable RLS on chat_messages
alter table chat_messages enable row level security;

-- Drop existing policies if any
drop policy if exists "Conv member read"   on chat_messages;
drop policy if exists "Conv member insert" on chat_messages;

-- Create select policy (participants can read)
create policy "Conv member read"
  on chat_messages for select
  using (
    conv_id in (select id from conversations where user_id = auth.uid())
  );

-- Create insert policy (authenticated user can insert their own messages)
create policy "Conv member insert"
  on chat_messages for insert
  with check (
    auth.uid() = sender_id
    AND conv_id in (select id from conversations where user_id = auth.uid())
  );

-- Ensure conversations table has unique constraint on (user_id, agent_id)
alter table conversations drop constraint if exists conversations_user_id_agent_id_key;
alter table conversations add constraint conversations_user_id_agent_id_key unique (user_id, agent_id);

-- Enable Realtime on chat_messages table
alter publication supabase_realtime add table chat_messages;
