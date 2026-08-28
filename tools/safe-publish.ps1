<#
.SYNOPSIS
    Stage only explicitly public Vault content and its referenced local assets.

.DESCRIPTION
    Publication is fail-closed:
      - published: true  => eligible for staging
      - published: false => kept local and removed from the Git index if tracked
      - missing/invalid  => blocked and reported as an error

    The script never commits or pushes. It only changes the Git staging area
    inside _vault/. Staged changes outside _vault/ are preserved.
#>

param(
    [switch]$DryRun,
    [switch]$NoReset
)

$ErrorActionPreference = 'Stop'
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = (Resolve-Path (Join-Path $scriptDir '..')).Path
$vaultRoot = Join-Path $repoRoot '_vault'
Set-Location $repoRoot

$publishedFiles = [System.Collections.Generic.List[string]]::new()
$privateFiles = [System.Collections.Generic.List[string]]::new()
$invalidFiles = [System.Collections.Generic.List[string]]::new()
$assetFiles = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
$errors = [System.Collections.Generic.List[string]]::new()

function Get-RelativeRepoPath {
    param([Parameter(Mandatory = $true)][string]$FullPath)

    $rootWithSeparator = $repoRoot.TrimEnd('\') + '\'
    if (-not $FullPath.StartsWith($rootWithSeparator, [System.StringComparison]::OrdinalIgnoreCase)) {
        throw "Path escapes repository: $FullPath"
    }
    return $FullPath.Substring($rootWithSeparator.Length).Replace('\', '/')
}

function Get-PublicationState {
    param([Parameter(Mandatory = $true)][string]$Content)

    if ($Content -notmatch '(?s)\A---\s*\r?\n(?<fm>.*?)\r?\n---') {
        return 'Invalid'
    }

    $frontmatter = $Matches['fm']
    $matches = [regex]::Matches($frontmatter, '(?m)^published:\s*(true|false)\s*$')
    if ($matches.Count -ne 1) {
        return 'Invalid'
    }
    if ($matches[0].Groups[1].Value -eq 'true') {
        foreach ($requiredField in @('title', 'date')) {
            if ([regex]::Matches($frontmatter, "(?m)^$requiredField\s*:").Count -ne 1) {
                return 'Invalid'
            }
        }
        return 'Published'
    }
    return 'Private'
}

function Add-ReferencedAssets {
    param(
        [Parameter(Mandatory = $true)][string]$MarkdownPath,
        [Parameter(Mandatory = $true)][string]$Content
    )

    $scanContent = [regex]::Replace($Content, '(?ms)^\s*```.*?^\s*```\s*', '')
    $scanContent = [regex]::Replace($scanContent, '(?ms)^\s*~~~.*?^\s*~~~\s*', '')
    $urls = [System.Collections.Generic.List[string]]::new()
    foreach ($match in [regex]::Matches($scanContent, '!\[[^\]]*\]\((?<url>[^)\s]+)')) {
        $urls.Add($match.Groups['url'].Value.Trim('<', '>'))
    }
    foreach ($match in [regex]::Matches($scanContent, '<img\b[^>]*\bsrc=["''](?<url>[^"'']+)["'']', 'IgnoreCase')) {
        $urls.Add($match.Groups['url'].Value)
    }

    foreach ($url in $urls) {
        if ($url -match '^(?:[a-z][a-z0-9+.-]*:|#)') { continue }

        $pathOnly = ($url -split '[?#]', 2)[0]
        if ($pathOnly.StartsWith('/')) {
            $candidate = Join-Path $repoRoot $pathOnly.TrimStart('/').Replace('/', '\')
        }
        else {
            $candidate = Join-Path (Split-Path -Parent $MarkdownPath) $pathOnly.Replace('/', '\')
        }

        $fullPath = [System.IO.Path]::GetFullPath($candidate)
        $repoPrefix = $repoRoot.TrimEnd('\') + '\'
        if (-not $fullPath.StartsWith($repoPrefix, [System.StringComparison]::OrdinalIgnoreCase)) {
            $errors.Add("Asset path escapes repository: $url in $(Get-RelativeRepoPath $MarkdownPath)")
            continue
        }
        if (-not (Test-Path -LiteralPath $fullPath -PathType Leaf)) {
            $errors.Add("Missing asset: $url in $(Get-RelativeRepoPath $MarkdownPath)")
            continue
        }
        [void]$assetFiles.Add((Get-RelativeRepoPath $fullPath))
    }
}

if (-not (Test-Path -LiteralPath $vaultRoot -PathType Container)) {
    throw "Vault directory not found: $vaultRoot"
}

if (-not $NoReset -and -not $DryRun) {
    git reset -q HEAD -- _vault
    if ($LASTEXITCODE -ne 0) { throw 'Unable to clear the _vault staging scope.' }
}

$markdownFiles = Get-ChildItem -LiteralPath $vaultRoot -Recurse -File -Filter '*.md' |
    Where-Object { $_.Name -ne '_index.md' } |
    Sort-Object FullName

foreach ($file in $markdownFiles) {
    $content = Get-Content -LiteralPath $file.FullName -Raw -Encoding UTF8
    $relativePath = Get-RelativeRepoPath $file.FullName
    $state = Get-PublicationState $content

    switch ($state) {
        'Published' {
            $publishedFiles.Add($relativePath)
            Add-ReferencedAssets -MarkdownPath $file.FullName -Content $content
        }
        'Private' {
            $privateFiles.Add($relativePath)
        }
        default {
            $invalidFiles.Add($relativePath)
            $errors.Add("Missing or invalid explicit published field: $relativePath")
        }
    }
}

$deletedTracked = @(git -c core.quotepath=false ls-files --deleted -- _vault)
if ($LASTEXITCODE -ne 0) { throw 'Unable to inspect deleted tracked Vault files.' }

if (-not $DryRun) {
    foreach ($path in $deletedTracked) {
        git add -u -- $path
        if ($LASTEXITCODE -ne 0) { throw "Unable to stage deletion: $path" }
    }

    foreach ($path in @($privateFiles) + @($invalidFiles)) {
        $tracked = @(git ls-files -- $path)
        if ($LASTEXITCODE -ne 0) { throw "Unable to inspect tracked state: $path" }
        if ($tracked.Count -gt 0) {
            git rm -q -f --cached -- $path
            if ($LASTEXITCODE -ne 0) { throw "Unable to untrack private file: $path" }
        }
    }

    foreach ($path in $publishedFiles) {
        git add -f -- $path
        if ($LASTEXITCODE -ne 0) { throw "Unable to stage published file: $path" }
    }
    foreach ($path in $assetFiles) {
        git add -f -- $path
        if ($LASTEXITCODE -ne 0) { throw "Unable to stage asset: $path" }
    }
}

Write-Host ''
Write-Host 'Vault publication preview'
Write-Host "  Published Markdown : $($publishedFiles.Count)"
Write-Host "  Referenced assets  : $($assetFiles.Count)"
Write-Host "  Private Markdown   : $($privateFiles.Count)"
Write-Host "  Invalid/blocked    : $($invalidFiles.Count)"
Write-Host "  Deleted tracked    : $($deletedTracked.Count)"

if ($invalidFiles.Count -gt 0) {
    Write-Host ''
    Write-Host 'Blocked files:' -ForegroundColor Red
    foreach ($path in $invalidFiles) { Write-Host "  - $path" -ForegroundColor Red }
}
if ($errors.Count -gt 0) {
    Write-Host ''
    Write-Host 'Errors:' -ForegroundColor Red
    foreach ($message in $errors) { Write-Host "  - $message" -ForegroundColor Red }
}

if ($DryRun) {
    Write-Host ''
    Write-Host 'Dry run only; staging area was not changed.' -ForegroundColor Cyan
}

if ($errors.Count -gt 0) { exit 1 }
exit 0
