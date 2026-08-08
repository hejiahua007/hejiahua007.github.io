<#
.SYNOPSIS
    Validate Vault front matter, hierarchy, publication state, and local assets.
#>

param(
    [switch]$ChangedOnly,
    [string]$JsonReport
)

$ErrorActionPreference = 'Stop'
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = (Resolve-Path (Join-Path $scriptDir '..')).Path
$vaultRoot = Join-Path $repoRoot '_vault'
Set-Location $repoRoot

$errors = [System.Collections.Generic.List[object]]::new()
$warnings = [System.Collections.Generic.List[object]]::new()
$checked = [System.Collections.Generic.List[string]]::new()

function Get-RelativeRepoPath {
    param([string]$FullPath)
    $prefix = $repoRoot.TrimEnd('\') + '\'
    return $FullPath.Substring($prefix.Length).Replace('\', '/')
}

function Add-Issue {
    param([string]$Level, [string]$Path, [string]$Message)
    $issue = [ordered]@{ level = $Level; path = $Path; message = $Message }
    if ($Level -eq 'error') { $errors.Add($issue) } else { $warnings.Add($issue) }
}

function Get-CandidateFiles {
    if (-not $ChangedOnly) {
        return @(Get-ChildItem -LiteralPath $vaultRoot -Recurse -File -Filter '*.md')
    }

    $paths = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
    $excludeConfig = "core.excludesfile=$(Join-Path $repoRoot '.git\info\exclude')"
    $statusLines = @(git -c core.quotepath=false -c $excludeConfig status --porcelain=v1 --untracked-files=all --ignored=matching -- _vault 2>$null)
    foreach ($line in $statusLines) {
        if ($line.Length -lt 4) { continue }
        $path = $line.Substring(3).Trim('"')
        if ($path -match ' -> ') { $path = ($path -split ' -> ', 2)[1] }
        if ($path.EndsWith('.md', [System.StringComparison]::OrdinalIgnoreCase)) {
            [void]$paths.Add($path)
        }
    }
    return @($paths | ForEach-Object {
        $fullPath = Join-Path $repoRoot $_.Replace('/', '\')
        if (Test-Path -LiteralPath $fullPath -PathType Leaf) { Get-Item -LiteralPath $fullPath }
    })
}

function Test-AssetReference {
    param([string]$MarkdownPath, [string]$RelativePath, [string]$Url)
    if ($Url -match '^(?:[a-z][a-z0-9+.-]*:|#)') { return }
    $pathOnly = ($Url.Trim('<', '>') -split '[?#]', 2)[0]
    if ($pathOnly.StartsWith('/')) {
        $candidate = Join-Path $repoRoot $pathOnly.TrimStart('/').Replace('/', '\')
    }
    else {
        $candidate = Join-Path (Split-Path -Parent $MarkdownPath) $pathOnly.Replace('/', '\')
    }
    $fullPath = [System.IO.Path]::GetFullPath($candidate)
    $prefix = $repoRoot.TrimEnd('\') + '\'
    if (-not $fullPath.StartsWith($prefix, [System.StringComparison]::OrdinalIgnoreCase)) {
        Add-Issue error $RelativePath "Asset escapes repository: $Url"
    }
    elseif (-not (Test-Path -LiteralPath $fullPath -PathType Leaf)) {
        Add-Issue error $RelativePath "Missing local asset: $Url"
    }
}

$files = @(Get-CandidateFiles | Sort-Object FullName)
foreach ($file in $files) {
    $relativePath = Get-RelativeRepoPath $file.FullName
    $checked.Add($relativePath)
    if ($file.Name -eq '_index.md') { continue }

    $parts = $relativePath -split '/'
    if ($parts.Count -lt 3 -or $parts[1] -notmatch '^A\d+-') {
        Add-Issue warning $relativePath 'Article is not under an ordered A-level folder.'
    }
    $content = Get-Content -LiteralPath $file.FullName -Raw -Encoding UTF8
    if ($content -notmatch '(?s)\A---\s*\r?\n(?<fm>.*?)\r?\n---') {
        Add-Issue error $relativePath 'Missing YAML front matter.'
        continue
    }
    $frontmatter = $Matches['fm']

    foreach ($field in @('title', 'date', 'published')) {
        $fieldMatches = [regex]::Matches($frontmatter, "(?m)^$field\s*:")
        if ($fieldMatches.Count -eq 0) { Add-Issue error $relativePath "Missing field: $field" }
        elseif ($fieldMatches.Count -gt 1) { Add-Issue error $relativePath "Duplicate field: $field" }
    }

    $publishedMatches = [regex]::Matches($frontmatter, '(?m)^published:\s*(true|false)\s*$')
    if ($publishedMatches.Count -ne 1) {
        Add-Issue error $relativePath 'published must be one unquoted boolean true or false.'
    }

    $scanContent = [regex]::Replace($content, '(?ms)^\s*```.*?^\s*```\s*', '')
    $scanContent = [regex]::Replace($scanContent, '(?ms)^\s*~~~.*?^\s*~~~\s*', '')
    foreach ($match in [regex]::Matches($scanContent, '!\[[^\]]*\]\((?<url>[^)\s]+)')) {
        Test-AssetReference $file.FullName $relativePath $match.Groups['url'].Value
    }
    foreach ($match in [regex]::Matches($scanContent, '<img\b[^>]*\bsrc=["''](?<url>[^"'']+)["'']', 'IgnoreCase')) {
        Test-AssetReference $file.FullName $relativePath $match.Groups['url'].Value
    }
}

$report = [ordered]@{
    generated_at = (Get-Date).ToString('o')
    changed_only = [bool]$ChangedOnly
    checked_files = @($checked)
    error_count = $errors.Count
    warning_count = $warnings.Count
    errors = @($errors)
    warnings = @($warnings)
}

if ($JsonReport) {
    $fullReportPath = if ([System.IO.Path]::IsPathRooted($JsonReport)) { $JsonReport } else { Join-Path $repoRoot $JsonReport }
    $reportDir = Split-Path -Parent $fullReportPath
    if (-not (Test-Path -LiteralPath $reportDir)) { New-Item -ItemType Directory -Path $reportDir -Force | Out-Null }
    [System.IO.File]::WriteAllText($fullReportPath, ($report | ConvertTo-Json -Depth 8), [System.Text.UTF8Encoding]::new($false))
}

Write-Host "Checked: $($checked.Count)"
Write-Host "Errors: $($errors.Count)"
Write-Host "Warnings: $($warnings.Count)"
foreach ($issue in $errors) { Write-Host "[ERROR] $($issue.path): $($issue.message)" -ForegroundColor Red }
foreach ($issue in $warnings) { Write-Host "[WARN] $($issue.path): $($issue.message)" -ForegroundColor Yellow }

if ($errors.Count -gt 0) { exit 1 }
exit 0
