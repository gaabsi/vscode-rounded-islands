# Rounded Islands — Rounded UI Uninstaller for Windows

param()

$ErrorActionPreference = "Stop"

Write-Host "Rounded Islands — Rounded UI Uninstaller for Windows" -ForegroundColor Cyan
Write-Host "======================================================" -ForegroundColor Cyan
Write-Host ""

# Step 1: Restore old settings
Write-Host "Step 1: Restoring VS Code settings..."
$settingsDir = "$env:APPDATA\Code\User"
$settingsFile = Join-Path $settingsDir "settings.json"
$backupFile = "$settingsFile.pre-rounded-islands"

if (Test-Path $backupFile) {
    Copy-Item $backupFile $settingsFile -Force
    Write-Host "Settings restored from backup" -ForegroundColor Green
    Write-Host "   Backup file: $backupFile"
} else {
    Write-Host "No backup found at $backupFile" -ForegroundColor Yellow
    Write-Host "   You may need to manually update your VS Code settings."
}

# Step 2: Disable Custom UI Style
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
