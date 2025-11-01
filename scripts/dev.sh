#!/bin/bash

# Sky High Booker - Development Script
# This script helps with local development

set -e

echo "🚀 Starting Sky High Booker in development mode..."

# Check if we're in the right directory
if [ ! -f "package.json" ]; then
    echo "❌ Error: package.json not found. Please run this script from the project root."
    exit 1
fi

# Install dependencies if node_modules doesn't exist
if [ ! -d "node_modules" ]; then
    echo "📦 Installing dependencies..."
    npm install
fi

# Check if .env file exists
if [ ! -f ".env" ]; then
    echo "⚠️  Warning: .env file not found. Please create one with your Supabase credentials."
    echo "Example .env content:"
    echo "VITE_SUPABASE_URL=your_supabase_url"
    echo "VITE_SUPABASE_ANON_KEY=your_supabase_anon_key"
fi

# Start the development server
echo "🔥 Starting development server..."
npm run dev