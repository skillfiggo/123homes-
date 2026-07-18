-- SQL Migration to add lat/lng columns to user_listings
ALTER TABLE user_listings ADD COLUMN IF NOT EXISTS lat double precision;
ALTER TABLE user_listings ADD COLUMN IF NOT EXISTS lng double precision;
