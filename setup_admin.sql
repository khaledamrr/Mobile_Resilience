-- Drop everything and start fresh
DROP TABLE IF EXISTS admin CASCADE;
DROP TABLE IF EXISTS products CASCADE;

-- Create a simple admin table
CREATE TABLE admin (
    email TEXT PRIMARY KEY,
    password TEXT NOT NULL
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

-- Insert admin user
INSERT INTO admin (email, password) 
VALUES ('bero@admin.com', '123456789');

-- Enable RLS
ALTER TABLE products ENABLE ROW LEVEL SECURITY;
ALTER TABLE admin ENABLE ROW LEVEL SECURITY;

-- Create policies for products
CREATE POLICY "Anyone can view products" 
ON products FOR SELECT 
TO authenticated, anon
USING (true);

CREATE POLICY "Only admin can insert products" 
ON products FOR INSERT 
TO authenticated
WITH CHECK (
    EXISTS (
        SELECT 1 FROM admin WHERE email = auth.email()
    )
);

CREATE POLICY "Only admin can update products" 
ON products FOR UPDATE 
TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM admin WHERE email = auth.email()
    )
)
WITH CHECK (
    EXISTS (
        SELECT 1 FROM admin WHERE email = auth.email()
    )
);

CREATE POLICY "Only admin can delete products" 
ON products FOR DELETE 
TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM admin WHERE email = auth.email()
    )
);

-- Create policy for admin table
CREATE POLICY "Admin can view their own record"
ON admin FOR SELECT
TO authenticated
USING (email = auth.email());

-- Verify setup
SELECT * FROM admin; 