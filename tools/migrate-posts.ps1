<#
.SYNOPSIS
    将 _posts/ 中的文章按分类映射迁移到 _vault/ 目录
#>

$ErrorActionPreference = "Stop"
$repoRoot = "d:\DevTools\vs_project\hejiahua007.github.io"
$postsDir = Join-Path $repoRoot "_posts"
$vaultDir = Join-Path $repoRoot "_vault"

# 分类映射表 (filename -> target_relative_dir)
$mapping = @{
    # === A1-回忆归档 ===
    "2022-05-21-hello-world.md" = "A1-回忆归档/B2-22年回忆"
    "2023-10-13-diary1.md" = "A1-回忆归档/B3-23年回忆"
    "2023-10-14-diary2.md" = "A1-回忆归档/B3-23年回忆"
    "2023-10-16-diary3.md" = "A1-回忆归档/B3-23年回忆"
    "2023-10-16-diary4.md" = "A1-回忆归档/B3-23年回忆"
    "2023-10-24-diary5.md" = "A1-回忆归档/B3-23年回忆"
    "2023-10-25-diary6.md" = "A1-回忆归档/B3-23年回忆"
    "2023-10-28-diary7.md" = "A1-回忆归档/B3-23年回忆"
    "2023-10-25-music_maker.md" = "A1-回忆归档/B3-23年回忆"
    "2023-12-17-novel_1.md" = "A1-回忆归档/B3-23年回忆"
    "2024-04-18-survival-challenge-8.md" = "A1-回忆归档/B1-24年回忆"
    "2024-04-18-survival-challenge-9.md" = "A1-回忆归档/B1-24年回忆"
    "2024-06-18-survival-challenge-10.md" = "A1-回忆归档/B1-24年回忆"
    "2024-03-21-novel_2.md" = "A1-回忆归档/B1-24年回忆"

    # === A3-项目/B1-毕设 ===
    "2023-10-13-yuyin.md" = "A3-项目/B1-毕设"
    "2023-10-13-yuyinhecheng.md" = "A3-项目/B1-毕设"
    "2023-10-14-chat.md" = "A3-项目/B1-毕设"
    "2023-10-24-chat.md" = "A3-项目/B1-毕设"
    "2023-10-26-translate.md" = "A3-项目/B1-毕设"
    "2023-10-29-raspberry_chat.md" = "A3-项目/B1-毕设"
    "2023-11-05-raspberry_speaking.md" = "A3-项目/B1-毕设"
    "2023-11-27-raspberry_finial.md" = "A3-项目/B1-毕设"
    "2023-11-28-raspberry-beiwanglu.md" = "A3-项目/B1-毕设"
    "2023-11-28-raspberry-clock.md" = "A3-项目/B1-毕设"
    "2023-11-28-raspberry-geyan.md" = "A3-项目/B1-毕设"
    "2023-11-28-raspberry-sqlite3.md" = "A3-项目/B1-毕设"
    "2023-11-28-raspberry-tcp_server.md" = "A3-项目/B1-毕设"
    "2023-11-28-raspberry_musicplay.md" = "A3-项目/B1-毕设"
    "2023-11-28-raspberry_time.md" = "A3-项目/B1-毕设"
    "2023-11-28-raspberry_weather_forecast.md" = "A3-项目/B1-毕设"
    "2023-12-25-Android_fenxi.md" = "A3-项目/B1-毕设"
    "2024-02-07-raspberry_zhuangtaijiance.md" = "A3-项目/B1-毕设"
    "2024-02-07-raspberry_zhuangtaijiance1.md" = "A3-项目/B1-毕设"
    "2024-04-08-raspberry_zhuangtaijiance3.md" = "A3-项目/B1-毕设"
    "2024-04-08-raspberry_zhuangtaijiance4.md" = "A3-项目/B1-毕设"
    "2024-05-18-raspberry_zhuangtaijiance5.md" = "A3-项目/B1-毕设"
    "2024-05-23-raspberry_zhiling.md" = "A3-项目/B1-毕设"
    "2024-03-21-bisheceshi1.md" = "A3-项目/B1-毕设"
    "2024-04-26-Android_youhua1.md" = "A3-项目/B1-毕设"

    # === A3-项目/B2-人生管理体系 ===
    "2026-07-11-portfolio-optimization-log.md" = "A3-项目/B2-人生管理体系"

    # === A4-知识库/B3-Python ===
    "2023-10-14-pythonvenv.md" = "A4-知识库/B3-Python"
    "2023-10-24-python_async.md" = "A4-知识库/B3-Python"
    "2023-10-24-python_async2.md" = "A4-知识库/B3-Python"
    "2023-10-24-python_async3.md" = "A4-知识库/B3-Python"
    "2023-10-24-python_bingfa.md" = "A4-知识库/B3-Python"
    "2023-10-24-python_class.md" = "A4-知识库/B3-Python"
    "2023-10-24-python_duoxiancheng.md" = "A4-知识库/B3-Python"
    "2023-10-24-python_suo.md" = "A4-知识库/B3-Python"
    "2023-10-24-python_xianchengchi.md" = "A4-知识库/B3-Python"
    "2023-10-24-python_xianchengtongxin.md" = "A4-知识库/B3-Python"
    "2023-10-24-python_xiecheng.md" = "A4-知识库/B3-Python"
    "2023-10-24-python_xinxigeli.md" = "A4-知识库/B3-Python"
    "2023-10-24-python_yield.md" = "A4-知识库/B3-Python"

    # === A4-知识库/B4-嵌入式 ===
    "2023-10-13-process1.md" = "A4-知识库/B4-嵌入式"
    "2023-10-13-process2.md" = "A4-知识库/B4-嵌入式"
    "2023-10-26-raspberry_wake.md" = "A4-知识库/B4-嵌入式"
    "2023-10-28-raspberry_recongnize.md" = "A4-知识库/B4-嵌入式"
    "2023-11-16-raspberry_python3.7_change.md" = "A4-知识库/B4-嵌入式"
    "2023-10-29-NTC.md" = "A4-知识库/B4-嵌入式"
    "2023-12-07-stm32f103_chuankou.md" = "A4-知识库/B4-嵌入式"
    "2023-12-07-stm32f103_esp8266.md" = "A4-知识库/B4-嵌入式"
    "2023-12-07-stm32f103_guangzhao.md" = "A4-知识库/B4-嵌入式"
    "2023-12-07-stm32f103_qiti.md" = "A4-知识库/B4-嵌入式"
    "2023-12-07-stm32f103_voice.md" = "A4-知识库/B4-嵌入式"
    "2023-12-07-stm32f103_wenduchuanganqi.md" = "A4-知识库/B4-嵌入式"
    "2023-12-07-stm32f103_wifi.md" = "A4-知识库/B4-嵌入式"
    "2024-01-13-ESP01_qianyan.md" = "A4-知识库/B4-嵌入式"
    "2024-01-25-ESP01_zhiwuqi.md" = "A4-知识库/B4-嵌入式"
    "2024-01-26-ESP01_duoji.md" = "A4-知识库/B4-嵌入式"
    "2024-01-26-ESP01_fengshan.md" = "A4-知识库/B4-嵌入式"
    "2024-02-02-stm32f103_tiaoshi.md" = "A4-知识库/B4-嵌入式"

    # === A4-知识库/B5-求职技能 ===
    "2023-10-13-mainshixuzhi.md" = "A4-知识库/B5-求职技能"
    "2023-10-13-mainshiyinhang.md" = "A4-知识库/B5-求职技能"
    "2023-10-14-jisuanjijichu1.md" = "A4-知识库/B5-求职技能"
    "2023-10-14-jisuanjijichu2.md" = "A4-知识库/B5-求职技能"
    "2023-10-14-jisuanjijichu3.md" = "A4-知识库/B5-求职技能"
    "2023-10-14-jisuanjijichu4.md" = "A4-知识库/B5-求职技能"
    "2023-10-17-jisuanjijichu5.md" = "A4-知识库/B5-求职技能"
    "2023-10-17-jisuanjijichu6.md" = "A4-知识库/B5-求职技能"
    "2023-10-18-jisuanjijichu7.md" = "A4-知识库/B5-求职技能"
    "2024-03-16-search.md" = "A4-知识库/B5-求职技能"

    # === A4-知识库/B2-阅读 ===
    "2023-10-18-yuedu.md" = "A4-知识库/B2-阅读"
}

