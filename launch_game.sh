#!/usr/bin/env bash
# Lumina Veil: Sideway Stars - Linux Launcher
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if command -v godot &> /dev/null; then
    godot --path "$SCRIPT_DIR" "$@"
elif command -v godot4 &> /dev/null; then
    godot4 --path "$SCRIPT_DIR" "$@"
else
    echo "[!] Godot 4 executable not found in PATH."
    echo "Please install Godot 4 (e.g. 'sudo apt install godot' or download the Godot 4 binary) and ensure 'godot' is in your PATH."
    exit 1
fi
