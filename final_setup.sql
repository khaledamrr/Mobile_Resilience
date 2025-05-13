-- First, clean everything up
DROP POLICY IF EXISTS "Anyone can view products" ON products;
DROP POLICY IF EXISTS "Only admin can insert products" ON products;
DROP POLICY IF EXISTS "Only admin can update products" ON products;
DROP POLICY IF EXISTS "Only admin can delete products" ON products;
DROP POLICY IF EXISTS "Admin can view their own record" ON admin;
DROP TABLE IF EXISTS products CASCADE;
DROP TABLE IF EXISTS admin CASCADE;

-- Create admin table (super simple)
CREATE TABLE admin (
    id UUID PRIMARY KEY REFERENCES auth.users(id),
    email TEXT UNIQUE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL
);

-- Create products table
CREATE TABLE products (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    name TEXT NOT NULL,
    description TEXT,
    price DECIMAL(10,2) NOT NULL,
    stock INTEGER NOT NULL DEFAULT 0,
    category TEXT,
    image_url TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL
);

-- Enable RLS
ALTER TABLE products ENABLE ROW LEVEL SECURITY;
ALTER TABLE admin ENABLE ROW LEVEL SECURITY;

-- Create simple policies
CREATE POLICY "Public products view" 
ON products FOR SELECT 
TO authenticated, anon
USING (true);

CREATE POLICY "Admin products insert" 
ON products FOR INSERT 
TO authenticated
WITH CHECK (
    EXISTS (
        SELECT 1 FROM admin 
        WHERE admin.id = auth.uid()
    )
);

CREATE POLICY "Admin products update" 
ON products FOR UPDATE 
TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM admin 
        WHERE admin.id = auth.uid()
    )
);

CREATE POLICY "Admin products delete" 
ON products FOR DELETE 
TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM admin 
        WHERE admin.id = auth.uid()
    )
);

CREATE POLICY "Admin table access" 
ON admin FOR ALL 
TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM admin 
        WHERE admin.id = auth.uid()
    )
);

-- Create storage policies for admin
CREATE POLICY "Admin storage access"
ON storage.objects
FOR ALL
TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM admin 
        WHERE admin.id = auth.uid()
    )
)
WITH CHECK (
    EXISTS (
        SELECT 1 FROM admin 
        WHERE admin.id = auth.uid()
    )
);

-- Verify everything is set up
SELECT * FROM admin;
SELECT * FROM pg_policies WHERE tablename = 'admin' OR tablename = 'products'; 