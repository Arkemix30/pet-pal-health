-- Security Verification: Ensure only owners can soft-delete
-- Run this in Supabase SQL Editor to audit your current policies

-- 1. Check current policies for 'pets' table
SELECT * FROM pg_policies WHERE tablename = 'pets';

-- 2. Refined Policy (Optional/Recommended)
-- If you want to strictly prevent editors from setting is_deleted = true,
-- you can split the update policy into two, or use a TRIGGER.
-- For now, the app handles the restriction. 

-- 3. Verify soft delete status
-- This query helps you see which pets are currently "archived"
SELECT id, name, owner_id, is_deleted, updated_at 
FROM pets 
WHERE is_deleted = true;
