-- Check all storage policies
SELECT tablename, policyname, permissive, roles, cmd, qual, with_check
FROM pg_policies 
WHERE schemaname = 'storage' 
  AND tablename = 'objects';

-- Check all product policies
SELECT tablename, policyname, permissive, roles, cmd, qual, with_check
FROM pg_policies 
WHERE tablename = 'products';

-- Check admin users
SELECT * FROM admin;

-- Check storage buckets
SELECT * FROM storage.buckets; 