#!/usr/bin/env bash
set -euo pipefail
time -p cd "$(dirname "$0")"
time -p pwd
# Validate required environment (script defect => exit 1).
/usr/bin/time -p bash -c ': "${CAPTURE_URL:?Set CAPTURE_URL.}"'
/usr/bin/time -p bash -c ': "${CAPTURE_DIR:?Set CAPTURE_DIR.}"'
/usr/bin/time -p bash -c 'echo "capturing $CAPTURE_URL into $CAPTURE_DIR"'
# Keep capture output outside source; create destination.
/usr/bin/time -p mkdir -p "$CAPTURE_DIR"
/usr/bin/time -p bash -c 'echo "RUNTIME_DIR=${RUNTIME_DIR:?Set RUNTIME_DIR.}"'
# Open the exact URL, wait for rendered content, capture desktop + mobile, close browser.
# default-capture.mjs exits 75 for transient navigation/browser infra failures, 1 for defects.
/usr/bin/time -p node "${RUNTIME_DIR:?}/scripts/default-capture.mjs"
/usr/bin/time -p ls -l "$CAPTURE_DIR/final-desktop.png" "$CAPTURE_DIR/final-mobile.png"
