param(
    [string]$SitePath = '_site'
)

$ErrorActionPreference = 'Stop'
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = (Resolve-Path (Join-Path $scriptDir '..')).Path
$siteRoot = [System.IO.Path]::GetFullPath((Join-Path $repoRoot $SitePath))
$vaultRoot = Join-Path $repoRoot '_vault'

if (-not (Test-Path -LiteralPath $siteRoot -PathType Container)) {
    throw "Built site not found: $siteRoot"
}

$htmlFiles = @(Get-ChildItem -LiteralPath $siteRoot -Recurse -File -Include '*.html','*.xml','*.json','*.txt')
$privateCount = 0
$errors = [System.Collections.Generic.List[string]]::new()

if (Test-Path -LiteralPath $vaultRoot -PathType Container) {
    foreach ($file in Get-ChildItem -LiteralPath $vaultRoot -Recurse -File -Filter '*.md') {
        if ($file.Name -eq '_index.md') { continue }
        $content = Get-Content -LiteralPath $file.FullName -Raw -Encoding UTF8
        $publishedMatches = [regex]::Matches($content, '(?m)^published:\s*(true|false)\s*$')
        $isPublic = $publishedMatches.Count -eq 1 -and $publishedMatches[0].Groups[1].Value -eq 'true'
        if ($isPublic) { continue }

        $privateCount++
        $relativePath = $file.FullName.Substring($vaultRoot.TrimEnd('\').Length + 1).Replace('\', '/')
        $sha1 = [System.Security.Cryptography.SHA1]::Create()
        try {
            $hashBytes = $sha1.ComputeHash([System.Text.Encoding]::UTF8.GetBytes($relativePath))
        }
        finally {
            $sha1.Dispose()
        }
        $digest = ([System.BitConverter]::ToString($hashBytes) -replace '-', '').ToLowerInvariant()
        $postDigest = $digest.Substring(0, 10)
        $assetDigest = $digest.Substring(0, 12)

        $matchingPost = @(Get-ChildItem -LiteralPath (Join-Path $siteRoot 'posts') -Directory -ErrorAction SilentlyContinue |
            Where-Object { $_.Name.EndsWith("-$postDigest", [System.StringComparison]::OrdinalIgnoreCase) })
        if ($matchingPost.Count -gt 0) {
            $errors.Add("Private note generated a public page: $relativePath")
        }
        if (Test-Path -LiteralPath (Join-Path $siteRoot "assets/vault/$assetDigest")) {
            $errors.Add("Private note generated public assets: $relativePath")
        }
    }
}

foreach ($html in $htmlFiles) {
    $content = Get-Content -LiteralPath $html.FullName -Raw -Encoding UTF8
    if ($content -match '(?i)(?:href|src)=["''][^"'']+\.md(?:[?#][^"'']*)?["'']') {
        $errors.Add("Raw Markdown link remains: $($html.FullName.Substring($siteRoot.Length + 1))")
    }

    if ($html.Extension -ne '.html') { continue }

    foreach ($match in [regex]::Matches($content, '(?i)(?:href|src)=["'']([^"'']+)["'']')) {
        $reference = [System.Net.WebUtility]::HtmlDecode($match.Groups[1].Value).Trim()
        if (
            [string]::IsNullOrWhiteSpace($reference) -or
            $reference.StartsWith('#') -or
            $reference.StartsWith('?') -or
            $reference.StartsWith('//') -or
            $reference -match '^[a-z][a-z0-9+.-]*:'
        ) {
            continue
        }

        $pathPart = ($reference -split '[?#]', 2)[0]
        if ([string]::IsNullOrWhiteSpace($pathPart)) { continue }

        try {
            $pathPart = [System.Uri]::UnescapeDataString($pathPart)
        }
        catch {
            $errors.Add("Malformed local URL in $($html.FullName.Substring($siteRoot.Length + 1)): $reference")
            continue
        }

        if ($pathPart.StartsWith('/')) {
            $candidate = Join-Path $siteRoot $pathPart.TrimStart('/').Replace('/', [System.IO.Path]::DirectorySeparatorChar)
        }
        else {
            $candidate = Join-Path $html.DirectoryName $pathPart.Replace('/', [System.IO.Path]::DirectorySeparatorChar)
        }

        $candidate = [System.IO.Path]::GetFullPath($candidate)
        if (-not $candidate.StartsWith($siteRoot, [System.StringComparison]::OrdinalIgnoreCase)) {
            $errors.Add("Local URL leaves the generated site in $($html.FullName.Substring($siteRoot.Length + 1)): $reference")
            continue
        }

        if (Test-Path -LiteralPath $candidate) { continue }
        if (Test-Path -LiteralPath (Join-Path $candidate 'index.html') -PathType Leaf) { continue }

        $errors.Add("Broken local URL in $($html.FullName.Substring($siteRoot.Length + 1)): $reference")
    }
}

if (Test-Path -LiteralPath (Join-Path $siteRoot '_vault')) {
    $errors.Add('The source _vault directory was copied into the public site.')
}

Write-Host ''
Write-Host 'Public artifact audit'
Write-Host "  Site files inspected : $($htmlFiles.Count)"
Write-Host "  Private local notes  : $privateCount"
Write-Host "  Errors               : $($errors.Count)"

if ($errors.Count -gt 0) {
    foreach ($message in $errors) { Write-Host "  - $message" -ForegroundColor Red }
    throw "Public artifact audit failed with $($errors.Count) error(s)."
}

Write-Host 'Public artifact is clean.' -ForegroundColor Green
