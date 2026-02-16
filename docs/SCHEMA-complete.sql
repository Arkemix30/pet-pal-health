-- Complete Schema Migration for Pet Pal Health
-- Run this in Supabase SQL Editor to create all required tables

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================
-- PETS TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS pets (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  owner_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  species TEXT NOT NULL,
  breed TEXT,
  birth_date TIMESTAMPTZ,
  weight_kg DECIMAL(5,2),
  photo_url TEXT,
  is_deleted BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- HEALTH SCHEDULES TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS health_schedules (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  pet_id UUID REFERENCES pets(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  type TEXT NOT NULL,
  start_date TIMESTAMPTZ NOT NULL,
  frequency TEXT,
  notes TEXT,
  is_completed BOOLEAN DEFAULT FALSE,
  completed_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- PET SHARES TABLE (for family sharing)
-- ============================================
CREATE TABLE IF NOT EXISTS pet_shares (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  pet_id UUID REFERENCES pets(id) ON DELETE CASCADE,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  access_level TEXT DEFAULT 'editor',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(pet_id, user_id)
);

-- ============================================
-- PET INVITATIONS TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS pet_invitations (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  pet_id UUID REFERENCES pets(id) ON DELETE CASCADE,
  inviter_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  invitee_email TEXT NOT NULL,
  token TEXT UNIQUE NOT NULL,
  status TEXT DEFAULT 'pending',
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- VETS TABLE (for vet directory)
-- ============================================
CREATE TABLE IF NOT EXISTS vets (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  owner_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  phone TEXT,
  address TEXT,
  notes TEXT,
  is_deleted BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- ENABLE RLS ON ALL TABLES
-- ============================================
ALTER TABLE pets ENABLE ROW LEVEL SECURITY;
ALTER TABLE health_schedules ENABLE ROW LEVEL SECURITY;
ALTER TABLE pet_shares ENABLE ROW LEVEL SECURITY;
ALTER TABLE pet_invitations ENABLE ROW LEVEL SECURITY;
ALTER TABLE vets ENABLE ROW LEVEL SECURITY;

-- ============================================
-- RLS POLICIES FOR PETS
-- ============================================
DROP POLICY IF EXISTS "Users can see own pets" ON pets;

CREATE POLICY "Users can see pets they own or are shared with" ON pets
  FOR SELECT USING (
    owner_id = auth.uid() OR
    EXISTS (SELECT 1 FROM pet_shares WHERE pet_id = pets.id AND user_id = auth.uid())
  );

CREATE POLICY "Users can insert own pets" ON pets
  FOR INSERT WITH CHECK (owner_id = auth.uid());

CREATE POLICY "Users can update pets they own or have editor access" ON pets
  FOR UPDATE USING (
    owner_id = auth.uid() OR
    EXISTS (SELECT 1 FROM pet_shares WHERE pet_id = pets.id AND user_id = auth.uid() AND access_level = 'editor')
  );

CREATE POLICY "Users can delete own pets" ON pets
  FOR DELETE USING (owner_id = auth.uid());

-- ============================================
-- RLS POLICIES FOR HEALTH SCHEDULES
-- ============================================
CREATE POLICY "Users can see schedules of their pets" ON health_schedules
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM pets
      WHERE pets.id = health_schedules.pet_id
      AND (pets.owner_id = auth.uid() OR EXISTS (SELECT 1 FROM pet_shares WHERE pet_id = pets.id AND user_id = auth.uid()))
    )
  );

CREATE POLICY "Users can manage schedules of their pets" ON health_schedules
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM pets
      WHERE pets.id = health_schedules.pet_id
      AND (pets.owner_id = auth.uid() OR EXISTS (SELECT 1 FROM pet_shares WHERE pet_id = pets.id AND user_id = auth.uid() AND access_level = 'editor'))
    )
  );

-- ============================================
-- RLS POLICIES FOR PET SHARES
-- ============================================
CREATE POLICY "Owners can manage pet shares" ON pet_shares
  FOR ALL USING (
    EXISTS (SELECT 1 FROM pets WHERE pets.id = pet_id AND pets.owner_id = auth.uid())
  );

CREATE POLICY "Shared users can see their shares" ON pet_shares
  FOR SELECT USING (user_id = auth.uid());

-- ============================================
-- RLS POLICIES FOR PET INVITATIONS
-- ============================================
CREATE POLICY "Users can manage own invitations" ON pet_invitations
  FOR ALL USING (
    EXISTS (SELECT 1 FROM pets WHERE pets.id = pet_id AND pets.owner_id = auth.uid())
  );

-- ============================================
-- RLS POLICIES FOR VETS
-- ============================================
CREATE POLICY "Users can manage own vets" ON vets
  FOR ALL USING (owner_id = auth.uid());

-- ============================================
-- UPDATED AT TRIGGER FUNCTION
-- ============================================
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply trigger to all tables
CREATE TRIGGER update_pets_updated_at BEFORE UPDATE ON pets
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_health_schedules_updated_at BEFORE UPDATE ON health_schedules
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_vets_updated_at BEFORE UPDATE ON vets
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
