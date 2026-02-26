# ================================================================
# BHARATHEEYAM — Push to GitHub
# Run this script in PowerShell after getting your token
# ================================================================

$token = "PASTE_YOUR_TOKEN_HERE"   # <-- paste your token between the quotes
$repoUrl = "https://${token}@github.com/goureesha/bharatheeyamapp.git"

Write-Host "Setting remote..." -ForegroundColor Cyan
& "C:\Program Files\Git\bin\git.exe" remote add origin $repoUrl 2>$null
& "C:\Program Files\Git\bin\git.exe" remote set-url origin $repoUrl

Write-Host "Pushing to GitHub..." -ForegroundColor Cyan
& "C:\Program Files\Git\bin\git.exe" branch -M main
& "C:\Program Files\Git\bin\git.exe" push -u origin main --force

Write-Host ""
Write-Host "✅ Done! Your code is now on GitHub." -ForegroundColor Green
Write-Host "Go to: https://github.com/goureesha/bharatheeyamapp/actions" -ForegroundColor Yellow
Write-Host "Click 'Build APK & Flutter Web' → 'Run workflow' to start the build." -ForegroundColor Yellow
