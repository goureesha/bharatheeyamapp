# ================================================================
# BHARATHEEYAM - Sync Gemini Conversation Backup
# Copies latest conversation data, plans, and artifacts to repo
# Run automatically before push, or manually anytime
# ================================================================

$geminiDir = "$env:USERPROFILE\.gemini\antigravity"
$backupDir = "$PSScriptRoot\.gemini-backup"

if (-not (Test-Path $geminiDir)) {
    Write-Host "[WARN] Gemini data not found at $geminiDir - skipping sync" -ForegroundColor Yellow
    exit 0
}

Write-Host "[SYNC] Syncing Gemini backup..." -ForegroundColor Cyan

# --- 1. Conversations (essential files only) ---
$brainDir = Join-Path $geminiDir "brain"
$convDst = Join-Path $backupDir "conversations"

if (Test-Path $brainDir) {
    # Clean old backup
    if (Test-Path $convDst) { Remove-Item $convDst -Recurse -Force }
    New-Item -ItemType Directory -Force -Path $convDst | Out-Null

    Get-ChildItem $brainDir -Directory | Where-Object { $_.Name -ne "tempmediaStorage" } | ForEach-Object {
        $convId = $_.Name
        $dst = Join-Path $convDst $convId
        New-Item -ItemType Directory -Force -Path $dst | Out-Null

        # Copy artifacts: .md, .json, .png (skip temp DOM snapshots, browser cache)
        Get-ChildItem $_.FullName -File | Where-Object {
            $_.Extension -in '.md','.json','.png' -and $_.Length -lt 5MB
        } | ForEach-Object {
            Copy-Item $_.FullName $dst -Force
        }

        # Copy conversation log
        $logSrc = Join-Path $_.FullName ".system_generated\logs\overview.txt"
        if (Test-Path $logSrc) {
            $logDst = Join-Path $dst "logs"
            New-Item -ItemType Directory -Force -Path $logDst | Out-Null
            Copy-Item $logSrc $logDst -Force
        }
    }
    $convCount = (Get-ChildItem $convDst -Directory).Count
    Write-Host "  [OK] $convCount conversations synced" -ForegroundColor Green
}

# --- 2. Knowledge Items ---
$knSrc = Join-Path $geminiDir "knowledge"
$knDst = Join-Path $backupDir "knowledge"
if (Test-Path $knSrc) {
    if (Test-Path $knDst) { Remove-Item $knDst -Recurse -Force }
    New-Item -ItemType Directory -Force -Path $knDst | Out-Null
    Copy-Item "$knSrc\*" $knDst -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host "  [OK] Knowledge items synced" -ForegroundColor Green
}

# --- 3. Stage backup changes ---
git add .gemini-backup/ 2>$null

$changes = git diff --cached --stat -- .gemini-backup/ 2>$null
if ($changes) {
    Write-Host "  [STAGED] Backup changes staged for commit" -ForegroundColor Cyan
} else {
    Write-Host "  [INFO] No backup changes to sync" -ForegroundColor Gray
}

Write-Host "[DONE] Gemini sync complete!" -ForegroundColor Green
