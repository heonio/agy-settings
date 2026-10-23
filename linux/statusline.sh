#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# Antigravity statusline.sh (Cross-platform wrapper for Linux/WSL & macOS)
# This script forwards arguments and stdin to statusline.py.
# -----------------------------------------------------------------------------

# Resolve the directory where this script (or symlink target) is located
SOURCE="${BASH_SOURCE[0]:-$0}"
while [ -h "$SOURCE" ]; do
    DIR="$(cd -P "$(dirname "$SOURCE")" && pwd)"
    SOURCE="$(readlink "$SOURCE")"
    [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE"
done
SCRIPT_DIR="$(cd -P "$(dirname "$SOURCE")" && pwd)"
PYTHON_SCRIPT="$SCRIPT_DIR/statusline.py"

if [ -f "$PYTHON_SCRIPT" ]; then
    python3 "$PYTHON_SCRIPT" "$@"
elif [ -f "$HOME/.gemini/antigravity-cli/statusline.py" ]; then
    python3 "$HOME/.gemini/antigravity-cli/statusline.py" "$@"
elif [ -f "$HOME/.gemini/statusline.py" ]; then
    python3 "$HOME/.gemini/statusline.py" "$@"
else
    # Fallback if python script is in the current working directory
    python3 "statusline.py" "$@"
fi
