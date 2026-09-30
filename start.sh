#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
/usr/bin/time -p pwd
PROJECT_ROOT="$(/usr/bin/time -p pwd)"
STATIC_DIR="$PROJECT_ROOT/car-parking2-site"
/usr/bin/time -p test -f "$STATIC_DIR/index.html"
if [ -f "$PROJECT_ROOT/package.json" ]; then
  /usr/bin/time -p npm install --no-audit --no-fund
  if grep -q '"build"' "$PROJECT_ROOT/package.json"; then
    /usr/bin/time -p npm run build
  fi
else
  echo "static site: no package.json, skipping install/build"
fi
PORT="${PORT:-3000}"
WEB_DIR="${OPENCODE_WEB_DIR:-/home/runner/work/_temp/omgithub-web}"
/usr/bin/time -p mkdir -p "$WEB_DIR"
/usr/bin/time -p bash -c 'printf "{\"project\":\"/home/runner/work/PlayGround/PlayGround\",\"directory\":\"%s\"}" "$0" > "$1/deployment-output.json"' "$STATIC_DIR" "$WEB_DIR"
cat "$WEB_DIR/deployment-output.json"; echo
exec /usr/bin/time -p python3 -m http.server "$PORT" --directory "$STATIC_DIR" --bind 0.0.0.0
