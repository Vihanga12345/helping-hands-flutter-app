# 🗄️ Helping Hands Database Setup

## **SIMPLE BROWSER-ONLY SETUP**

**Your Supabase Project Details:**
- **Project Name**: Helping Hands
- **Project ID**: awdhnscowyibbbvoysfa
- **Project URL**: https://awdhnscowyibbbvoysfa.supabase.co

---

## 📋 **3-STEP SETUP PROCESS**

### **Step 1: Access Your Supabase Project**
1. Go to https://app.supabase.com
2. Open your **"Helping Hands"** project
3. Click **"SQL Editor"** in the left sidebar

### **Step 2: Create Database Schema**
1. In SQL Editor, click **"+ New Query"**
2. Copy the **entire content** from `supabase/migrations/001_initial_schema.sql`
3. Paste it and click **"RUN"** ▶️
4. ✅ **Creates all 13 tables with relationships**

### **Step 3: Add Initial Data**
1. Create **another new query** in SQL Editor
2. Copy the **entire content** from `supabase/migrations/002_seed_data.sql`
3. Paste it and click **"RUN"** ▶️
4. ✅ **Adds 30 job categories + admin user**

### **Step 4: Verify Setup**
Run this verification query:
```sql
-- Check everything is working
SELECT 'Tables Created' as status, COUNT(*) as count 
FROM information_schema.tables 
WHERE table_schema = 'public' AND table_name NOT LIKE 'pg_%';

SELECT 'Job Categories' as status, COUNT(*) as count FROM job_categories;
SELECT 'Admin User' as status, COUNT(*) as count FROM users WHERE user_type = 'admin';
```

---

## 🔧 **FLUTTER APP INTEGRATION**

### **Your Project Credentials:**
```dart
// Add these to your Flutter app's Supabase configuration
const supabaseUrl = 'https://awdhnscowyibbbvoysfa.supabase.co';
const supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImF3ZGhuc2Nvd3lpYmJidm95c2ZhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTA3NjQ3ODUsImV4cCI6MjA2NjM0MDc4NX0.2gsbjyjj82Fb6bT89XpJdlxzRwHTfu0Lw_rXwpB565g';
```

### **Service Role Key (for admin operations):**
```
eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImF3ZGhuc2Nvd3lpYmJidm95c2ZhIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1MDc2NDc4NSwiZXhwIjoyMDY2MzQwNzg1fQ.Jor4vtjbjUaLHeG9a9c04P1LA9QJ13jNJvGdMQiZjng
```

---

## 📊 **WHAT YOU GET**

### **13 Database Tables Ready:**
1. ✅ **users** - Helpers, Helpees, Admins with profiles
2. ✅ **jobs** - Job postings (private/public)
3. ✅ **job_categories** - 30 service categories
4. ✅ **job_applications** - Application system
5. ✅ **user_skills** - Helper expertise & rates
6. ✅ **ratings_reviews** - 5-star rating system
7. ✅ **payments** - Payment tracking
8. ✅ **notifications** - App notifications
9. ✅ **emergency_contacts** - Emergency contacts
10. ✅ **job_attachments** - File uploads
11. ✅ **user_documents** - Certificates/IDs
12. ✅ **user_availability** - Helper schedules
13. ✅ **job_reports** - Issue reporting

### **30 Job Categories Included:**
House Cleaning, Deep Cleaning, Gardening, Pet Care, Elderly Care, Tutoring, Tech Support, Photography, Fitness Training, Cooking, Laundry, Plumbing, Electrical Work, Painting, Moving Help, Furniture Assembly, Car Washing, Delivery Services, Event Planning, Shopping Assistance, Office Maintenance, Babysitting, Window Cleaning, Carpet Cleaning, Appliance Repair, Massage Therapy, Language Translation, Music Lessons, Art and Craft, Data Entry.

---

## 🚀 **READY TO USE!**

**Total Setup Time:** ~5 minutes
**Installation Required:** None!
**Files to Use:** Only 2 SQL files in `supabase/migrations/`

Your database is now ready for your Flutter app to connect and start building features!

---

## 🎯 **NEXT STEPS**

1. ✅ **Database Setup** - Complete
2. 🔗 **Update Flutter Config** - Use the credentials above
3. 📱 **Start Development** - Build your app features
4. 🧪 **Test Everything** - User registration, job posting, etc.

**Your Helping Hands app database is ready! 🎉** 