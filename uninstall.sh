#!/bin/bash

set -e

echo "Rounded Islands — UI Uninstaller for macOS/Linux"
echo "=================================================="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Determine VS Code settings directory
SETTINGS_DIR="$HOME/.config/Code/User"
if [[ "$OSTYPE" == "darwin"* ]]; then
    SETTINGS_DIR="$HOME/Library/Application Support/Code/User"
fi

SETTINGS_FILE="$SETTINGS_DIR/settings.json"

# Step 1: Restore settings from backup
echo "Step 1: Restoring VS Code settings..."
BACKUP_FILE="$SETTINGS_FILE.pre-rounded-islands"
LEGACY_BACKUP="$SETTINGS_FILE.pre-islands-dark"

if [ -f "$BACKUP_FILE" ]; then
    cp "$BACKUP_FILE" "$SETTINGS_FILE"
    echo -e "${GREEN}Settings restored from backup${NC}"
    echo "   Backup file: $BACKUP_FILE"
elif [ -f "$LEGACY_BACKUP" ]; then
    cp "$LEGACY_BACKUP" "$SETTINGS_FILE"
    echo -e "${GREEN}Settings restored from legacy backup${NC}"
    echo "   Backup file: $LEGACY_BACKUP"
else
    echo -e "${YELLOW}No backup found${NC}"
    echo "   You may need to manually update your VS Code settings."
fi

# Step 2: Remove fix-webviews.js
JS_FILE="$SETTINGS_DIR/fix-webviews.js"
if [ -f "$JS_FILE" ]; then
    rm "$JS_FILE"
    echo -e "${GREEN}Webview fix script removed${NC}"
fi

# Step 3: Disable Custom UI Style
echo ""
echo "Step 2: Disabling Custom UI Style..."
echo -e "${YELLOW}   Please disable Custom UI Style manually:${NC}"
echo "   1. Open Command Palette (Cmd+Shift+P / Ctrl+Shift+P)"
echo "   2. Run 'Custom UI Style: Disable'"
echo "   3. VS Code will reload"

echo ""
echo -e "${GREEN}Rounded UI has been uninstalled!${NC}"
echo ""
echo "   Reload VS Code to complete the process."
echo ""
