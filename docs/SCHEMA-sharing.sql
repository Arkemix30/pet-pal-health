-- SQL Migration for Family Sharing

-- 1. Table for pet sharing relationships
CREATE TABLE pet_shares (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  pet_id UUID REFERENCES pets(id) ON DELETE CASCADE,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  access_level TEXT DEFAULT 'editor', -- 'editor' or 'viewer'
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(pet_id, user_id)
);

-- 2. Table for invitations
CREATE TABLE pet_invitations (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  pet_id UUID REFERENCES pets(id) ON DELETE CASCADE,
  inviter_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  invitee_email TEXT NOT NULL,
  token TEXT UNIQUE NOT NULL,
  status TEXT DEFAULT 'pending', -- 'pending', 'accepted', 'expired'
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 3. RLS Policies for pet_shares
ALTER TABLE pet_shares ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Owners can manage pet shares" ON pet_shares
  FOR ALL USING (
    EXISTS (SELECT 1 FROM pets WHERE pets.id = pet_id AND pets.owner_id = auth.uid())
  );

CREATE POLICY "Shared users can see their own shares" ON pet_shares
  FOR SELECT USING (user_id = auth.uid());

-- 4. RLS Update for pets
DROP POLICY IF EXISTS "Users can see own pets" ON pets; -- Adjust existing policy if needed

CREATE POLICY "Users can see pets they own or are shared with them" ON pets
  FOR SELECT USING (
    auth.uid() = owner_id OR
    EXISTS (SELECT 1 FROM pet_shares WHERE pet_id = pets.id AND user_id = auth.uid())
  );

CREATE POLICY "Owners and editors can update pets" ON pets
  FOR UPDATE USING (
    auth.uid() = owner_id OR
    EXISTS (SELECT 1 FROM pet_shares WHERE pet_id = pets.id AND user_id = auth.uid() AND access_level = 'editor')
  );

-- 5. RLS Update for health_schedules
DROP POLICY IF EXISTS "Users can manage own pet schedules" ON health_schedules;

CREATE POLICY "Users can see schedules of pets they have access to" ON health_schedules
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM pets
      WHERE pets.id = health_schedules.pet_id
      AND (pets.owner_id = auth.uid() OR EXISTS (SELECT 1 FROM pet_shares WHERE pet_id = pets.id AND user_id = auth.uid()))
    )
  );

CREATE POLICY "Users can edit schedules of pets they have editor access to" ON health_schedules
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM pets
      WHERE pets.id = health_schedules.pet_id
      AND (pets.owner_id = auth.uid() OR EXISTS (SELECT 1 FROM pet_shares WHERE pet_id = pets.id AND user_id = auth.uid() AND access_level = 'editor'))
    )
  );
