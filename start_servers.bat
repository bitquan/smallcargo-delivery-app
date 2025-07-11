@echo off
echo Starting Small Cargo Development Environment...
echo.

:: Start development server
echo [1/3] Starting development server on port 8085...
start "Dev Server" cmd /k "cd /d \"%~dp0\" && flutter run -d web-server --web-port 8085"

:: Build production
echo [2/3] Building production version...
flutter build web --release

:: Start production server
echo [3/3] Starting production server on port 8080...
start "Production Server" cmd /k "cd /d \"%~dp0build\web\" && python -m http.server 8080"

echo.
echo ========================================
echo Development Environment Ready!
echo ========================================
echo Development (Hot Reload): http://localhost:8085
echo Production (Optimized):   http://localhost:8080
echo.
echo Press any key to continue...
pause >nul
