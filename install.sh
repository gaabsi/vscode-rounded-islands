#!/bin/bash

set -e

echo "Rounded Islands — UI Installer for macOS/Linux"
echo "================================================"
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if code command is available
if ! command -v code &> /dev/null; then
    echo -e "${RED}Error: VS Code CLI (code) not found!${NC}"
    echo "Please install VS Code and make sure 'code' command is in your PATH."
    echo "You can do this by:"
    echo "  1. Open VS Code"
    echo "  2. Press Cmd+Shift+P (macOS) or Ctrl+Shift+P (Linux)"
    echo "  3. Type 'Shell Command: Install code command in PATH'"
    exit 1
fi

echo -e "${GREEN}VS Code CLI found${NC}"

# Get the directory where this script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Determine VS Code settings directory
SETTINGS_DIR="$HOME/.config/Code/User"
if [[ "$OSTYPE" == "darwin"* ]]; then
    SETTINGS_DIR="$HOME/Library/Application Support/Code/User"
fi
mkdir -p "$SETTINGS_DIR"
SETTINGS_FILE="$SETTINGS_DIR/settings.json"

# Step 1: Install required extension
echo ""
echo "Step 1: Installing Custom UI Style extension..."
if code --install-extension subframe7536.custom-ui-style --force; then
    echo -e "${GREEN}Custom UI Style extension installed${NC}"
else
    echo -e "${YELLOW}Could not install Custom UI Style extension automatically${NC}"
    echo "   Please install it manually from the Extensions marketplace"
fi

echo ""
echo "Step 1b: Installing Bearded Icons theme..."
if code --install-extension BeardedBear.beardedicons --force; then
    echo -e "${GREEN}Bearded Icons theme installed${NC}"
else
    echo -e "${YELLOW}Could not install Bearded Icons automatically${NC}"
    echo "   Please install it manually from the Extensions marketplace"
fi

# Step 2: Copy fix-webviews.js
echo ""
echo "Step 2: Installing webview fix script..."
cp "$SCRIPT_DIR/fix-webviews.js" "$SETTINGS_DIR/fix-webviews.js"
echo -e "${GREEN}Webview fix script installed${NC}"

# Step 3: Backup and merge settings
echo ""
echo "Step 3: Applying rounded UI settings..."

if [ -f "$SETTINGS_FILE" ]; then
    BACKUP_FILE="$SETTINGS_FILE.pre-rounded-islands"
    cp "$SETTINGS_FILE" "$BACKUP_FILE"
    echo -e "${YELLOW}Existing settings.json backed up to:${NC}"
    echo "   $BACKUP_FILE"
fi

# Merge settings using Python (available on macOS/Linux without extra deps)
SCRIPT_DIR="$SCRIPT_DIR" SETTINGS_FILE="$SETTINGS_FILE" python3 -c '
import json, os

settings_path = os.environ["SETTINGS_FILE"]
src_path = os.path.join(os.environ["SCRIPT_DIR"], "settings.json")

# Load existing user settings
user = {}
if os.path.exists(settings_path):
    try:
        with open(settings_path) as f:
            user = json.load(f)
    except json.JSONDecodeError:
        print("Warning: Could not parse existing settings.json, starting fresh")
        user = {}

# Load source settings
with open(src_path) as f:
    src = json.load(f)

# Merge: stylesheet is replaced entirely, colorCustomizations is deep-merged, rest is overwritten
for key, value in src.items():
    if key.startswith("//"):
        continue
    if key == "custom-ui-style.stylesheet" and isinstance(value, dict):
        user[key] = value
    elif key == "workbench.colorCustomizations" and isinstance(value, dict):
        if key not in user or not isinstance(user[key], dict):
            user[key] = {}
        user[key].update(value)
    else:
        user[key] = value

# Add JS fix path
settings_dir = os.path.dirname(settings_path)
js_path = os.path.join(settings_dir, "fix-webviews.js")
user["custom-ui-style.external.imports"] = ["file://" + js_path]

with open(settings_path, "w") as f:
    json.dump(user, f, indent=2)
    f.write("\n")
'
echo -e "${GREEN}Rounded UI settings merged into your config${NC}"

# Step 4: Reload VS Code
echo ""
echo "Step 4: Reloading VS Code..."

if [[ "$OSTYPE" == "darwin"* ]]; then
    osascript -e 'display notification "Rounded UI installed successfully!" with title "Rounded Islands"' 2>/dev/null || true
fi

code --reload-window 2>/dev/null || code . 2>/dev/null || true

echo ""
echo -e "${GREEN}Done!${NC}"
echo ""
echo -e "${YELLOW}Notes:${NC}"
echo "   - You may see a 'corrupt installation' warning — this is normal"
echo "   - Click the gear icon and select 'Don't Show Again'"
echo "   - Your original settings are backed up with .pre-rounded-islands extension"
echo ""
