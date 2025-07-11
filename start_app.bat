@echo off
echo Starting Small Cargo App Development Environment...
echo.

echo [1/3] Starting Development Server on port 8090...
start "Flutter Dev Server" cmd /c "cd /d \"%~dp0\" && flutter run -d web-server --web-port 8090"

echo [2/3] Building Production Version...
flutter build web --release

echo [3/3] Starting Production Server on port 8091...
start "Production Server" cmd /c "cd /d \"%~dp0build\web\" && python -m http.server 8091"

echo.
echo ====================================
echo  Small Cargo App is now running!
echo ====================================
echo Development (Hot Reload): http://localhost:8090
echo Production (Optimized):   http://localhost:8091
echo.
echo Admin Quick Login Credentials:
echo Email: testadmin@smallcargo.com
echo Password: Reckless@13
echo.
echo Press any key to exit...
pause >nul
