-- Schema for User Profiles and Settings
-- Run this in Supabase SQL Editor

-- ============================================
-- PROFILES TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS profiles (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  full_name TEXT,
  avatar_url TEXT,
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  
  -- Enforce one profile per user
  CONSTRAINT profiles_user_id_key UNIQUE (user_id)
);

-- RLS for Profiles
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view their own profile" ON profiles
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own profile" ON profiles
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own profile" ON profiles
  FOR UPDATE USING (auth.uid() = user_id);

-- ============================================
-- USER SETTINGS TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS user_settings (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  enable_notifications BOOLEAN DEFAULT TRUE,
  enable_vaccine_reminders BOOLEAN DEFAULT TRUE,
  enable_medication_reminders BOOLEAN DEFAULT TRUE,
  enable_appointment_reminders BOOLEAN DEFAULT TRUE,
  reminder_hours_before INTEGER DEFAULT 24,
  updated_at TIMESTAMPTZ DEFAULT NOW(),

  -- Enforce one settings row per user
  CONSTRAINT user_settings_user_id_key UNIQUE (user_id)
);

-- RLS for User Settings
ALTER TABLE user_settings ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view their own settings" ON user_settings
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own settings" ON user_settings
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own settings" ON user_settings
  FOR UPDATE USING (auth.uid() = user_id);

-- ============================================
-- STORAGE BUCKET
-- ============================================
-- Ensure the storage bucket exists for avatars
INSERT INTO storage.buckets (id, name, public)
VALUES ('pet-pal-health', 'pet-pal-health', true)
ON CONFLICT (id) DO NOTHING;

-- Storage Policy: Users can upload their own avatar
CREATE POLICY "Avatar images are publicly accessible"
ON storage.objects FOR SELECT
USING ( bucket_id = 'pet-pal-health' );

CREATE POLICY "Users can upload their own avatar"
ON storage.objects FOR INSERT
WITH CHECK (
  bucket_id = 'pet-pal-health' AND
  auth.uid()::text = (storage.foldername(name))[2]
);

CREATE POLICY "Users can update their own avatar"
ON storage.objects FOR UPDATE
USING (
  bucket_id = 'pet-pal-health' AND
  auth.uid()::text = (storage.foldername(name))[2]
);
