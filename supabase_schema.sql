-- Run this in your Supabase SQL Editor (Dashboard > SQL Editor)
-- Then: go to Storage, create bucket named 'clothes' and make it public

-- ============================================
-- USERS TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS users (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  username TEXT NOT NULL,
  email TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE users ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can read own data"
  ON users FOR SELECT
  USING (auth.uid() = id);

CREATE POLICY "Users can insert own data"
  ON users FOR INSERT
  WITH CHECK (auth.uid() = id);

-- ============================================
-- CLOTHES TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS clothes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  image_url TEXT NOT NULL,
  height_inches DOUBLE PRECISION NOT NULL,
  width_inches DOUBLE PRECISION NOT NULL,
  category TEXT NOT NULL CHECK (category IN ('Shirt', 'Pants', 'Shoes')),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE clothes ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can read own clothes"
  ON clothes FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own clothes"
  ON clothes FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete own clothes"
  ON clothes FOR DELETE
  USING (auth.uid() = user_id);

-- ============================================
-- FAVORITES TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS favorites (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  shirt_id TEXT NOT NULL,
  pants_id TEXT NOT NULL,
  shoes_id TEXT NOT NULL,
  saved_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE favorites ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can read own favorites"
  ON favorites FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own favorites"
  ON favorites FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete own favorites"
  ON favorites FOR DELETE
  USING (auth.uid() = user_id);

-- ============================================
-- IMPORTANT: Disable email confirmation
-- ============================================
-- Go to Authentication > Settings > General
-- Set "Confirm email" to OFF
-- Otherwise users won't be auto-logged in after registration
