-- Create public access policy for viewing images
CREATE POLICY "Public Access"
ON storage.objects FOR SELECT
TO public
USING (bucket_id = 'products');

-- Verify storage policies
SELECT name, definition 
FROM pg_policies 
WHERE tablename = 'objects'; 