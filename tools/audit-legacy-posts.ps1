<#
.SYNOPSIS
    Compare legacy _posts files with migrated _vault copies.

.DESCRIPTION
    Read-only. A file is exact when its content matches after removing only the
    published field added during migration and normalizing line endings.
#>

param(
    [string]$OutputPath = 'docs/LEGACY_POSTS_AUDIT.md'
)

$ErrorActionPreference = 'Stop'
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = (Resolve-Path (Join-Path $scriptDir '..')).Path
$postsRoot = Join-Path $repoRoot '_posts'
$vaultRoot = Join-Path $repoRoot '_vault'

function Normalize-Content {
    param([string]$Content)
    return (($Content -replace '(?m)^published:\s*(true|false)\s*\r?\n', '') -replace "`r`n", "`n").TrimEnd()
}

$rows = [System.Collections.Generic.List[object]]::new()
foreach ($post in (Get-ChildItem -LiteralPath $postsRoot -File -Filter '*.md' | Sort-Object Name)) {
    $matches = @(Get-ChildItem -LiteralPath $vaultRoot -Recurse -File -Filter $post.Name)
    $exactTarget = $null
    $postContent = Normalize-Content (Get-Content -LiteralPath $post.FullName -Raw -Encoding UTF8)
    foreach ($match in $matches) {
        $vaultContent = Normalize-Content (Get-Content -LiteralPath $match.FullName -Raw -Encoding UTF8)
        if ($postContent -eq $vaultContent) {
            $exactTarget = $match.FullName.Substring($repoRoot.Length + 1).Replace('\', '/')
            break
        }
    }
    $rows.Add([ordered]@{
        post = "_posts/$($post.Name)"
        match_count = $matches.Count
        exact = [bool]$exactTarget
        target = $exactTarget
        decision = if ($exactTarget) { 'safe-to-remove-after-review' } else { 'keep-and-review' }
    })
}

$exactCount = @($rows | Where-Object { $_.exact }).Count
$reviewRows = @($rows | Where-Object { -not $_.exact })
$lines = [System.Collections.Generic.List[string]]::new()
$lines.Add('# Legacy _posts audit')
$lines.Add('')
$lines.Add("> Generated: $((Get-Date).ToString('yyyy-MM-dd HH:mm:ss zzz'))")
$lines.Add('')
$lines.Add("- Legacy posts: $($rows.Count)")
$lines.Add("- Exact migrated copies: $exactCount")
$lines.Add("- Require review: $($reviewRows.Count)")
$lines.Add('')
$lines.Add('The script is read-only. No legacy file was deleted.')
$lines.Add('')
$lines.Add('## Require review')
$lines.Add('')
if ($reviewRows.Count -eq 0) {
    $lines.Add('- None')
}
else {
    foreach ($row in $reviewRows) {
        $lines.Add(('- `{0}` - matches={1}; decision={2}' -f $row.post, $row.match_count, $row.decision))
    }
}
$lines.Add('')
$lines.Add('## Exact migrated copies')
$lines.Add('')
foreach ($row in ($rows | Where-Object { $_.exact })) {
    $lines.Add(('- `{0}` -> `{1}`' -f $row.post, $row.target))
}

$fullOutputPath = if ([System.IO.Path]::IsPathRooted($OutputPath)) { $OutputPath } else { Join-Path $repoRoot $OutputPath }
[System.IO.File]::WriteAllLines($fullOutputPath, $lines, [System.Text.UTF8Encoding]::new($false))
Write-Host "Audit: $fullOutputPath"
Write-Host "Exact: $exactCount"
Write-Host "Review: $($reviewRows.Count)"
