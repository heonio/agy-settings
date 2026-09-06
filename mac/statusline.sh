#!/bin/zsh
# -----------------------------------------------------------------------------
# Antigravity statusline.sh (Zsh wrapper for macOS)
# This script forwards arguments and stdin to statusline.py.
# -----------------------------------------------------------------------------

# Resolve the directory where this script (or symlink target) is located
SCRIPT_DIR="$(cd "$(dirname "${0:A}")" && pwd)"
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

