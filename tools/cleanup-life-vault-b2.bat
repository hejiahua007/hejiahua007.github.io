@echo off
chcp 65001 >nul
cd /d "d:\DevTools\vs_project\life-vault"

set "DIR=_vault\A3-项目\B2-人生管理体系"

if exist "%DIR%\LIFE_MANAGEMENT_SYSTEM_DISCOVERY.md" (
    echo Deleting old: LIFE_MANAGEMENT_SYSTEM_DISCOVERY.md
    del "%DIR%\LIFE_MANAGEMENT_SYSTEM_DISCOVERY.md"
)

if exist "%DIR%\LIFE_MANAGEMENT_SYSTEM_PRD_V1.md" (
    echo Deleting old: LIFE_MANAGEMENT_SYSTEM_PRD_V1.md
    del "%DIR%\LIFE_MANAGEMENT_SYSTEM_PRD_V1.md"
)

echo Cleanup done.
