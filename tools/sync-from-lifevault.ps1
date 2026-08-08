<#
.SYNOPSIS
    Deprecated compatibility entry point.

.DESCRIPTION
    The old script copied a hard-coded file list and removed a directory.
    It now performs only the safe Prepare phase of monthly migration.
#>

param(
    [string]$MigrationId = (Get-Date -Format 'yyyy-MM'),
    [string]$LifeVaultPath
)

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$controller = Join-Path $scriptDir 'monthly-migration.ps1'
Write-Warning 'sync-from-lifevault.ps1 is deprecated. Running monthly migration Prepare only.'

$arguments = @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', $controller, '-Mode', 'Prepare', '-MigrationId', $MigrationId)
if ($LifeVaultPath) { $arguments += @('-LifeVaultPath', $LifeVaultPath) }
& powershell @arguments
exit $LASTEXITCODE
