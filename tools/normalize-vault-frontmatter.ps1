<#
.SYNOPSIS
    Add minimal fail-closed front matter to Vault Markdown files.

.DESCRIPTION
    Existing values are preserved. Missing published is always added as false.
    Files without front matter receive title, date, tags, and published:false.
#>

param(
    [switch]$Apply
)

$ErrorActionPreference = 'Stop'
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = (Resolve-Path (Join-Path $scriptDir '..')).Path
$vaultRoot = Join-Path $repoRoot '_vault'
$changed = [System.Collections.Generic.List[string]]::new()
$blocked = [System.Collections.Generic.List[string]]::new()

function Get-RelativeRepoPath {
    param([string]$FullPath)
    return $FullPath.Substring($repoRoot.TrimEnd('\').Length + 1).Replace('\', '/')
}

foreach ($file in (Get-ChildItem -LiteralPath $vaultRoot -Recurse -File -Filter '*.md' | Sort-Object FullName)) {
    if ($file.Name -eq '_index.md') { continue }
    $content = Get-Content -LiteralPath $file.FullName -Raw -Encoding UTF8
    $newContent = $content

    $frontmatterMatch = [regex]::Match($content, '(?s)\A---\s*\r?\n(?<fm>.*?)\r?\n---')
    if ($frontmatterMatch.Success) {
        $publishedMatches = [regex]::Matches($frontmatterMatch.Groups['fm'].Value, '(?m)^published\s*:')
        if ($publishedMatches.Count -gt 1) {
            $blocked.Add("$(Get-RelativeRepoPath $file.FullName): duplicate published fields")
            continue
        }
        if ($publishedMatches.Count -eq 0) {
            $replacement = $frontmatterMatch.Value -replace '\r?\n---$', "`r`npublished: false`r`n---"
            $newContent = $replacement + $content.Substring($frontmatterMatch.Length)
        }
    }
    else {
        $title = [System.IO.Path]::GetFileNameWithoutExtension($file.Name)
        $heading = [regex]::Match($content, '(?m)^#\s+(?<title>.+?)\s*$')
        if ($heading.Success) { $title = $heading.Groups['title'].Value.Trim() }
        $title = $title.Replace('"', '\"')
        $date = $file.LastWriteTime.ToString('yyyy-MM-dd HH:mm:ss') + ' +0800'
        $frontmatter = "---`r`ntitle: `"$title`"`r`ndate: $date`r`ntags: []`r`npublished: false`r`n---`r`n`r`n"
        $newContent = $frontmatter + $content.TrimStart([char]0xFEFF)
    }

    if ($newContent -ne $content) {
        $relativePath = Get-RelativeRepoPath $file.FullName
        $changed.Add($relativePath)
        if ($Apply) {
            [System.IO.File]::WriteAllText($file.FullName, $newContent, [System.Text.UTF8Encoding]::new($false))
        }
    }
}

Write-Host "Would normalize: $($changed.Count)"
foreach ($path in $changed) { Write-Host "  - $path" }
if ($blocked.Count -gt 0) {
    Write-Host "Blocked: $($blocked.Count)" -ForegroundColor Red
    foreach ($message in $blocked) { Write-Host "  - $message" -ForegroundColor Red }
}
if (-not $Apply) { Write-Host 'Dry run only. Use -Apply to write changes.' }
if ($blocked.Count -gt 0) { exit 1 }
exit 0
