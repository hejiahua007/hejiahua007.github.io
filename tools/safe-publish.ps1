<#
.SYNOPSIS
    Safe publish script - scan _vault/ .md files, selectively git add based on frontmatter.published.
    published:true files are staged and pushed; published:false files stay local only.

.DESCRIPTION
    Usage (replaces git add -A):
        .\tools\safe-publish.ps1
        git commit -m "your message"
        git push

    Resets staging area, then checks each file's frontmatter, only staging published:true files.
    Files without frontmatter or without published field default to published:true.
#>

param(
    [switch]$DryRun,
    [switch]$NoReset,
    [switch]$IncludePosts
)

$ErrorActionPreference = "Stop"
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = Resolve-Path (Join-Path $scriptDir "..")
Set-Location $repoRoot

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  safe-publish.ps1 - Safe Publish Script" -ForegroundColor Cyan
Write-Host "  Only stage files with published:true" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

# Step 1: Reset staging area
if (-not $NoReset) {
    Write-Host "[INFO] Clearing staging area (git reset)..." -ForegroundColor Gray
    git reset | Out-Null
    Write-Host "[OK]   Staging area cleared`n" -ForegroundColor Green
} else {
    Write-Host "[INFO] Append mode, not clearing staging area`n" -ForegroundColor Gray
}

# Step 2: Scan _vault/ directory
$totalFiles = 0
$addedFiles = 0
$skippedFiles = 0
$skippedList = @()
$errorList = @()

function Test-Published {
    param([string]$FilePath)
    try {
        $content = Get-Content $FilePath -Raw -Encoding UTF8 -ErrorAction Stop
    }
    catch {
        $script:errorList += "[ERROR] Cannot read file: $FilePath"
        return $false
    }
    # Match YAML frontmatter (--- ... ---)
    if ($content -match '^---\s*\r?\n(.*?)\r?\n---') {
        $frontmatter = $Matches[1]
        if ($frontmatter -match 'published:\s*false') {
            return $false
        }
    }
    return $true
}

function Process-Directory {
    param([string]$DirPath, [string]$Label)
    if (-not (Test-Path $DirPath)) {
        Write-Host "[WARN] Directory not found: $DirPath`n" -ForegroundColor Yellow
        return
    }
    Write-Host "--- Scanning $Label ($DirPath) ---" -ForegroundColor Cyan
    $files = Get-ChildItem -Path $DirPath -Recurse -Filter "*.md" -File
    $localTotal = 0
    $localAdded = 0
    $localSkipped = 0
    foreach ($file in $files) {
        if ($file.Name -eq "_index.md") { continue }
        $localTotal++
        $script:totalFiles++
        $relPath = Resolve-Path $file.FullName -Relative
        $isPublished = Test-Published -FilePath $file.FullName
        if ($isPublished) {
            $localAdded++
            $script:addedFiles++
            if (-not $DryRun) { git add $file.FullName 2>&1 | Out-Null }
            Write-Host "  [ADD]    $relPath" -ForegroundColor Green
        } else {
            $localSkipped++
            $script:skippedFiles++
            $script:skippedList += $relPath
            Write-Host "  [SKIP]   $relPath" -ForegroundColor Yellow
        }
    }
    Write-Host "  Dir stats: +$localAdded / -$localSkipped / =$localTotal`n" -ForegroundColor Gray
}

# Scan _vault/
Process-Directory -DirPath (Join-Path $repoRoot "_vault") -Label "_vault/"

# Optionally scan _posts/
if ($IncludePosts) {
    Process-Directory -DirPath (Join-Path $repoRoot "_posts") -Label "_posts/"
}

# Step 3: Summary
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Publish Summary" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Staged:     $addedFiles" -ForegroundColor Green
Write-Host "  Skipped:    $skippedFiles" -ForegroundColor Yellow
Write-Host "  Total:      $totalFiles" -ForegroundColor Gray
Write-Host "========================================" -ForegroundColor Cyan

if ($skippedList.Count -gt 0) {
    Write-Host "`nFiles excluded (published:false):" -ForegroundColor Yellow
    foreach ($s in $skippedList) { Write-Host "  - $s" -ForegroundColor DarkYellow }
}

if ($errorList.Count -gt 0) {
    Write-Host "`nErrors:" -ForegroundColor Red
    foreach ($e in $errorList) { Write-Host "  $e" -ForegroundColor Red }
}

if ($DryRun) {
    Write-Host "`n[DRY RUN] Preview mode, no files were actually staged" -ForegroundColor Magenta
}

if ($skippedFiles -gt 0 -or $errorList.Count -gt 0) { exit 1 }
exit 0
