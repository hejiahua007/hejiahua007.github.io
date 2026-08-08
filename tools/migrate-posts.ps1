<#
.SYNOPSIS
    Deprecated compatibility entry point for the legacy _posts migration.

.DESCRIPTION
    The one-time copy migration has already run. Re-running it could overwrite
    Vault content or re-add published:true. This entry now performs a read-only
    audit instead.
#>

param(
    [string]$OutputPath = 'docs/LEGACY_POSTS_AUDIT.md'
)

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$auditScript = Join-Path $scriptDir 'audit-legacy-posts.ps1'
Write-Warning 'migrate-posts.ps1 is deprecated. Running read-only legacy audit.'
& powershell -NoProfile -ExecutionPolicy Bypass -File $auditScript -OutputPath $OutputPath
exit $LASTEXITCODE
