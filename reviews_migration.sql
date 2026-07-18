-- ================================================================
-- AGENT REVIEWS & RATINGS
-- Run in Supabase Dashboard → SQL Editor
-- ================================================================

create table if not exists reviews (
  id              serial primary key,
  reviewer_id     uuid references auth.users(id) on delete cascade,
  reviewer_name   text not null default 'User',
  reviewer_avatar text,
  agent_id        uuid references auth.users(id) on delete cascade,
  rating          int not null check (rating >= 1 and rating <= 5),
  comment         text,
  created_at      timestamptz default now(),
  unique(reviewer_id, agent_id)  -- one review per user per agent
);

alter table reviews enable row level security;

drop policy if exists "Anyone can read reviews"              on reviews;
drop policy if exists "Authenticated users can write review" on reviews;
drop policy if exists "Users can update own review"          on reviews;

-- Anyone (logged in) can read all reviews
create policy "Anyone can read reviews"
  on reviews for select using (true);

-- Users can submit a review (reviewer_id must match their uid)
create policy "Authenticated users can write review"
  on reviews for insert to authenticated
  with check (auth.uid() = reviewer_id);

-- Users can update their own review (e.g. change star rating)
create policy "Users can update own review"
  on reviews for update to authenticated
  using (auth.uid() = reviewer_id);
