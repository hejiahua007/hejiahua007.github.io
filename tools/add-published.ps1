<#
.SYNOPSIS
    Batch-add 'published: true' to all _vault/ article .md files.
#>
$ErrorActionPreference = "Stop"
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = Resolve-Path (Join-Path $scriptDir "..")
$vaultDir = Join-Path $repoRoot "_vault"

$count = 0
$files = Get-ChildItem -Path $vaultDir -Recurse -Filter "*.md" -File | Where-Object { $_.Name -ne "_index.md" }

foreach ($f in $files) {
    $lines = Get-Content $f.FullName -Encoding UTF8
    if ($lines -join "`n" -match "published:") {
        Write-Host "SKIP: $($f.Name)" -ForegroundColor Gray
        continue
    }
    # Find frontmatter block: lines between first --- and second ---
    $dashCount = 0
    $insertIdx = -1
    for ($i = 0; $i -lt $lines.Count; $i++) {
        if ($lines[$i].Trim() -eq "---") {
            $dashCount++
            if ($dashCount -eq 2) {
                $insertIdx = $i
                break
            }
        }
    }
    if ($insertIdx -lt 0) {
        Write-Host "WARN: no frontmatter: $($f.Name)" -ForegroundColor Yellow
        continue
    }
    # Insert 'published: true' before the closing ---
    $newLines = $lines[0..($insertIdx - 1)] + @("published: true") + $lines[$insertIdx..($lines.Count - 1)]
    $utf8 = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllLines($f.FullName, $newLines, $utf8)
    $count++
    Write-Host "OK: $($f.Name)" -ForegroundColor Green
}

Write-Host "`nDone. Updated: $count files" -ForegroundColor Cyan
