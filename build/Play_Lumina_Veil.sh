#!/usr/bin/env bash
# Lumina Veil: Sideway Stars - Standalone Release Launcher (Linux)
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PCK_FILE="$SCRIPT_DIR/LuminaVeil.pck"

if [ -f "$SCRIPT_DIR/LuminaVeil.x86_64" ]; then
    chmod +x "$SCRIPT_DIR/LuminaVeil.x86_64"
    "$SCRIPT_DIR/LuminaVeil.x86_64" --main-pack "$PCK_FILE" "$@"
elif command -v godot &> /dev/null; then
    godot --main-pack "$PCK_FILE" "$@"
elif command -v godot4 &> /dev/null; then
    godot4 --main-pack "$PCK_FILE" "$@"
else
    echo "[!] Godot 4 runtime not found."
    echo "Install Godot 4 or place the Linux runner in this folder to launch LuminaVeil.pck."
    exit 1
fi
