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
    [switch]$NoReset,
    [string]$ApprovedManifest
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
$approvedHashes = @{}
$blockedManifestFiles = [System.Collections.Generic.List[string]]::new()

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
        $assetPath = Get-RelativeRepoPath $fullPath
        if ($ApprovedManifest -and -not $assetPath.StartsWith('_vault/', [System.StringComparison]::OrdinalIgnoreCase)) {
            # Existing legacy articles may still reference tracked assets below
            # /assets. They are safe to reuse only when already tracked and
            # unchanged; the approved publication scope must never stage or
            # alter those external files.
            git ls-files --error-unmatch -- $assetPath *> $null
            $isTracked = $LASTEXITCODE -eq 0
            git diff --quiet -- $assetPath
            $worktreeUnchanged = $LASTEXITCODE -eq 0
            git diff --cached --quiet -- $assetPath
            $indexUnchanged = $LASTEXITCODE -eq 0
            if ($isTracked -and $worktreeUnchanged -and $indexUnchanged) {
                continue
            }
            $errors.Add("Approved publication asset outside _vault/ must already be tracked and unchanged: $assetPath")
            continue
        }
        [void]$assetFiles.Add($assetPath)
    }
}

if (-not (Test-Path -LiteralPath $vaultRoot -PathType Container)) {
    throw "Vault directory not found: $vaultRoot"
}

$markdownFiles = @()
if ($ApprovedManifest) {
    $manifestPath = if ([System.IO.Path]::IsPathRooted($ApprovedManifest)) {
        [System.IO.Path]::GetFullPath($ApprovedManifest)
    }
    else {
        [System.IO.Path]::GetFullPath((Join-Path $repoRoot $ApprovedManifest))
    }
    $repoPrefix = $repoRoot.TrimEnd('\') + '\'
    if (-not $manifestPath.StartsWith($repoPrefix, [System.StringComparison]::OrdinalIgnoreCase)) {
        throw "Approved manifest must be inside the repository: $manifestPath"
    }
    if (-not (Test-Path -LiteralPath $manifestPath -PathType Leaf)) {
        throw "Approved manifest not found: $manifestPath"
    }

    $manifest = Get-Content -LiteralPath $manifestPath -Raw -Encoding UTF8 | ConvertFrom-Json
    if ([int]$manifest.schema_version -ne 1) { throw 'Approved manifest schema_version must be 1.' }
    if ($null -eq $manifest.files) { throw 'Approved manifest must contain a files array.' }

    $seen = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
    foreach ($entry in @($manifest.files)) {
        $path = [string]$entry.path
        $decision = [string]$entry.decision
        if ($decision -eq 'blocked') {
            if ($path) { $blockedManifestFiles.Add($path) }
            continue
        }
        if ($decision -ne 'publish') { throw "Invalid manifest decision for ${path}: $decision" }
        if ($path -notmatch '^_vault/.+\.md$' -or $path.Contains('..') -or [System.IO.Path]::IsPathRooted($path)) {
            throw "Approved path must be a Markdown file below _vault/: $path"
        }
        if (-not $seen.Add($path)) { throw "Duplicate approved path: $path" }
        $hash = ([string]$entry.target_sha256).ToLowerInvariant()
        if ($hash -notmatch '^[0-9a-f]{64}$') { throw "Invalid target_sha256 for approved path: $path" }

        $fullPath = [System.IO.Path]::GetFullPath((Join-Path $repoRoot $path.Replace('/', '\')))
        if (-not $fullPath.StartsWith($repoPrefix, [System.StringComparison]::OrdinalIgnoreCase)) {
            throw "Approved path escapes repository: $path"
        }
        if (-not (Test-Path -LiteralPath $fullPath -PathType Leaf)) {
            $errors.Add("Approved file is missing: $path")
            continue
        }
        $approvedHashes[$path] = $hash
        $markdownFiles += Get-Item -LiteralPath $fullPath
    }
}
else {
    $markdownFiles = @(Get-ChildItem -LiteralPath $vaultRoot -Recurse -File -Filter '*.md' |
        Where-Object { $_.Name -ne '_index.md' } |
        Sort-Object FullName)
}

foreach ($file in $markdownFiles) {
    $content = Get-Content -LiteralPath $file.FullName -Raw -Encoding UTF8
    $relativePath = Get-RelativeRepoPath $file.FullName
    if ($ApprovedManifest) {
        $actualHash = (Get-FileHash -LiteralPath $file.FullName -Algorithm SHA256).Hash.ToLowerInvariant()
        if ($actualHash -ne $approvedHashes[$relativePath]) {
            $invalidFiles.Add($relativePath)
            $errors.Add("Approved file changed after review: $relativePath")
            continue
        }
    }
    $state = Get-PublicationState $content

    switch ($state) {
        'Published' {
            $publishedFiles.Add($relativePath)
            Add-ReferencedAssets -MarkdownPath $file.FullName -Content $content
        }
        'Private' {
            $privateFiles.Add($relativePath)
            if ($ApprovedManifest) { $errors.Add("Approved file is not published: true: $relativePath") }
        }
        default {
            $invalidFiles.Add($relativePath)
            $errors.Add("Missing or invalid explicit published field: $relativePath")
        }
    }
}

$deletedTracked = @()
if (-not $ApprovedManifest) {
    $deletedTracked = @(git -c core.quotepath=false ls-files --deleted -- _vault)
    if ($LASTEXITCODE -ne 0) { throw 'Unable to inspect deleted tracked Vault files.' }
}

if (-not $DryRun -and $errors.Count -eq 0) {
    if (-not $NoReset) {
        if ($ApprovedManifest) {
            foreach ($path in $approvedHashes.Keys) {
                git reset -q HEAD -- $path
                if ($LASTEXITCODE -ne 0) { throw "Unable to clear approved staging path: $path" }
            }
        }
        else {
            git reset -q HEAD -- _vault
            if ($LASTEXITCODE -ne 0) { throw 'Unable to clear the _vault staging scope.' }
        }
    }

    foreach ($path in $deletedTracked) {
        git add -u -- $path
        if ($LASTEXITCODE -ne 0) { throw "Unable to stage deletion: $path" }
    }

    if (-not $ApprovedManifest) {
        foreach ($path in @($privateFiles) + @($invalidFiles)) {
            $tracked = @(git ls-files -- $path)
            if ($LASTEXITCODE -ne 0) { throw "Unable to inspect tracked state: $path" }
            if ($tracked.Count -gt 0) {
                git rm -q -f --cached -- $path
                if ($LASTEXITCODE -ne 0) { throw "Unable to untrack private file: $path" }
            }
        }
    }

    foreach ($path in $publishedFiles) {
        git add -f -- $path
        if ($LASTEXITCODE -ne 0) { throw "Unable to stage published file: $path" }
    }
    foreach ($path in $assetFiles) {
        if ($ApprovedManifest -and -not $NoReset) {
            git reset -q HEAD -- $path
            if ($LASTEXITCODE -ne 0) { throw "Unable to clear approved asset staging path: $path" }
        }
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
if ($ApprovedManifest) {
    Write-Host "  Manifest blocked   : $($blockedManifestFiles.Count)"
    Write-Host "  Publication scope  : approved manifest"
}

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
