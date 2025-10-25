# Supabase Configuration Setup

This guide will help you configure your Daily Ritual app to connect to your Supabase project.

## Prerequisites

- A Supabase account at [https://supabase.com](https://supabase.com)
- A Supabase project created

## Step 1: Get Your Supabase Credentials

1. Go to [https://app.supabase.com](https://app.supabase.com)
2. Select your project (or create a new one)
3. Go to **Project Settings** (gear icon in sidebar)
4. Click on **API** in the settings menu

You'll need two pieces of information:
- **Project URL** (e.g., `https://xxxxx.supabase.co`)
- **anon public** key (the long JWT token under "Project API keys")

## Step 2: Configure iOS App

Open `/DailyRitualSwiftiOS/Your Daily Dose/Config.swift` and replace the placeholder values:

```swift
struct Config {
    // Replace these with your actual values
    static let supabaseURL = "https://YOUR-PROJECT-REF.supabase.co"
    static let supabaseAnonKey = "YOUR-ANON-KEY-HERE"
    
    // ... rest of config
}
```

### Example:
```swift
static let supabaseURL = "https://abcdefgh12345678.supabase.co"
static let supabaseAnonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
```

## Step 3: Configure Backend

Create a `.env` file in `/DailyRitualBackend/`:

```bash
cd DailyRitualBackend
cp .env.example .env  # If you have an example file
```

Add your Supabase credentials to `.env`:

```env
SUPABASE_URL=https://YOUR-PROJECT-REF.supabase.co
SUPABASE_SERVICE_ROLE_KEY=YOUR-SERVICE-ROLE-KEY
SUPABASE_ANON_KEY=YOUR-ANON-KEY
```

**Important:** 
- The **service role key** is different from the anon key
- Find it in Project Settings > API under "service_role" (keep this secret!)
- Never commit `.env` files to git

## Step 4: Set Up Database Schema

Your Supabase project needs the proper database tables. Run the migrations:

```bash
cd DailyRitualBackend/supabase
supabase db push
```

Or manually run the migration files in order:
1. `migrations/20240101000000_initial_schema.sql`
2. `migrations/20240101000001_rls_policies.sql`
3. `migrations/20240101000002_add_planned_notes.sql`
4. `migrations/20240101000003_training_plans_refactor.sql`

## Step 5: Deploy Edge Functions (Optional)

If you're using Supabase Edge Functions:

```bash
cd DailyRitualBackend/supabase
supabase functions deploy generate-affirmation
supabase functions deploy generate-insights
```

## Step 6: Test the Connection

### Test iOS App:
1. Build and run the app in Xcode
2. Try signing in with a test account
3. If you see connection errors, double-check your credentials

### Test Backend:
```bash
cd DailyRitualBackend
npm run dev
curl http://localhost:3000/health
```

## Troubleshooting

### "Server with specified hostname could not be found"
- ✅ Your Supabase URL is incorrect
- Check that it matches exactly from Supabase dashboard
- Make sure there's no trailing slash

### "Invalid API key" or 401 errors
- ✅ Your anon key is incorrect or expired
- Copy the key again from Supabase dashboard
- Make sure you're using the **anon** key in the iOS app (not service_role)

### "Table or view not found" errors
- ✅ Database migrations haven't been run
- Follow Step 4 to set up your database schema

### Backend can't connect to Supabase
- ✅ Check your `.env` file exists in DailyRitualBackend/
- ✅ Make sure `SUPABASE_URL` and `SUPABASE_SERVICE_ROLE_KEY` are set
- ✅ Restart your backend server after changing .env

## Security Best Practices

✅ **DO:**
- Use the anon key in your iOS app (client-side)
- Use the service_role key in your backend (server-side)
- Keep service_role key in .env files (gitignored)
- Enable Row Level Security (RLS) on all tables

❌ **DON'T:**
- Commit .env files to git
- Use service_role key in client apps
- Share service_role key publicly
- Disable RLS on production tables

## Need Help?

- Supabase Docs: https://supabase.com/docs
- Backend README: `/DailyRitualBackend/README.md`
- Setup Guide: `/docs/SETUP_GUIDE.md`

---

**Quick Reference:**

| Config File | Location | Use Case |
|-------------|----------|----------|
| `Config.swift` | iOS app | Client-side credentials |
| `.env` | Backend root | Server-side credentials |
| `config.toml` | Backend/supabase | Supabase CLI config |

