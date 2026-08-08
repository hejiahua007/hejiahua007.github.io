@echo off
chcp 65001 >nul
set D=d:\DevTools\vs_project\hejiahua007.github.io
set B=%D%\_vault\A3-项目\B2-人生管理体系

copy "%D%\docs\LIFE_MANAGEMENT_SYSTEM_DISCOVERY.md" "%B%\LIFE_MANAGEMENT_SYSTEM_DISCOVERY.md"
copy "%D%\docs\LIFE_MANAGEMENT_SYSTEM_PRD_V1.md" "%B%\LIFE_MANAGEMENT_SYSTEM_PRD_V1.md"
echo Done
