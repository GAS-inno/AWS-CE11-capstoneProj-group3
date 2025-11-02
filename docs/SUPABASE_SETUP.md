# Sky High Booker - Supabase Setup Guide

## 🚀 Quick Setup

### 1. Create Supabase Project
1. Go to [supabase.com](https://supabase.com/)
2. Click "New Project"
3. Choose your organization
4. Fill in project details:
   - **Name**: sky-high-booker
   - **Database Password**: Generate a secure password
   - **Region**: Choose closest to your users
5. Click "Create new project"

### 2. Get Your Credentials
After project creation (takes ~2 minutes):
1. Go to **Settings** → **API**
2. Copy these values:
   - **Project URL**: `https://xxx.supabase.co`
   - **Anon/Public Key**: `eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...`

### 3. Set Up Database Tables
Go to **SQL Editor** and run this script:

```sql
-- Enable RLS (Row Level Security)
alter table if exists public.profiles enable row level security;
alter table if exists public.bookings enable row level security;

-- Create profiles table
create table if not exists public.profiles (
  id uuid references auth.users on delete cascade primary key,
  full_name text,
  phone text,
  date_of_birth date,
  passport_number text,
  frequent_flyer_number text,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  updated_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- Create bookings table
create table if not exists public.bookings (
  id uuid default gen_random_uuid() primary key,
  user_id uuid references auth.users on delete cascade not null,
  flight_number text not null,
  departure_airport text not null,
  arrival_airport text not null,
  departure_time text not null,
  arrival_time text not null,
  departure_date date not null,
  passengers integer default 1,
  seats text[] default array[]::text[],
  base_price decimal(10,2) not null,
  seat_price decimal(10,2) default 0,
  total_price decimal(10,2) not null,
  currency text default 'USD',
  status text default 'confirmed',
  booking_reference text not null,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  updated_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- RLS Policies for profiles
create policy "Users can view own profile" 
  on profiles for select 
  using (auth.uid() = id);

create policy "Users can update own profile" 
  on profiles for update 
  using (auth.uid() = id);

create policy "Users can insert own profile" 
  on profiles for insert 
  with check (auth.uid() = id);

-- RLS Policies for bookings
create policy "Users can view own bookings" 
  on bookings for select 
  using (auth.uid() = user_id);

create policy "Users can insert own bookings" 
  on bookings for insert 
  with check (auth.uid() = user_id);

create policy "Users can update own bookings" 
  on bookings for update 
  using (auth.uid() = user_id);

-- Create function for booking reference generation
create or replace function generate_booking_reference()
returns text
language sql
as $$
  select 'SW' || upper(substring(gen_random_uuid()::text, 1, 6));
$$;
```

### 4. Configure Your Application

#### For Local Development:
```bash
# Create .env file
VITE_SUPABASE_URL=https://your-project-id.supabase.co
VITE_SUPABASE_PUBLISHABLE_KEY=your-anon-key
```

#### For Docker:
```bash
docker run -d -p 3000:80 \
  -e VITE_SUPABASE_URL="https://your-project-id.supabase.co" \
  -e VITE_SUPABASE_PUBLISHABLE_KEY="your-anon-key" \
  --name sky-high-booker sky-high-booker:fixed
```

## 🔒 Security Notes
- **Never commit** your actual Supabase keys to Git
- Use environment variables for all deployments
- The anon key is safe to use in frontend applications
- RLS policies protect your data at the database level

## 🧪 Test Your Setup
1. Start your application with real credentials
2. Try to register a new account
3. Check if you receive a confirmation email
4. Log in with your credentials
5. Test booking functionality

Your authentication and booking features will now work correctly! 🎉