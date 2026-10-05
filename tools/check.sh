#!/bin/sh
# Loads every script and runs the smoke test; prints only errors.
cd "$(dirname "$0")/.."
timeout 150 ${GODOT:-godot} --headless --path . -s tools/smoke.gd 2>&1 | grep -v '^\s*$' | grep -E "ERROR|level |SMOKE|Parse|at:" | head -${1:-40}
