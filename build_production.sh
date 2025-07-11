#!/bin/bash

echo "🚀 Small Cargo - Production Build & Deployment"
echo "=============================================="

# Step 1: Clean the project
echo "🧹 Cleaning project..."
flutter clean

# Step 2: Get dependencies
echo "📦 Getting dependencies..."
flutter pub get

# Step 3: Build for web production
echo "🏗️ Building for web production..."
flutter build web --release

# Step 4: Check build output
echo "📊 Build completed! Files are in build/web/"
ls -la build/web/

echo ""
echo "✅ Production build completed successfully!"
echo ""
echo "📁 Deploy these files to your web server:"
echo "   • build/web/ (entire directory)"
echo ""
echo "🌐 For quick deployment:"
echo "   • Firebase Hosting: firebase deploy"
echo "   • Netlify: drag build/web folder to netlify.com/drop"
echo "   • GitHub Pages: copy build/web/* to gh-pages branch"
echo "   • AWS S3: sync build/web/ to S3 bucket"
echo ""
echo "🎯 Your app is ready for production deployment!"
