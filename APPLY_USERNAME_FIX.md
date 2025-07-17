# APPLY USERNAME CONSTRAINT FIX - URGENT

## Steps to Fix the Username Constraint Issue:

### 1. Go to Supabase Dashboard
- Open your browser and go to [Supabase](https://supabase.com)
- Login and select your Helping Hands project
- Click on "SQL Editor" in the left sidebar

### 2. Run the Migration SQL
Copy and paste the entire content of `supabase/migrations/024_fix_username_constraints.sql` into the SQL Editor and click "Run"

### 3. Verify the Fix
After running the migration, test by:
- Try registering a helpee with username "testuser"
- Try registering a helper with the same username "testuser"
- Both should work without errors

### 4. What This Fix Does:
- Removes the global unique constraint on username
- Creates composite unique constraints (username + user_type)
- Updates the `create_user_with_auth` function to handle the new constraints
- Allows same usernames for different user types (helpee vs helper)
- Maintains email uniqueness across all user types

### 5. Expected Result:
- Username "Malithi" can exist for both helpee and helper user types
- Same email cannot be used for different user types (as designed)
- Registration should work without constraint violations

## Alternative: Direct SQL Commands
If you prefer, you can run these key commands directly:

```sql
-- Drop existing unique constraints
ALTER TABLE users DROP CONSTRAINT IF EXISTS users_username_key;
ALTER TABLE user_authentication DROP CONSTRAINT IF EXISTS user_authentication_username_key;

-- Create composite unique constraints
ALTER TABLE users ADD CONSTRAINT users_username_user_type_key UNIQUE (username, user_type);
ALTER TABLE user_authentication ADD CONSTRAINT user_authentication_username_user_type_key UNIQUE (username, user_type);
```

After applying this fix, the registration should work properly! 