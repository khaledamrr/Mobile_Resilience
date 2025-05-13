-- Reset and create storage policies for the products bucket
BEGIN;

-- First, disable RLS to reset everything
ALTER TABLE storage.objects DISABLE ROW LEVEL SECURITY;

-- Then enable it again
ALTER TABLE storage.objects ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Public Access" ON storage.objects;
DROP POLICY IF EXISTS "Admin Access Products Images" ON storage.objects;

-- Create a policy for public read access
CREATE POLICY "Public Access"
ON storage.objects FOR SELECT
TO public
USING (bucket_id = 'products');

-- Create a single policy for admin CRUD operations
CREATE POLICY "Admin Access Products Images"
ON storage.objects
TO authenticated
USING (
  bucket_id = 'products' 
  AND auth.email() IN (
    SELECT username FROM admin
  )
)
WITH CHECK (
  bucket_id = 'products' 
  AND auth.email() IN (
    SELECT username FROM admin
  )
);

COMMIT; 