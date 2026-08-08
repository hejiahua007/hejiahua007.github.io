<#
.SYNOPSIS
    Deterministic monthly transfer controller for life-vault.

.DESCRIPTION
    Prepare  - inventory source files and create a routing-plan template.
    Apply    - validate an agent-authored routing plan, back up sources, and copy.
    Finalize - after explicit confirmation, remove only verified migrated sources.

    This script never commits, pulls, or pushes either repository.
#>

param(
    [Parameter(Mandatory = $true)]
    [ValidateSet('Prepare', 'Apply', 'Finalize')]
    [string]$Mode,

    [string]$LifeVaultPath,
    [string]$MigrationId = (Get-Date -Format 'yyyy-MM'),
    [string]$PlanPath,
    [switch]$ConfirmCleanup
)

$ErrorActionPreference = 'Stop'
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = (Resolve-Path (Join-Path $scriptDir '..')).Path
if (-not $LifeVaultPath) {
    $LifeVaultPath = Join-Path (Split-Path -Parent $repoRoot) 'life-vault'
}
$lifeRoot = [System.IO.Path]::GetFullPath($LifeVaultPath)
$sourceRoot = Join-Path $lifeRoot '_vault'
$stateRoot = Join-Path $repoRoot ".migration\$MigrationId"
$inventoryPath = Join-Path $stateRoot 'inventory.json'
$templatePath = Join-Path $stateRoot 'routing-plan.template.json'
$defaultPlanPath = Join-Path $stateRoot 'routing-plan.json'
$manifestPath = Join-Path $stateRoot 'applied-manifest.json'
$backupRoot = Join-Path $stateRoot 'source-backup'

