-- First, drop all dependent policies
DROP POLICY IF EXISTS "Admin Access" ON storage.objects;
DROP POLICY IF EXISTS "Admin Insert Products Images" ON storage.objects;
DROP POLICY IF EXISTS "Admin Update Products Images" ON storage.objects;
DROP POLICY IF EXISTS "Admin Delete Products Images" ON storage.objects;
DROP POLICY IF EXISTS "Only admin can insert products" ON products;
DROP POLICY IF EXISTS "Only admin can update products" ON products;
DROP POLICY IF EXISTS "Only admin can delete products" ON products;

-- Now drop and recreate the admin table
DROP TABLE IF EXISTS admin CASCADE;

-- Create admin table with password field
CREATE TABLE admin (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    username TEXT UNIQUE NOT NULL,
    password TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL
);

-- Insert the admin user with password
INSERT INTO admin (username, password) 
VALUES ('bero@admin.com', '123456789');

-- Recreate the policies for products table
CREATE POLICY "Only admin can insert products" 
ON products FOR INSERT 
TO authenticated
WITH CHECK (
  EXISTS (
    SELECT 1 FROM admin 
    WHERE admin.username = auth.email()
  )
);

CREATE POLICY "Only admin can update products" 
ON products FOR UPDATE 
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM admin 
    WHERE admin.username = auth.email()
  )
)
WITH CHECK (
  EXISTS (
    SELECT 1 FROM admin 
    WHERE admin.username = auth.email()
  )
);

CREATE POLICY "Only admin can delete products" 
ON products FOR DELETE 
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM admin 
    WHERE admin.username = auth.email()
  )
);

-- Create storage policies
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

-- Verify the admin user exists
SELECT * FROM admin; 