-- First, check if the admin exists in auth.users
SELECT * FROM auth.users WHERE email = 'bero@admin.com';

-- If no results, you need to create the user through Supabase Auth UI or API
-- Then run these commands:

-- Update admin table structure
DROP TABLE IF EXISTS admin CASCADE;
CREATE TABLE admin (
    id UUID PRIMARY KEY REFERENCES auth.users(id),
    username TEXT UNIQUE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL
);

-- Create policies for admin table
CREATE POLICY "Enable read access for authenticated users" ON admin
    FOR SELECT TO authenticated USING (true);

-- Enable RLS
ALTER TABLE admin ENABLE ROW LEVEL SECURITY; 