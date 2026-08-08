$ErrorActionPreference = "Stop"
$life = "D:\DevTools\vs_project\life-vault"
$blog = "D:\DevTools\vs_project\hejiahua007.github.io"

$copies = @(
    @{Src="_vault\A2-规划\B2-2026年计划\C1-26年计划.md"; Dst="_vault\A2-规划\B2-2026年计划\C1-26年计划.md"},
    @{Src="_vault\A2-规划\B2-2026年计划\C2-8月计划\D1-08月计划.md"; Dst="_vault\A2-规划\B2-2026年计划\C2-8月计划\D1-08月计划.md"},
    @{Src="_vault\A2-规划\B2-2026年计划\C2-8月计划\D2-日记录\2026年08月03日记录.md"; Dst="_vault\A2-规划\B2-2026年计划\C2-8月计划\D2-日记录\2026年08月03日记录.md"},
    @{Src="_vault\A2-规划\B2-2026年计划\C2-8月计划\D2-日记录\2026年08月04日记录.md"; Dst="_vault\A2-规划\B2-2026年计划\C2-8月计划\D2-日记录\2026年08月04日记录.md"},
    @{Src="_vault\A2-规划\B2-2026年计划\C2-8月计划\D2-日记录\2026年08月05日记录.md"; Dst="_vault\A2-规划\B2-2026年计划\C2-8月计划\D2-日记录\2026年08月05日记录.md"},
    @{Src="_vault\A2-规划\B2-2026年计划\C2-8月计划\D2-日记录\2026年08月06日记录.md"; Dst="_vault\A2-规划\B2-2026年计划\C2-8月计划\D2-日记录\2026年08月06日记录.md"},
    @{Src="_vault\A2-规划\B2-2026年计划\C2-8月计划\D2-日记录\2026年08月07日记录.md"; Dst="_vault\A2-规划\B2-2026年计划\C2-8月计划\D2-日记录\2026年08月07日记录.md"}
)

foreach ($c in $copies) {
    $src = Join-Path $life $c.Src
    $dst = Join-Path $blog $c.Dst
    $ddir = Split-Path $dst -Parent
    if (!(Test-Path $ddir)) { New-Item -ItemType Directory -Path $ddir -Force | Out-Null }
    Copy-Item $src $dst -Force
    Write-Host "OK: $($c.Src)"
}

# Remove old empty C1-1月计划 directory
$old = Join-Path $blog "_vault\A2-规划\B2-2026年计划\C1-1月计划"
if (Test-Path $old) {
    Remove-Item $old -Recurse -Force
    Write-Host "Removed old: C1-1月计划/"
}

Write-Host "Sync complete."
