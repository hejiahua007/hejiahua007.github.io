<#
.SYNOPSIS
    Validate, build, commit, and optionally push public Vault changes.

.EXAMPLE
    .\tools\publish-vault.ps1 -Message 'content: update life records' -Push
#>

param(
    [Parameter(Mandatory = $true)][string]$Message,
    [switch]$Push,
    [switch]$DryRun
)

$ErrorActionPreference = 'Stop'
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = (Resolve-Path (Join-Path $scriptDir '..')).Path
Set-Location $repoRoot

$outsideVault = @(git -c core.quotepath=false status --porcelain=v1 --untracked-files=all | Where-Object {
    if ($_.Length -lt 4) { return $false }
    $path = $_.Substring(3).Trim('"')
    return -not $path.StartsWith('_vault/', [System.StringComparison]::OrdinalIgnoreCase)
})
if ($outsideVault.Count -gt 0) {
    throw "Refusing to publish with unrelated working-tree changes:`n$($outsideVault -join "`n")"
}

& (Join-Path $scriptDir 'validate-vault.ps1')
if ($LASTEXITCODE -ne 0) { throw 'Vault validation failed.' }
& (Join-Path $scriptDir 'safe-publish.ps1') -DryRun
if ($LASTEXITCODE -ne 0) { throw 'Vault publication preview failed.' }
if ($DryRun) {
    Write-Host 'Dry run completed; staging area was not changed.' -ForegroundColor Cyan
    exit 0
}

& (Join-Path $scriptDir 'safe-publish.ps1')
if ($LASTEXITCODE -ne 0) { throw 'Unable to stage public Vault content.' }

bundle exec jekyll clean
if ($LASTEXITCODE -ne 0) { throw 'Unable to clean the generated site.' }
$env:JEKYLL_ENV = 'production'
bundle exec jekyll build --destination _site --config _config.yml
if ($LASTEXITCODE -ne 0) { throw 'Production build failed.' }
bundle exec ruby (Join-Path $scriptDir 'check-built-site.rb') _site
if ($LASTEXITCODE -ne 0) { throw 'Built-site checks failed.' }
& (Join-Path $scriptDir 'audit-public-site.ps1') -SitePath _site
if ($LASTEXITCODE -ne 0) { throw 'Public artifact audit failed.' }
& (Join-Path $scriptDir 'verify-vault-mapping.ps1') -SitePath _site
if ($LASTEXITCODE -ne 0) { throw 'Vault path mapping verification failed.' }

$stagedOutsideVault = @(git -c core.quotepath=false diff --cached --name-only | Where-Object {
    -not $_.StartsWith('_vault/', [System.StringComparison]::OrdinalIgnoreCase)
})
if ($stagedOutsideVault.Count -gt 0) {
    throw "Refusing to commit staged files outside _vault/:`n$($stagedOutsideVault -join "`n")"
}
$staged = @(git diff --cached --name-only)
if ($staged.Count -eq 0) {
    Write-Host 'No public Vault changes to commit.' -ForegroundColor Cyan
    exit 0
}

git commit -m $Message
if ($LASTEXITCODE -ne 0) { throw 'Unable to commit public Vault changes.' }
if ($Push) {
    git push origin HEAD
    if ($LASTEXITCODE -ne 0) { throw 'Unable to push public Vault changes.' }
}
else {
    Write-Host 'Commit created locally. Run git push origin HEAD when ready.' -ForegroundColor Cyan
}
