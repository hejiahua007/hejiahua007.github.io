@echo off
chcp 65001 >nul
cd /d "d:\DevTools\vs_project\life-vault"

set "DIR=_vault\A3-项目\B2-人生管理体系"

git add "%DIR%\2026-07-25-life-management-system-discovery.md"
git add "%DIR%\2026-07-26-life-management-system-prd-v1.md"
git add "%DIR%\README-项目总览.md"
git rm "%DIR%\LIFE_MANAGEMENT_SYSTEM_DISCOVERY.md"
git rm "%DIR%\LIFE_MANAGEMENT_SYSTEM_PRD_V1.md"

git commit -m "sync: rename B2 files to YYYY-MM-DD-slug convention"
git push origin main

echo Done.
