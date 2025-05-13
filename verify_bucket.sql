-- Check if products bucket exists
SELECT name, owner, public
FROM storage.buckets
WHERE name = 'products';

-- If it doesn't exist, this will create it
INSERT INTO storage.buckets (id, name, public)
SELECT 'products', 'products', false
WHERE NOT EXISTS (
    SELECT 1 FROM storage.buckets WHERE name = 'products'
); 