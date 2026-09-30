#!/usr/bin/env bash
set -euo pipefail
time -p cd "$(dirname "$0")"
PROJECT_ROOT="$(pwd)"
STATIC_DIR="$PROJECT_ROOT"
PORT="${PORT:-3000}"
WEB_DIR="${OPENCODE_WEB_DIR:-/home/runner/work/_temp/omgithub-web}"
time -p pwd
/usr/bin/time -p test -f index.html
# Install dependencies when a package manifest exists (no-op for this static site).
/usr/bin/time -p bash -c 'if [ -f package.json ]; then if [ -f package-lock.json ]; then npm ci --no-audit --no-fund; else npm install --no-audit --no-fund; fi; else echo "no package.json, skipping install"; fi'
# Build when needed (no-op for this static site; supports npm build if present).
/usr/bin/time -p bash -c 'if [ -f package.json ] && node -e "const p=require(\"./package.json\"); process.exit(p.scripts&&p.scripts.build?0:1)"; then npm run build; else echo "no build step, serving source directory"; fi'
/usr/bin/time -p mkdir -p "$WEB_DIR"
/usr/bin/time -p python3 -c "import json; json.dump({'project':'/home/runner/work/PlayGround/PlayGround','directory':'$STATIC_DIR'}, open('$WEB_DIR/deployment-output.json','w'))"
/usr/bin/time -p cat "$WEB_DIR/deployment-output.json"
/usr/bin/time -p bash -c "echo serving $STATIC_DIR on port $PORT"
/usr/bin/time -p python3 -m http.server "$PORT" --directory "$STATIC_DIR" --bind 0.0.0.0
