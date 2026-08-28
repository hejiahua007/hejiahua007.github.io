<#
.SYNOPSIS
    Deterministically sync life-vault into this repository without AI routing.

.DESCRIPTION
    Every source keeps the same path below _vault. The script delegates all
    copying and source backup work to monthly-migration.ps1. Existing targets
    with different content are retained and reported; nothing is overwritten
    or deleted.
#>

param(
    [ValidateSet('Plan', 'Apply')]
    [string]$Mode = 'Plan',
    [string]$MigrationId = (Get-Date -Format 'yyyy-MM-dd-HHmmss'),
    [string]$LifeVaultPath
)

$ErrorActionPreference = 'Stop'
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = (Resolve-Path (Join-Path $scriptDir '..')).Path
$controller = Join-Path $scriptDir 'monthly-migration.ps1'

if (-not $LifeVaultPath) {
    $LifeVaultPath = Join-Path (Split-Path -Parent $repoRoot) 'life-vault'
}
$LifeVaultPath = [System.IO.Path]::GetFullPath($LifeVaultPath)

& $controller -Mode Prepare -MigrationId $MigrationId -LifeVaultPath $LifeVaultPath
if ($LASTEXITCODE -ne 0) { throw 'Unable to prepare the migration inventory.' }

$migrationRoot = Join-Path $repoRoot ".migration\$MigrationId"
$inventoryPath = Join-Path $migrationRoot 'inventory.json'
$planPath = Join-Path $migrationRoot 'routing-plan.json'
$inventory = Get-Content -LiteralPath $inventoryPath -Raw -Encoding UTF8 | ConvertFrom-Json

$migrateCount = 0
$identicalCount = 0
$conflicts = [System.Collections.Generic.List[string]]::new()
$items = foreach ($file in $inventory.files) {
    $targetPath = [System.IO.Path]::GetFullPath((Join-Path $repoRoot $file.source.Replace('/', '\')))
    $repoPrefix = $repoRoot.TrimEnd('\') + '\'
    if (-not $targetPath.StartsWith($repoPrefix, [System.StringComparison]::OrdinalIgnoreCase)) {
        throw "Target escapes repository: $($file.source)"
    }

    $action = 'migrate'
    $target = $file.source
    $reason = 'Same-path deterministic sync.'
    if (Test-Path -LiteralPath $targetPath -PathType Leaf) {
        $targetHash = (Get-FileHash -LiteralPath $targetPath -Algorithm SHA256).Hash.ToLowerInvariant()
        if ($targetHash -eq $file.source_sha256) {
            $identicalCount++
            $reason = 'Target already has identical content.'
        }
        else {
            $action = 'retain'
            $target = ''
            $reason = 'Target exists with different content; retained for human review.'
            $conflicts.Add($file.source)
        }
    }
    else {
        $migrateCount++
    }

    [ordered]@{
        source = $file.source
        source_sha256 = $file.source_sha256
        action = $action
        target = $target
        reason = $reason
        confidence = 1.0
    }
}

$plan = [ordered]@{
    schema_version = 1
    migration_id = $MigrationId
    generated_from = $inventoryPath
    items = @($items)
}
$plan | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $planPath -Encoding UTF8

Write-Host ''
Write-Host 'Direct Vault sync plan'
Write-Host "  Source files       : $($inventory.files.Count)"
Write-Host "  New same-path files: $migrateCount"
Write-Host "  Already identical  : $identicalCount"
Write-Host "  Conflicts retained : $($conflicts.Count)"
Write-Host "  Routing plan       : $planPath"
if ($conflicts.Count -gt 0) {
    Write-Host '  Review conflicts:' -ForegroundColor Yellow
    foreach ($path in $conflicts) { Write-Host "    - $path" -ForegroundColor Yellow }
}

if ($Mode -eq 'Apply') {
    & $controller -Mode Apply -MigrationId $MigrationId -LifeVaultPath $LifeVaultPath
    if ($LASTEXITCODE -ne 0) { throw 'Unable to apply the direct Vault sync.' }
}
else {
    Write-Host 'Plan only; no files were copied.' -ForegroundColor Cyan
}