$copied = 0
$skipped = 0
$errors = 0

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  文章迁移: _posts/ → _vault/" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

foreach ($filename in $mapping.Keys | Sort-Object) {
    $src = Join-Path $postsDir $filename
    $targetDir = Join-Path $vaultDir $mapping[$filename]
    $dest = Join-Path $targetDir $filename

    if (-not (Test-Path $src)) {
        Write-Host "  [MISS] $filename — 源文件不存在" -ForegroundColor Red
        $errors++
        continue
    }

    if (-not (Test-Path $targetDir)) {
        New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
    }

    # 读取源文件
    $content = Get-Content $src -Raw -Encoding UTF8

    # 检查是否已有 published 字段
    if ($content -match '^---\s*\r?\n(.*?)\r?\n---') {
        $fm = $Matches[1]
        if ($fm -notmatch 'published:') {
            # 在 frontmatter 中插入 published: true
            $content = $content -replace '^(---\s*\r?\n)', "`$1published: true`r`n"
            Write-Host "  [ADD published] $filename" -ForegroundColor DarkGray
        }
    } else {
        Write-Host "  [WARN] $filename — 无 frontmatter，跳过" -ForegroundColor Yellow
        $skipped++
        continue
    }

    # 复制文件
    try {
        [System.IO.File]::WriteAllText($dest, $content, [System.Text.UTF8Encoding]::new($false))
        Write-Host "  [COPY] $filename → $($mapping[$filename])/" -ForegroundColor Green
        $copied++
    }
    catch {
        Write-Host "  [ERROR] $filename — $_" -ForegroundColor Red
        $errors++
    }
}

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "  迁移完成" -ForegroundColor Cyan
Write-Host "  已复制: $copied  跳过: $skipped  错误: $errors" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
