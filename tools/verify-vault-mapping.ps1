<#
.SYNOPSIS
    Verify the public site mirrors every published Markdown path under _vault.
#>

param([string]$SitePath = '_site')

$ErrorActionPreference = 'Stop'
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = (Resolve-Path (Join-Path $scriptDir '..')).Path
$vaultRoot = Join-Path $repoRoot '_vault'
$siteRoot = [System.IO.Path]::GetFullPath((Join-Path $repoRoot $SitePath))
$errors = [System.Collections.Generic.List[string]]::new()
$publishedCount = 0
$expectedFolders = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)

foreach ($file in Get-ChildItem -LiteralPath $vaultRoot -Recurse -File -Filter '*.md') {
    if ($file.Name -eq '_index.md') { continue }
    $content = Get-Content -LiteralPath $file.FullName -Raw -Encoding UTF8
    $match = [regex]::Match($content, '(?s)\A---\s*\r?\n(?<fm>.*?)\r?\n---')
    if (-not $match.Success) { continue }
    $published = [regex]::Matches($match.Groups['fm'].Value, '(?m)^published:\s*true\s*$')
    if ($published.Count -ne 1) { continue }

    $publishedCount++
    $relativePath = $file.FullName.Substring($vaultRoot.TrimEnd('\').Length + 1).Replace('\', '/')
    $articleRelative = 'vault/' + ($relativePath -replace '\.md$', '') + '/index.html'
    $articlePath = Join-Path $siteRoot $articleRelative.Replace('/', '\')
    if (-not (Test-Path -LiteralPath $articlePath -PathType Leaf)) {
        $errors.Add("Missing one-to-one article page: $relativePath => $articleRelative")
    }

    $parts = ($relativePath -replace '/[^/]+$', '') -split '/'
    for ($i = 0; $i -lt $parts.Count; $i++) {
        [void]$expectedFolders.Add(($parts[0..$i] -join '/'))
    }
}

foreach ($folder in $expectedFolders) {
    $folderIndex = Join-Path $siteRoot ("vault/$folder/index.html").Replace('/', '\')
    if (-not (Test-Path -LiteralPath $folderIndex -PathType Leaf)) {
        $errors.Add("Missing public folder page: _vault/$folder")
    }
}

$postPages = @()
$postsRoot = Join-Path $siteRoot 'posts'
if (Test-Path -LiteralPath $postsRoot -PathType Container) {
    $postPages = @(Get-ChildItem -LiteralPath $postsRoot -Recurse -File -Filter 'index.html')
}
if ($postPages.Count -gt 0) {
    $errors.Add("Unexpected flattened /posts pages: $($postPages.Count)")
}

$postLinks = @(Get-ChildItem -LiteralPath $siteRoot -Recurse -File -Filter '*.html' | Where-Object {
    (Get-Content -LiteralPath $_.FullName -Raw -Encoding UTF8) -match '(?i)(?:href|src)=["'']/posts/'
})
if ($postLinks.Count -gt 0) {
    $errors.Add("Generated HTML still links to /posts/: $($postLinks.Count) files")
}

Write-Host ''
Write-Host 'Vault path mapping verification'
Write-Host "  Published articles : $publishedCount"
Write-Host "  Public folders     : $($expectedFolders.Count)"
Write-Host "  Flattened posts    : $($postPages.Count)"
Write-Host "  Errors             : $($errors.Count)"
if ($errors.Count -gt 0) {
    foreach ($message in $errors) { Write-Host "  - $message" -ForegroundColor Red }
    throw "Vault path mapping failed with $($errors.Count) error(s)."
}
Write-Host 'Every public article mirrors its _vault path.' -ForegroundColor Green
