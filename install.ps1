# Rounded Islands — Rounded UI Installer for Windows

param()

$ErrorActionPreference = "Stop"

Write-Host "Rounded Islands — Rounded UI Installer for Windows" -ForegroundColor Cyan
Write-Host "====================================================" -ForegroundColor Cyan
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

Write-Host ""
Write-Host "Step 1: Installing extensions..."
try {
    $output = code --install-extension subframe7536.custom-ui-style --force 2>&1
    Write-Host "Custom UI Style extension installed" -ForegroundColor Green
} catch {
    Write-Host "Could not install Custom UI Style extension automatically" -ForegroundColor Yellow
    Write-Host "   Please install it manually from the Extensions marketplace"
}

try {
    $output = code --install-extension catppuccin.catppuccin-vsc-icons --force 2>&1
    Write-Host "Catppuccin Icons extension installed" -ForegroundColor Green
} catch {
    Write-Host "Could not install Catppuccin Icons extension automatically" -ForegroundColor Yellow
    Write-Host "   Please install it manually from the Extensions marketplace"
}

Write-Host ""
Write-Host "Step 2: Applying rounded UI settings..."
$settingsDir = "$env:APPDATA\Code\User"
if (-not (Test-Path $settingsDir)) {
    New-Item -ItemType Directory -Path $settingsDir -Force | Out-Null
}

$settingsFile = Join-Path $settingsDir "settings.json"

# Backup existing settings if they exist
if (Test-Path $settingsFile) {
    $backupFile = "$settingsFile.pre-rounded-islands"
    Copy-Item $settingsFile $backupFile -Force
    Write-Host "Existing settings.json backed up to:" -ForegroundColor Yellow
    Write-Host "   $backupFile"
    Write-Host "   You can restore your old settings from this file if needed."
}

# Merge rounded UI settings into existing settings using Node.js
$srcPath = Join-Path $scriptDir "settings.json"
$env:SETTINGS_FILE = $settingsFile
$env:SCRIPT_DIR = $scriptDir

node -e @"
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
"@

Write-Host "Rounded UI settings merged into your config" -ForegroundColor Green

Write-Host ""
Write-Host "Step 3: Reloading VS Code..."

# Quit VS Code and relaunch so Custom UI Style fully initializes
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
