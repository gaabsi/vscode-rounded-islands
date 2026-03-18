# Rounded Islands — UI Uninstaller for Windows

param()

$ErrorActionPreference = "Stop"

Write-Host "Rounded Islands — UI Uninstaller for Windows" -ForegroundColor Cyan
Write-Host "==============================================" -ForegroundColor Cyan
Write-Host ""

# Determine VS Code settings directory
$settingsDir = "$env:APPDATA\Code\User"
$settingsFile = Join-Path $settingsDir "settings.json"

# Step 1: Restore settings from backup
Write-Host "Step 1: Restoring VS Code settings..."
$backupFile = "$settingsFile.pre-rounded-islands"
$legacyBackup = "$settingsFile.pre-islands-dark"

if (Test-Path $backupFile) {
    Copy-Item $backupFile $settingsFile -Force
    Write-Host "Settings restored from backup" -ForegroundColor Green
    Write-Host "   Backup file: $backupFile"
} elseif (Test-Path $legacyBackup) {
    Copy-Item $legacyBackup $settingsFile -Force
    Write-Host "Settings restored from legacy backup" -ForegroundColor Green
    Write-Host "   Backup file: $legacyBackup"
} else {
    Write-Host "No backup found" -ForegroundColor Yellow
    Write-Host "   You may need to manually update your VS Code settings."
}

# Step 2: Remove fix-webviews.js
$jsFile = Join-Path $settingsDir "fix-webviews.js"
if (Test-Path $jsFile) {
    Remove-Item $jsFile -Force
    Write-Host "Webview fix script removed" -ForegroundColor Green
}

# Step 3: Disable Custom UI Style
Write-Host ""
Write-Host "Step 2: Disabling Custom UI Style..."
Write-Host "   Please disable Custom UI Style manually:" -ForegroundColor Yellow
Write-Host "   1. Open Command Palette (Ctrl+Shift+P)"
Write-Host "   2. Run 'Custom UI Style: Disable'"
Write-Host "   3. VS Code will reload"

Write-Host ""
Write-Host "Rounded UI has been uninstalled!" -ForegroundColor Green
Write-Host ""
Write-Host "   Reload VS Code to complete the process."
Write-Host ""

Start-Sleep -Seconds 3
