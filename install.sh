#!/bin/bash

set -e


echo "🏝️  Rounded Islands — Rounded UI Installer for macOS/Linux"
echo "==========================================================="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if code command is available
if ! command -v code &> /dev/null; then
    echo -e "${RED}❌ Error: VS Code CLI (code) not found!${NC}"
    echo "Please install VS Code and make sure 'code' command is in your PATH."
    echo "You can do this by:"
    echo "  1. Open VS Code"
    echo "  2. Press Cmd+Shift+P (macOS) or Ctrl+Shift+P (Linux)"
    echo "  3. Type 'Shell Command: Install code command in PATH'"
    exit 1
fi

echo -e "${GREEN}✓ VS Code CLI found${NC}"

# Get the directory where this script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

echo ""
echo "🔧 Step 1: Installing extensions..."
if code --install-extension subframe7536.custom-ui-style --force; then
    echo -e "${GREEN}✓ Custom UI Style extension installed${NC}"
else
    echo -e "${YELLOW}⚠️  Could not install Custom UI Style extension automatically${NC}"
    echo "   Please install it manually from the Extensions marketplace"
fi

if code --install-extension beardedbear.beardedicons --force; then
    echo -e "${GREEN}✓ Bearded Icons extension installed${NC}"
else
    echo -e "${YELLOW}⚠️  Could not install Bearded Icons extension automatically${NC}"
    echo "   Please install it manually from the Extensions marketplace"
fi

echo ""
echo "⚙️  Step 2: Applying rounded UI settings..."
SETTINGS_DIR="$HOME/.config/Code/User"
if [[ "$OSTYPE" == "darwin"* ]]; then
    SETTINGS_DIR="$HOME/Library/Application Support/Code/User"
fi

mkdir -p "$SETTINGS_DIR"
SETTINGS_FILE="$SETTINGS_DIR/settings.json"

# Backup existing settings if they exist
if [ -f "$SETTINGS_FILE" ]; then
    BACKUP_FILE="$SETTINGS_FILE.pre-rounded-islands"
    cp "$SETTINGS_FILE" "$BACKUP_FILE"
    echo -e "${YELLOW}⚠️  Existing settings.json backed up to:${NC}"
    echo "   $BACKUP_FILE"
    echo "   You can restore your old settings from this file if needed."
fi

# Merge rounded UI settings into existing settings using Python
SCRIPT_DIR="$SCRIPT_DIR" SETTINGS_FILE="$SETTINGS_FILE" python3 -c '
import json, os, re

user_path = os.environ["SETTINGS_FILE"]
src_path = os.path.join(os.environ["SCRIPT_DIR"], "settings.json")

user = {}
if os.path.exists(user_path):
    try:
        raw = open(user_path).read()
        raw = re.sub(r"^\s*//.*$", "", raw, flags=re.MULTILINE)
        raw = re.sub(r",\s*([\]}])", r"\1", raw)
        user = json.loads(raw)
    except Exception:
        print("Warning: Could not parse existing settings.json, starting fresh")
        user = {}

raw = open(src_path).read()
raw = re.sub(r"^\s*//.*$", "", raw, flags=re.MULTILINE)
raw = re.sub(r",\s*([\]}])", r"\1", raw)
src = json.loads(raw)

for key, value in src.items():
    if key.startswith("//"):
        continue
    if key == "custom-ui-style.stylesheet" and isinstance(value, dict):
        user[key] = value
    elif key == "workbench.colorCustomizations" and isinstance(value, dict):
        if not isinstance(user.get(key), dict):
            user[key] = {}
        user[key].update(value)
    else:
        user[key] = value

with open(user_path, "w") as f:
    json.dump(user, f, indent=2)
    f.write("\n")
'
echo -e "${GREEN}✓ Rounded UI settings merged into your config${NC}"

echo ""
echo "🚀 Step 3: Reloading VS Code..."

if [[ "$OSTYPE" == "darwin"* ]]; then
    osascript -e 'display notification "Rounded UI installed successfully!" with title "🏝️ Rounded Islands"' 2>/dev/null || true
fi

code --reload-window 2>/dev/null || code . 2>/dev/null || true

echo ""
echo -e "${GREEN}Done! 🏝️${NC}"
echo ""
echo -e "${YELLOW}📝 Notes:${NC}"
echo "   • You may see a 'corrupt installation' warning — this is normal"
echo "   • Click the gear icon and select 'Don't Show Again'"
echo "   • Your original settings are backed up with .pre-rounded-islands extension"
echo ""
