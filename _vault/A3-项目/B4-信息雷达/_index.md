---
title: "信息雷达"
layout: vault_index
permalink: /vault/A3-项目/B4-信息雷达/
categories: [信息雷达]
published: true
---

信息雷达 (Signal Radar)——本地优先、证据约束的信息发掘探索平台。

## 项目概述

以"原始数据拉取 → 推演趋势 → 准备预案"三层工作流为核心，提供 Electron + Vue + Element Plus 桌面工作台与 FastAPI 后端。当前以"中国住宅地产基本面"为首个投资领域模板，支持 RSS/Atom 和受控 HTTP JSON 两种采集适配器，默认 30 天后用新证据复盘历史推演。

**不是**荐股、估值或自动交易系统。仓库数据均为合成固定样例，不代表实时市场数据。

## 技术栈

Python 3.11+ | FastAPI | Electron | Vue3 | TypeScript | SQLite | RSS/Atom

## 源项目

`signal-radar`，位于 `D:\DevTools\vs_project\signal-radar`

## 参考文档

- [ARCHITECTURE.md](ARCHITECTURE.md) — 架构、数据流与关键取舍
- [API.md](API.md) — API 和研究包契约
- [VERIFICATION.md](VERIFICATION.md) — 已验证范围与后续增强
- [DESKTOP_UI_AND_CONFIGURATION_PLAN.md](DESKTOP_UI_AND_CONFIGURATION_PLAN.md) — 桌面 UI、来源配置与长期复盘设计
