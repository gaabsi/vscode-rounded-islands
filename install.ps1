# Rounded Islands — UI Installer for Windows

param()

$ErrorActionPreference = "Stop"

Write-Host "Rounded Islands — UI Installer for Windows" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

# Check if VS Code is installed
$codePath = Get-Command "code" -ErrorAction SilentlyContinue
if (-not $codePath) {
    $possiblePaths = @(
        "$env:LOCALAPPDATA\Programs\Microsoft VS Code\bin\code.cmd",
        "$env:ProgramFiles\Microsoft VS Code\bin\code.cmd",
        "${env:ProgramFiles(x86)}\Microsoft VS Code\bin\code.cmd"
    )

    $found = $false
    foreach ($path in $possiblePaths) {
        if (Test-Path $path) {
            $env:Path += ";$(Split-Path $path)"
            $found = $true
            break
        }
    }

    if (-not $found) {
        Write-Host "Error: VS Code CLI (code) not found!" -ForegroundColor Red
        Write-Host "Please install VS Code and make sure 'code' command is in your PATH."
        Write-Host "You can do this by:"
        Write-Host "  1. Open VS Code"
        Write-Host "  2. Press Ctrl+Shift+P"
        Write-Host "  3. Type 'Shell Command: Install code command in PATH'"
        exit 1
    }
}

Write-Host "VS Code CLI found" -ForegroundColor Green

# Get the directory where this script is located
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

# Determine VS Code settings directory
$settingsDir = "$env:APPDATA\Code\User"
if (-not (Test-Path $settingsDir)) {
    New-Item -ItemType Directory -Path $settingsDir -Force | Out-Null
}
$settingsFile = Join-Path $settingsDir "settings.json"

# Step 1: Install required extension
Write-Host ""
Write-Host "Step 1: Installing Custom UI Style extension..."
try {
    $output = code --install-extension subframe7536.custom-ui-style --force 2>&1
    Write-Host "Custom UI Style extension installed" -ForegroundColor Green
} catch {
    Write-Host "Could not install Custom UI Style extension automatically" -ForegroundColor Yellow
    Write-Host "   Please install it manually from the Extensions marketplace"
}

Write-Host ""
Write-Host "Step 1b: Installing Bearded Icons theme..."
try {
    $output = code --install-extension BeardedBear.beardedicons --force 2>&1
    Write-Host "Bearded Icons theme installed" -ForegroundColor Green
} catch {
    Write-Host "Could not install Bearded Icons automatically" -ForegroundColor Yellow
    Write-Host "   Please install it manually from the Extensions marketplace"
}

# Step 2: Copy fix-webviews.js
Write-Host ""
Write-Host "Step 2: Installing webview fix script..."
Copy-Item "$scriptDir\fix-webviews.js" "$settingsDir\fix-webviews.js" -Force
Write-Host "Webview fix script installed" -ForegroundColor Green

# Step 3: Backup and merge settings
Write-Host ""
Write-Host "Step 3: Applying rounded UI settings..."

if (Test-Path $settingsFile) {
    $backupFile = "$settingsFile.pre-rounded-islands"
    Copy-Item $settingsFile $backupFile -Force
    Write-Host "Existing settings.json backed up to:" -ForegroundColor Yellow
    Write-Host "   $backupFile"
}

# Merge settings using Python
$env:SCRIPT_DIR = $scriptDir
$env:SETTINGS_FILE = $settingsFile
python -c @"
import json, os

settings_path = os.environ['SETTINGS_FILE']
src_path = os.path.join(os.environ['SCRIPT_DIR'], 'settings.json')

user = {}
if os.path.exists(settings_path):
    try:
        with open(settings_path) as f:
            user = json.load(f)
    except json.JSONDecodeError:
        print('Warning: Could not parse existing settings.json, starting fresh')
        user = {}

with open(src_path) as f:
    src = json.load(f)

for key, value in src.items():
    if key.startswith('//'):
        continue
    if key == 'custom-ui-style.stylesheet' and isinstance(value, dict):
        user[key] = value
    elif key == 'workbench.colorCustomizations' and isinstance(value, dict):
        if key not in user or not isinstance(user[key], dict):
            user[key] = {}
        user[key].update(value)
    else:
        user[key] = value

settings_dir = os.path.dirname(settings_path)
js_path = os.path.join(settings_dir, 'fix-webviews.js')
user['custom-ui-style.external.imports'] = ['file://' + js_path]

with open(settings_path, 'w') as f:
    json.dump(user, f, indent=2)
    f.write('\n')
"@
Write-Host "Rounded UI settings merged into your config" -ForegroundColor Green

# Step 4: Reload VS Code
Write-Host ""
Write-Host "Step 4: Reloading VS Code..."
Write-Host "   Closing VS Code..." -ForegroundColor Cyan
Stop-Process -Name "Code" -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 3

Write-Host "   Relaunching VS Code..." -ForegroundColor Cyan
Start-Process "code" -ErrorAction SilentlyContinue

Write-Host ""
Write-Host "Done!" -ForegroundColor Green
Write-Host ""
Write-Host "Notes:" -ForegroundColor Yellow
Write-Host "   - You may see a 'corrupt installation' warning — this is normal"
Write-Host "   - Click the gear icon and select 'Don't Show Again'"
Write-Host "   - Your original settings are backed up with .pre-rounded-islands extension"
Write-Host ""
Write-Host "If the CSS customizations are not applied, open the Command Palette" -ForegroundColor Yellow
Write-Host "(Ctrl+Shift+P) and run: Custom UI Style: Reload" -ForegroundColor Yellow

Start-Sleep -Seconds 3
