# Helping Hands App - Database Setup Guide

## 🗄️ **COMPREHENSIVE SUPABASE DATABASE SETUP**

This guide will help you set up the complete database for the Helping Hands app using Supabase CLI with automated migrations.

---

## 📋 **PREREQUISITES**

### 1. Install Supabase CLI
```bash
# Windows (using Chocolatey)
choco install supabase

# macOS (using Homebrew)
brew install supabase/tap/supabase

# Linux/WSL
curl -fsSL https://github.com/supabase/cli/releases/download/v1.127.4/supabase_linux_amd64.tar.gz | tar -xz && sudo mv supabase /usr/local/bin/
```

### 2. Create Supabase Project
- Go to [https://supabase.com](https://supabase.com)
- Create a new project
- Note down your:
  - **Project URL**
  - **Project Reference ID** 
  - **Service Role Key** (from Settings > API)

---

## 🚀 **AUTOMATED SETUP PROCESS**

### Step 1: Initialize Supabase in Your Project
```bash
# Navigate to your Flutter project root
cd helping_hands_app

# Login to Supabase (will open browser)
supabase login

# Link to your remote project
supabase link --project-ref YOUR_PROJECT_REFERENCE_ID
```

### Step 2: Apply Database Migrations
```bash
# Push migrations to your remote database
supabase db push

# This will automatically:
# ✅ Create all 13 tables with proper relationships
# ✅ Set up indexes for optimal performance
# ✅ Create triggers for automatic timestamp updates
# ✅ Insert 30 job categories with proper icons
# ✅ Create sample admin user
```

### Step 3: Verify Database Setup
```bash
# Check migration status
supabase migration list

# Start local development environment (optional)
supabase start

# View your database in Supabase Studio
# Local: http://localhost:54323
# Remote: https://app.supabase.com/project/YOUR_PROJECT_ID
```

---

## 📊 **DATABASE SCHEMA OVERVIEW**

### **Core Tables Created:**

#### 1. **Users** (`users`)
- Supports **3 user types**: Helper, Helpee, Admin
- **Profile info**: Name, phone, email, location, about me
- **Location data**: Latitude, longitude, address, city, district
- **Status**: Verification, active status

#### 2. **Emergency Contacts** (`emergency_contacts`)
- **Simple structure**: Name and phone only (as per app requirements)
- **One-to-many**: Each user can have multiple emergency contacts

#### 3. **Job Categories** (`job_categories`)
- **30 predefined categories**: House Cleaning, Gardening, Pet Care, etc.
- **Icon integration**: Icon names for Flutter Material Icons
- **Expandable**: Easy to add new categories

#### 4. **Jobs** (`jobs`)
- **Job types**: Private (invite specific helper) or Public (open applications)
- **Status flow**: pending → accepted → started → paused/resumed → completed
- **Comprehensive data**: Description, pricing, scheduling, location, requirements
- **Payment tracking**: Method, status, amounts

#### 5. **Job Applications** (`job_applications`)
- **For public jobs**: Helpers apply to available jobs
- **Status tracking**: pending → accepted/rejected/withdrawn
- **Unique constraint**: One application per helper per job

#### 6. **User Skills** (`user_skills`)
- **Helper expertise**: Links helpers to job categories
- **Experience tracking**: Years of experience, skill level, hourly rates
- **Availability**: Can toggle skills on/off

#### 7. **Ratings & Reviews** (`ratings_reviews`)
- **Bidirectional**: Helper ↔ Helpee ratings
- **Job-linked**: Each rating tied to specific completed job
- **5-star system**: With optional text reviews

#### 8. **Payments** (`payments`)
- **Complete tracking**: Amount, method, status, fees
- **Platform integration**: Ready for payment gateway integration
- **Earnings calculation**: Platform fee and helper earnings

#### 9. **Notifications** (`notifications`)
- **Multi-type**: Job applications, payments, system notifications
- **Deep linking**: Action URLs for navigation
- **Read status**: Track read/unread notifications

#### 10. **Additional Supporting Tables:**
- **Job Attachments**: Files uploaded with jobs
- **User Documents**: Certificates, IDs, portfolios
- **User Availability**: Helper working hours
- **Job Reports**: Issue reporting system

---

## 🔧 **FLUTTER INTEGRATION**

### Step 1: Update Environment Variables
Create `.env` file in your Flutter project:
```env
SUPABASE_URL=https://your-project-ref.supabase.co
SUPABASE_ANON_KEY=your-anon-key
SUPABASE_SERVICE_ROLE_KEY=your-service-role-key
```

### Step 2: Update Supabase Configuration
The database is now ready to integrate with your Flutter app using the existing Supabase client configuration.

### Step 3: User Authentication Integration
The schema is designed to work with Supabase Auth:
- **Email/Phone registration**: Automatic user creation in `users` table
- **Role assignment**: During registration, assign user_type (helper/helpee)
- **Profile completion**: Additional info added after authentication

---

## 📱 **APP FUNCTIONALITY MAPPING**

### **Helper Features Supported:**
- ✅ **Profile Management**: Complete profile with skills, documents, availability
- ✅ **Job Applications**: Apply to public jobs or receive private invitations
- ✅ **Job Tracking**: Full status flow from pending to completed
- ✅ **Earnings**: Track payments and platform fees
- ✅ **Ratings System**: Receive and give ratings

### **Helpee Features Supported:**
- ✅ **Job Posting**: Create private or public job requests
- ✅ **Helper Search**: Find helpers by category, location, ratings
- ✅ **Job Management**: Track job progress and completion
- ✅ **Payment Processing**: Handle payments and receipts
- ✅ **Review System**: Rate helpers after job completion

### **Admin Features Supported:**
- ✅ **User Management**: Monitor all users and verifications
- ✅ **Job Oversight**: View all jobs and handle disputes
- ✅ **Report Handling**: Manage issue reports and resolutions
- ✅ **Platform Analytics**: Access to all data for insights

---

## 🔍 **TESTING THE DATABASE**

### Sample Data Queries:
```sql
-- View all job categories
SELECT * FROM job_categories ORDER BY name;

-- Check admin user
SELECT * FROM users WHERE user_type = 'admin';

-- View table relationships
\d+ users
\d+ jobs
\d+ job_applications
```

### Performance Verification:
```sql
-- Check indexes
SELECT indexname, tablename FROM pg_indexes WHERE schemaname = 'public';

-- Verify constraints
SELECT conname, contype FROM pg_constraint WHERE connamespace = 'public'::regnamespace;
```

---

## ⚡ **NEXT STEPS**

1. **✅ Database Setup Complete** - All tables created and ready
2. **🔄 Flutter Integration** - Connect your app to the database
3. **🔐 Authentication Setup** - Configure user registration/login
4. **📱 App Development** - Build features using the database
5. **🚀 Deployment** - Production deployment ready

---

## 🆘 **TROUBLESHOOTING**

### Common Issues:

#### Migration Errors:
```bash
# Reset and retry
supabase db reset
supabase db push
```

#### Permission Issues:
```bash
# Check project linking
supabase projects list
supabase link --project-ref YOUR_PROJECT_ID
```

#### Local Development:
```bash
# Start fresh local environment
supabase stop
supabase start
```

---

## 📞 **SUPPORT**

- **Database Issues**: Check migration files in `supabase/migrations/`
- **Schema Questions**: Review table definitions in `001_initial_schema.sql`
- **Integration Help**: Check Supabase Flutter documentation

**🎉 Your Helping Hands database is now fully set up and ready for development!** 