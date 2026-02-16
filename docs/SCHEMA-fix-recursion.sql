-- Fix for Infinite Recursion in RLS Policies
-- Use SECURITY DEFINER function to break the RLS loop between pets and pet_shares

-- 1. Create a helper function to check pet ownership bypassing RLS
CREATE OR REPLACE FUNCTION is_pet_owner(_pet_id UUID)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  -- This runs with the permissions of the function creator (admin), bypassing RLS
  RETURN EXISTS (
    SELECT 1 FROM pets
    WHERE id = _pet_id
    AND owner_id = auth.uid()
  );
END;
$$;

-- 2. Drop existing problematic policies

-- Drop policies on pet_shares
DROP POLICY IF EXISTS "Owners can manage pet shares" ON pet_shares;

-- Drop policies on pet_invitations (similar pattern)
DROP POLICY IF EXISTS "Users can manage own invitations" ON pet_invitations;

-- 3. Recreate policies using the SECURITY DEFINER function

-- Pet Shares: Owners can manage (insert, update, delete)
CREATE POLICY "Owners can manage pet shares" ON pet_shares
  FOR ALL USING (
    is_pet_owner(pet_id)
  );

-- Pet Invitations: Owners can manage
CREATE POLICY "Users can manage own invitations" ON pet_invitations
  FOR ALL USING (
    is_pet_owner(pet_id)
  );

-- Note: The 'pets' table policies remain unchanged.
-- The loop was: pets -> pet_shares -> pets
-- Now it is: pets -> pet_shares -> is_pet_owner (stops here, no recursion)
