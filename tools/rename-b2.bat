@echo off
chcp 65001 >nul
cd /d "d:\DevTools\vs_project\hejiahua007.github.io"

set "DIR=_vault\A3-项目\B2-人生管理体系"

if exist "%DIR%\LIFE_MANAGEMENT_SYSTEM_DISCOVERY.md" (
    echo Renaming LIFE_MANAGEMENT_SYSTEM_DISCOVERY.md...
    move "%DIR%\LIFE_MANAGEMENT_SYSTEM_DISCOVERY.md" "%DIR%\2026-07-25-life-management-system-discovery.md"
) else (
    echo LIFE_MANAGEMENT_SYSTEM_DISCOVERY.md not found
)

if exist "%DIR%\LIFE_MANAGEMENT_SYSTEM_PRD_V1.md" (
    echo Renaming LIFE_MANAGEMENT_SYSTEM_PRD_V1.md...
    move "%DIR%\LIFE_MANAGEMENT_SYSTEM_PRD_V1.md" "%DIR%\2026-07-26-life-management-system-prd-v1.md"
) else (
    echo LIFE_MANAGEMENT_SYSTEM_PRD_V1.md not found
)

echo Done.
