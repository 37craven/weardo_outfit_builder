-- Run this in your Supabase SQL Editor (Dashboard > SQL Editor)
-- If you already ran a previous version, run this first to migrate:
--   ALTER TABLE clothes ADD COLUMN IF NOT EXISTS is_favorited BOOLEAN DEFAULT false;
--   ALTER TABLE clothes ADD COLUMN IF NOT EXISTS name TEXT NOT NULL DEFAULT '';
--   ALTER TABLE clothes DROP CONSTRAINT IF EXISTS clothes_category_check;
--   ALTER TABLE clothes ADD CONSTRAINT clothes_category_check CHECK (category IN ('Headwear', 'Outer Tops', 'Inner Tops', 'Bottoms', 'Footwear'));
--   ALTER TABLE favorites ADD COLUMN IF NOT EXISTS outer_id TEXT;
--   ALTER TABLE favorites ADD COLUMN IF NOT EXISTS inner_id TEXT;
--   UPDATE favorites SET inner_id = shirt_id WHERE inner_id IS NULL;
--   ALTER TABLE favorites DROP COLUMN IF EXISTS shirt_id;

-- ============================================
-- USERS TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS users (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  username TEXT NOT NULL UNIQUE,
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
  category TEXT NOT NULL CHECK (category IN ('Headwear', 'Outer Tops', 'Inner Tops', 'Bottoms', 'Footwear')),
  name TEXT NOT NULL DEFAULT '',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  is_favorited BOOLEAN DEFAULT false
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
-- If favorites already exists, run: ALTER TABLE favorites ADD COLUMN IF NOT EXISTS headwear_id TEXT;

CREATE TABLE IF NOT EXISTS favorites (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  headwear_id TEXT,
  outer_id TEXT,
  inner_id TEXT NOT NULL,
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
-- STORAGE BUCKET & RLS POLICIES
-- ============================================
-- Create the 'clothes' bucket (idempotent)
INSERT INTO storage.buckets (id, name, public)
VALUES ('clothes', 'clothes', true)
ON CONFLICT (id) DO NOTHING;

-- Allow authenticated users to upload files to the clothes bucket
CREATE POLICY "Allow authenticated uploads"
  ON storage.objects FOR INSERT
  TO authenticated
  WITH CHECK (bucket_id = 'clothes');

-- Allow public read access to files in the clothes bucket
CREATE POLICY "Allow public reads"
  ON storage.objects FOR SELECT
  USING (bucket_id = 'clothes');

-- Allow users to delete their own files from the clothes bucket
CREATE POLICY "Allow individual delete"
  ON storage.objects FOR DELETE
  TO authenticated
  USING (bucket_id = 'clothes' AND owner = auth.uid());

-- ============================================
-- IMPORTANT: Disable email confirmation
-- ============================================
-- Go to Authentication > Settings > General
-- Set "Confirm email" to OFF
-- Otherwise users won't be auto-logged in after registration
