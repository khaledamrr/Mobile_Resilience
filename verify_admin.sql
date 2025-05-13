-- First, let's see what's in the admin table
SELECT * FROM admin;

-- Make sure we have the correct admin user
DELETE FROM admin WHERE username = 'bero@admin.com';
INSERT INTO admin (username, password) 
VALUES ('bero@admin.com', '123456789');

-- Verify the admin user exists
SELECT * FROM admin; 