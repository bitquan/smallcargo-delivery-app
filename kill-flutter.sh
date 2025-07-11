#!/bin/bash

# Stop all Flutter related processes
echo "Stopping all Flutter processes..."

# Kill Flutter daemon processes
pkill -f "flutter.*daemon" 2>/dev/null

# Kill Dart tooling daemon processes  
pkill -f "dartaotruntime.*dart_tooling_daemon" 2>/dev/null

# Kill DevTools processes
pkill -f "dart.*devtools" 2>/dev/null

# Kill frontend server processes
pkill -f "frontend_server_aot" 2>/dev/null

# Kill any remaining dart processes (except language server)
pkill -f "dart.*--packages.*flutter_tools.*daemon" 2>/dev/null

# Kill web server processes
fuser -k 8080/tcp 2>/dev/null || true
fuser -k 9100/tcp 2>/dev/null || true
fuser -k 9101/tcp 2>/dev/null || true

# Kill common DevTools ports
for port in 35775 36847 45901 35805 36559 45495 40721 36711 42597 42723 44021 38015 43907 38881 34439 44764; do
    fuser -k ${port}/tcp 2>/dev/null || true
done

echo "Flutter processes stopped."
echo "Remaining dart processes (language server only):"
ps aux | grep dart | grep -v grep | grep -v "kill-flutter"
