-- Fix: Missing updated_at column on pets table
-- Run this in Supabase SQL Editor

-- 1. Check and add updated_at column if it's missing (idempotent)
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'pets' AND column_name = 'updated_at'
  ) THEN
    ALTER TABLE pets ADD COLUMN updated_at TIMESTAMPTZ DEFAULT NOW();
  END IF;
END $$;

-- 2. Verify or Re-apply the trigger
-- Drop first to ensure a clean state
DROP TRIGGER IF EXISTS update_pets_updated_at ON pets;

-- Create the trigger again
CREATE TRIGGER update_pets_updated_at 
BEFORE UPDATE ON pets
FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
