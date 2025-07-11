#!/bin/bash

# Production Build and Deployment Script for Small Cargo Delivery App

echo "🚀 Small Cargo Delivery App - Production Build & Deployment"
echo "==========================================================="
echo ""

# Step 1: Clean previous builds
echo "🧹 Cleaning previous builds..."
flutter clean
flutter pub get
echo "✅ Project cleaned and dependencies updated"
echo ""

# Step 2: Run tests
echo "🧪 Running tests..."
flutter test
if [ $? -ne 0 ]; then
    echo "❌ Tests failed. Aborting deployment."
    exit 1
fi
echo "✅ All tests passed"
echo ""

# Step 3: Build for production
echo "🔨 Building for production..."
flutter build web --release \
    --web-renderer canvaskit \
    --dart-define=FLUTTER_WEB_USE_SKIA=true \
    --no-source-maps \
    --tree-shake-icons \
    --base-href="/" \
    --pwa-strategy=offline-first

if [ $? -ne 0 ]; then
    echo "❌ Production build failed"
    exit 1
fi
echo "✅ Production build completed"
echo ""

# Step 4: Optimize build
echo "⚡ Optimizing build..."

# Create optimized manifest
cat > build/web/manifest.json << EOF
{
  "name": "Small Cargo Delivery",
  "short_name": "SmallCargo",
  "description": "Professional delivery and logistics management platform",
  "start_url": "/",
  "display": "standalone",
  "background_color": "#000000",
  "theme_color": "#FFEB3B",
  "orientation": "portrait-primary",
  "icons": [
    {
      "src": "icons/Icon-192.png",
      "sizes": "192x192",
      "type": "image/png",
      "purpose": "maskable any"
    },
    {
      "src": "icons/Icon-512.png",
      "sizes": "512x512",
      "type": "image/png",
      "purpose": "maskable any"
    }
  ],
  "categories": ["business", "logistics", "delivery"],
  "lang": "en",
  "scope": "/",
  "prefer_related_applications": false
}
EOF

# Create robots.txt
cat > build/web/robots.txt << EOF
User-agent: *
Allow: /

Sitemap: https://smallcargo.app/sitemap.xml
EOF

# Create .htaccess for Apache servers
cat > build/web/.htaccess << EOF
# Enable compression
<IfModule mod_deflate.c>
    AddOutputFilterByType DEFLATE text/plain
    AddOutputFilterByType DEFLATE text/html
    AddOutputFilterByType DEFLATE text/xml
    AddOutputFilterByType DEFLATE text/css
    AddOutputFilterByType DEFLATE application/xml
    AddOutputFilterByType DEFLATE application/xhtml+xml
    AddOutputFilterByType DEFLATE application/rss+xml
    AddOutputFilterByType DEFLATE application/javascript
    AddOutputFilterByType DEFLATE application/x-javascript
    AddOutputFilterByType DEFLATE application/dart
</IfModule>

# Set cache headers
<IfModule mod_expires.c>
    ExpiresActive on
    ExpiresByType text/css "access plus 1 year"
    ExpiresByType application/javascript "access plus 1 year"
    ExpiresByType image/png "access plus 1 year"
    ExpiresByType image/jpg "access plus 1 year"
    ExpiresByType image/jpeg "access plus 1 year"
    ExpiresByType image/gif "access plus 1 year"
    ExpiresByType image/svg+xml "access plus 1 year"
</IfModule>

# Flutter web routing
RewriteEngine On
RewriteCond %{REQUEST_FILENAME} !-f
RewriteCond %{REQUEST_FILENAME} !-d
RewriteRule ^(.*)$ /index.html [QSA,L]
EOF

echo "✅ Build optimization completed"
echo ""

# Step 5: Generate deployment info
echo "📋 Generating deployment information..."

BUILD_DATE=$(date '+%Y-%m-%d %H:%M:%S')
BUILD_HASH=$(git rev-parse --short HEAD 2>/dev/null || echo "unknown")
BUILD_SIZE=$(du -sh build/web | cut -f1)

cat > build/web/build-info.json << EOF
{
  "buildDate": "$BUILD_DATE",
  "buildHash": "$BUILD_HASH",
  "buildSize": "$BUILD_SIZE",
  "version": "1.0.0",
  "environment": "production"
}
EOF

echo "✅ Deployment information generated"
echo ""

# Step 6: Display deployment options
echo "🌐 Deployment Options:"
echo "======================"
echo ""
echo "1. 🔥 Firebase Hosting (Recommended)"
echo "   Command: firebase deploy --only hosting"
echo "   Benefits: CDN, SSL, easy custom domains"
echo ""
echo "2. 📦 Vercel"
echo "   Command: vercel --prod"
echo "   Benefits: Automatic deployments, edge functions"
echo ""
echo "3. 🌊 Netlify"
echo "   Command: netlify deploy --prod --dir=build/web"
echo "   Benefits: Form handling, serverless functions"
echo ""
echo "4. ☁️ Custom Hosting"
echo "   Upload contents of build/web/ to your web server"
echo "   Configure web server for SPA routing"
echo ""

echo "📊 Build Summary:"
echo "=================="
echo "Build Date: $BUILD_DATE"
echo "Build Hash: $BUILD_HASH"
echo "Build Size: $BUILD_SIZE"
echo "Output Directory: build/web/"
echo ""

echo "🎉 Production build ready for deployment!"
echo "⚠️  Remember to:"
echo "   • Set up environment variables"
echo "   • Configure Firebase security rules"
echo "   • Set up custom domain and SSL"
echo "   • Configure monitoring and analytics"
