-- Create products table if it doesn't exist
CREATE TABLE IF NOT EXISTS products (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  name TEXT NOT NULL,
  description TEXT,
  price DECIMAL(10,2) NOT NULL,
  stock INTEGER NOT NULL DEFAULT 0,
  category TEXT,
  image_url TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL
);

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Anyone can view products" ON products;
DROP POLICY IF EXISTS "Only admin can insert products" ON products;
DROP POLICY IF EXISTS "Only admin can update products" ON products;
DROP POLICY IF EXISTS "Only admin can delete products" ON products;

-- Enable RLS
ALTER TABLE products ENABLE ROW LEVEL SECURITY;

-- Create policies
CREATE POLICY "Anyone can view products" 
ON products FOR SELECT 
TO authenticated, anon
USING (true);

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