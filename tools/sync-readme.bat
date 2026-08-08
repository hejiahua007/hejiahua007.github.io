@echo off
chcp 65001 >nul
set SRC=d:\DevTools\vs_project\hejiahua007.github.io\_vault\A3-项目\B2-人生管理体系\README-项目总览.md
set DST=d:\DevTools\vs_project\life-vault\_vault\A3-项目\B2-人生管理体系\README-项目总览.md
copy "%SRC%" "%DST%"
echo Done
