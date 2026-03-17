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

if code --install-extension catppuccin.catppuccin-vsc-icons --force; then
    echo -e "${GREEN}✓ Catppuccin Icons extension installed${NC}"
else
    echo -e "${YELLOW}⚠️  Could not install Catppuccin Icons extension automatically${NC}"
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

# Merge rounded UI settings into existing settings using Node.js
SCRIPT_DIR="$SCRIPT_DIR" SETTINGS_FILE="$SETTINGS_FILE" node -e '
const fs = require("fs");

const userPath = process.env.SETTINGS_FILE;
const srcPath = require("path").join(process.env.SCRIPT_DIR, "settings.json");

let user = {};
if (fs.existsSync(userPath)) {
    try {
        let raw = fs.readFileSync(userPath, "utf8");
        raw = raw.replace(/^\s*\/\/.*$/gm, "");
        raw = raw.replace(/,\s*([\]}])/g, "$1");
        user = JSON.parse(raw);
    } catch (e) {
        console.error("Warning: Could not parse existing settings.json, starting fresh");
        user = {};
    }
}

let src = JSON.parse(fs.readFileSync(srcPath, "utf8").replace(/^\s*\/\/.*$/gm, "").replace(/,\s*([\]}])/g, "$1"));

for (const [key, value] of Object.entries(src)) {
    if (key.startsWith("//")) continue;
    if (key === "custom-ui-style.stylesheet" && typeof value === "object") {
        user[key] = value;
    } else if (key === "workbench.colorCustomizations" && typeof value === "object") {
        if (!user[key] || typeof user[key] !== "object") user[key] = {};
        Object.assign(user[key], value);
    } else {
        user[key] = value;
    }
}

fs.writeFileSync(userPath, JSON.stringify(user, null, 2) + "\n");
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
