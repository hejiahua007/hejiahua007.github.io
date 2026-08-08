@echo off
set SRC=d:\DevTools\vs_project\hejiahua007.github.io\_vault\A3-项目\B2-人生管理体系
set DST=d:\DevTools\vs_project\life-vault\_vault\A3-项目\B2-人生管理体系

if not exist "%DST%" mkdir "%DST%"

copy "%SRC%\2026-07-25-life-management-system-discovery.md" "%DST%\" /Y
copy "%SRC%\2026-07-26-life-management-system-prd-v1.md" "%DST%\" /Y
copy "%SRC%\2026-07-11-portfolio-optimization-log.md" "%DST%\" /Y
copy "%SRC%\README-项目总览.md" "%DST%\" /Y

echo Sync Done.
