-- Get the user's ID from auth.users
WITH user_id AS (
  SELECT id FROM auth.users WHERE email = 'bero@admin.com'
)
-- Insert into admin table
INSERT INTO admin (id, username)
SELECT id, 'bero@admin.com'
FROM user_id;

-- Verify admin was added
SELECT a.*, u.email 
FROM admin a 
JOIN auth.users u ON u.id = a.id; 