function Get-RelativePath {
    param(
        [Parameter(Mandatory = $true)][string]$Root,
        [Parameter(Mandatory = $true)][string]$Path
    )
    $rootPrefix = [System.IO.Path]::GetFullPath($Root).TrimEnd('\') + '\'
    $fullPath = [System.IO.Path]::GetFullPath($Path)
    if (-not $fullPath.StartsWith($rootPrefix, [System.StringComparison]::OrdinalIgnoreCase)) {
        throw "Path escapes root: $Path"
    }
    return $fullPath.Substring($rootPrefix.Length).Replace('\', '/')
}

function Resolve-SafeChild {
    param(
        [Parameter(Mandatory = $true)][string]$Root,
        [Parameter(Mandatory = $true)][string]$RelativePath
    )
    if ([System.IO.Path]::IsPathRooted($RelativePath)) {
        throw "Absolute paths are not allowed: $RelativePath"
    }
    $normalized = $RelativePath.Replace('/', '\')
    $fullPath = [System.IO.Path]::GetFullPath((Join-Path $Root $normalized))
    $rootPrefix = [System.IO.Path]::GetFullPath($Root).TrimEnd('\') + '\'
    if (-not $fullPath.StartsWith($rootPrefix, [System.StringComparison]::OrdinalIgnoreCase)) {
        throw "Path escapes root: $RelativePath"
    }
    return $fullPath
}

function Get-Sha256 {
    param([Parameter(Mandatory = $true)][string]$Path)
    return (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash.ToLowerInvariant()
}

function Get-PublishedValue {
    param([Parameter(Mandatory = $true)][string]$Path)
    if ([System.IO.Path]::GetExtension($Path) -ne '.md') { return $null }
    $content = Get-Content -LiteralPath $Path -Raw -Encoding UTF8
    if ($content -notmatch '(?s)\A---\s*\r?\n(?<fm>.*?)\r?\n---') { return 'missing' }
    $matches = [regex]::Matches($Matches['fm'], '(?m)^published:\s*(true|false)\s*$')
    if ($matches.Count -ne 1) { return 'missing' }
    return $matches[0].Groups[1].Value
}

function Write-JsonFile {
    param(
        [Parameter(Mandatory = $true)]$Value,
        [Parameter(Mandatory = $true)][string]$Path,
        [int]$Depth = 8
    )
    $directory = Split-Path -Parent $Path
    if (-not (Test-Path -LiteralPath $directory)) {
        New-Item -ItemType Directory -Path $directory -Force | Out-Null
    }
    $json = $Value | ConvertTo-Json -Depth $Depth
    [System.IO.File]::WriteAllText($Path, $json, [System.Text.UTF8Encoding]::new($false))
}

if (-not (Test-Path -LiteralPath $sourceRoot -PathType Container)) {
    throw "life-vault source directory not found: $sourceRoot"
}

if ($Mode -eq 'Prepare') {
    New-Item -ItemType Directory -Path $stateRoot -Force | Out-Null
    $sourceCommit = (& git -C $lifeRoot rev-parse HEAD 2>$null)
    if ($LASTEXITCODE -ne 0) { $sourceCommit = $null }

    $files = @(Get-ChildItem -LiteralPath $sourceRoot -Recurse -File | Sort-Object FullName)
    $items = @($files | ForEach-Object {
        $relative = Get-RelativePath -Root $lifeRoot -Path $_.FullName
        [ordered]@{
            source = $relative
            source_sha256 = Get-Sha256 $_.FullName
            size_bytes = $_.Length
            last_write_time = $_.LastWriteTime.ToString('o')
            kind = if ($_.Extension -eq '.md') { 'markdown' } else { 'asset' }
            published = Get-PublishedValue $_.FullName
        }
    })

    $inventory = [ordered]@{
        schema_version = 1
        migration_id = $MigrationId
        created_at = (Get-Date).ToString('o')
        source_root = $lifeRoot
        source_commit = $sourceCommit
        total_files = $items.Count
        files = $items
    }
    Write-JsonFile -Value $inventory -Path $inventoryPath

    $planItems = @($items | ForEach-Object {
        [ordered]@{
            source = $_.source
            source_sha256 = $_.source_sha256
            action = 'REPLACE_WITH_migrate_OR_retain'
            target = ''
            reason = ''
            confidence = 0.0
        }
    })
    $template = [ordered]@{
        schema_version = 1
        migration_id = $MigrationId
        generated_from = $inventoryPath
        items = $planItems
    }
    Write-JsonFile -Value $template -Path $templatePath

    Write-Host "Inventory: $inventoryPath"
    Write-Host "Plan template: $templatePath"
    Write-Host "Files: $($items.Count)"
    exit 0
}

if (-not $PlanPath) { $PlanPath = $defaultPlanPath }

if ($Mode -eq 'Apply') {
    if (-not (Test-Path -LiteralPath $inventoryPath)) {
        throw "Run Prepare first. Missing: $inventoryPath"
    }
    if (-not (Test-Path -LiteralPath $PlanPath)) {
        throw "Routing plan not found: $PlanPath"
    }

    $inventory = Get-Content -LiteralPath $inventoryPath -Raw -Encoding UTF8 | ConvertFrom-Json
    $plan = Get-Content -LiteralPath $PlanPath -Raw -Encoding UTF8 | ConvertFrom-Json
    if ($plan.migration_id -ne $MigrationId) { throw 'Routing plan migration_id mismatch.' }

    $inventoryBySource = @{}
    foreach ($item in $inventory.files) { $inventoryBySource[$item.source] = $item }
    $planBySource = @{}
    foreach ($item in $plan.items) {
        if ($planBySource.ContainsKey($item.source)) { throw "Duplicate plan source: $($item.source)" }
        $planBySource[$item.source] = $item
    }
    foreach ($source in $inventoryBySource.Keys) {
        if (-not $planBySource.ContainsKey($source)) { throw "Plan omitted source: $source" }
    }
    foreach ($source in $planBySource.Keys) {
        if (-not $inventoryBySource.ContainsKey($source)) { throw "Plan contains unknown source: $source" }
    }

    $operations = [System.Collections.Generic.List[object]]::new()
    $targets = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
    foreach ($source in ($planBySource.Keys | Sort-Object)) {
        $planned = $planBySource[$source]
        $known = $inventoryBySource[$source]
        if ($planned.source_sha256 -ne $known.source_sha256) {
            throw "Plan hash mismatch: $source"
        }
        if ($planned.action -eq 'retain') { continue }
        if ($planned.action -ne 'migrate') { throw "Invalid action for ${source}: $($planned.action)" }
        if ($planned.target -notmatch '^_vault/A\d+-[^/]+(?:/|$)') {
            throw "Target must start with an ordered _vault/A-level folder: $($planned.target)"
        }
        if ([double]$planned.confidence -lt 0.8 -or [double]$planned.confidence -gt 1.0) {
            throw "Migration confidence must be between 0.8 and 1.0: $source"
        }
        if ([System.IO.Path]::GetExtension($source) -ne [System.IO.Path]::GetExtension($planned.target)) {
            throw "Source and target extensions differ: $source"
        }

        $sourcePath = Resolve-SafeChild -Root $lifeRoot -RelativePath $source
        if (-not (Test-Path -LiteralPath $sourcePath -PathType Leaf)) { throw "Source missing: $source" }
        if ((Get-Sha256 $sourcePath) -ne $known.source_sha256) { throw "Source changed after Prepare: $source" }

        $targetPath = Resolve-SafeChild -Root $repoRoot -RelativePath $planned.target
        if (-not $targets.Add($targetPath)) { throw "Duplicate target: $($planned.target)" }
        if (Test-Path -LiteralPath $targetPath) {
            if ((Get-Sha256 $targetPath) -ne $known.source_sha256) {
                throw "Target exists with different content: $($planned.target)"
            }
        }

        $operations.Add([pscustomobject]@{
            source = $source
            source_path = $sourcePath
            source_sha256 = $known.source_sha256
            target = $planned.target
            target_path = $targetPath
            reason = $planned.reason
            confidence = $planned.confidence
        })
    }

    $manifestItems = [System.Collections.Generic.List[object]]::new()
    foreach ($operation in $operations) {
        $backupPath = Resolve-SafeChild -Root $backupRoot -RelativePath $operation.source
        New-Item -ItemType Directory -Path (Split-Path -Parent $backupPath) -Force | Out-Null
        Copy-Item -LiteralPath $operation.source_path -Destination $backupPath -Force

        $existed = Test-Path -LiteralPath $operation.target_path
        if (-not $existed) {
            New-Item -ItemType Directory -Path (Split-Path -Parent $operation.target_path) -Force | Out-Null
            Copy-Item -LiteralPath $operation.source_path -Destination $operation.target_path
        }

        $manifestItems.Add([ordered]@{
            source = $operation.source
            source_sha256 = $operation.source_sha256
            target = $operation.target
            status = if ($existed) { 'already_identical' } else { 'copied' }
            reason = $operation.reason
            confidence = $operation.confidence
        })
    }

    $retained = @($plan.items | Where-Object { $_.action -eq 'retain' } | ForEach-Object { $_.source })
    $manifest = [ordered]@{
        schema_version = 1
        migration_id = $MigrationId
        applied_at = (Get-Date).ToString('o')
        source_root = $lifeRoot
        migrated = @($manifestItems)
        retained = $retained
    }
    Write-JsonFile -Value $manifest -Path $manifestPath
    Write-Host "Applied manifest: $manifestPath"
    Write-Host "Migrated: $($manifestItems.Count)"
    Write-Host "Retained: $($retained.Count)"
    Write-Host 'No source files were deleted.'
    exit 0
}

if (-not $ConfirmCleanup) {
    throw 'Finalize requires -ConfirmCleanup.'
}
if (-not (Test-Path -LiteralPath $manifestPath)) {
    throw "Applied manifest not found: $manifestPath"
}

$manifest = Get-Content -LiteralPath $manifestPath -Raw -Encoding UTF8 | ConvertFrom-Json
foreach ($item in $manifest.migrated) {
    $sourcePath = Resolve-SafeChild -Root $lifeRoot -RelativePath $item.source
    $backupPath = Resolve-SafeChild -Root $backupRoot -RelativePath $item.source
    $targetPath = Resolve-SafeChild -Root $repoRoot -RelativePath $item.target
    if (-not (Test-Path -LiteralPath $sourcePath -PathType Leaf)) { throw "Source already missing: $($item.source)" }
    if (-not (Test-Path -LiteralPath $backupPath -PathType Leaf)) { throw "Backup missing: $($item.source)" }
    if (-not (Test-Path -LiteralPath $targetPath -PathType Leaf)) { throw "Target missing: $($item.target)" }
    if ((Get-Sha256 $sourcePath) -ne $item.source_sha256) { throw "Source changed after Apply: $($item.source)" }
    if ((Get-Sha256 $backupPath) -ne $item.source_sha256) { throw "Backup verification failed: $($item.source)" }
}

foreach ($item in $manifest.migrated) {
    $sourcePath = Resolve-SafeChild -Root $lifeRoot -RelativePath $item.source
    Remove-Item -LiteralPath $sourcePath
}

Get-ChildItem -LiteralPath $sourceRoot -Recurse -Directory |
    Sort-Object FullName -Descending |
    Where-Object { @(Get-ChildItem -LiteralPath $_.FullName -Force).Count -eq 0 } |
    Remove-Item

Write-Host "Removed verified migrated source files: $(@($manifest.migrated).Count)"
Write-Host "Retained source files: $(@($manifest.retained).Count)"
Write-Host 'Review life-vault git diff, then commit and push manually.'
