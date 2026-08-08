---
title: 人生管理体系 - 项目总览
date: 2026-08-08 00:00:00 +0800
categories: [项目, 人生管理体系]
tags: [项目总览, 人生管理, 知识库, 博客]
pin: true
published: true
author: 
    name: hejiahua007
    link: https://space.bilibili.com/507838758
toc: true
comments: true
math: false
mermaid: true
---

# 人生管理体系 - 项目总览

> 给 AI 阅读的项目背景文档。请在此了解项目全貌，帮助查漏补缺。

## 1. 项目背景

我想建立一套可以长期使用的个人系统，解决以下问题：
- 日常记录、计划和知识沉淀混在一起，启动成本高
- 计划依赖高能量状态，通常只能维持半个月
- 完美主义导致逃避和拖延
- 私人和公开内容没有安全边界

核心目标：**以极低成本留下真实记录，再逐步把记录转化为行动、知识、原则和公开作品。**

## 2. 当前架构

### 两个 Git 仓库

| 仓库 | 类型 | 作用 |
|---|---|---|
| `hejiahua007/hejiahua007.github.io` | 公开 | Jekyll 博客 + 分类知识库（网站部署） |
| `hejiahua007/life-vault` | 私有 | 日常记录中继站（公司↔宿舍同步） |

### 工作流程

```
公司电脑                    宿舍电脑
   │                           │
   ├─ life-vault (日常记录)     ├─ 拉取 life-vault
   ├─ VS Code + Git             ├─ 月度迁移到 hejiahua007.github.io/_vault/
   ├─ 写日记/日志/计划          ├─ Obsidian 阅读复习
   │                           ├─ safe-publish.ps1 过滤私密文件
   └─ git push ──────────────→ └─ git push → GitHub Actions 自动部署
```

### _vault/ 目录结构（两个仓库一致）

```
_vault/
├── A1-回忆归档/
│   ├── B1-24年回忆/
│   ├── B2-25年回忆/
│   ├── B3-26年回忆/
│   ├── B2-22年回忆/
│   └── B3-23年回忆/
├── A2-规划/
│   ├── B1-人生曼陀罗图/
│   └── B2-2026年计划/
│       ├── C1-26年计划.md
│       └── C2-8月计划/
│           ├── D1-08月计划.md
│           └── D2-日记录/
├── A3-项目/
│   ├── B1-毕设/
│   ├── B2-人生管理体系/
│   ├── B3-估值雷达/
│   └── B4-信息雷达/
└── A4-知识库/
    ├── B1-基金/
    ├── B2-阅读/
    ├── B3-Python/
    ├── B4-嵌入式/
    └── B5-求职技能/
```

## 3. 文件规范

### Frontmatter 格式

```yaml
---
title: 标题
date: YYYY-MM-DD HH:MM:SS +0800
categories: [主分类, 子分类]
tags: [标签]
pin: false
published: true   # true→上传GitHub；false→仅本地
author: 
    name: hejiahua007
    link: https://space.bilibili.com/507838758
toc: true
comments: true
math: false
mermaid: true
---
```

### published 控制机制

- `published: true` → `safe-publish.ps1` 会 git add → 推送 GitHub → 网站展示
- `published: false` → 脚本跳过 → 仅本地存在 → Obsidian 可读写

## 4. 关键技术组件

### hejiahua007.github.io

| 组件 | 路径 | 作用 |
|---|---|---|
| Jekyll 插件 | `_plugins/vault_generator.rb` | 扫描 _vault/ 注入站点，生成分类索引页 |
| 安全发布脚本 | `tools/safe-publish.ps1` | 按 published 过滤 git add |
| 分类布局 | `_layouts/vault_index.html` | 面包屑 + 子分类 + 文章列表 |
| 导航页 | `_tabs/vault.md` | 侧边栏"知识库"入口 |
| 同步脚本 | `tools/sync.bat` | 从 life-vault 复制文件到 _vault/ |

### life-vault

| 组件 | 作用 |
|---|---|
| `_vault/` 目录 | 与 hejiahua007 完全一致的分类结构 |
| Obsidian 配置 | `.obsidian/` 目录，可直接作为 Vault 打开 |
| 迁移脚本 | `tools/migrate.ps1` (辅助函数) |

## 5. 已完成的改造历史

1. **2026-07-11**: 个人网站优化，从学生博客升级为职业作品集
2. **2026-08-07**: 重构为单目录知识库架构，创建 `_vault/` 四级层级
3. **2026-08-07**: 开发 Jekyll 插件 + 安全发布脚本 + 分类浏览布局
4. **2026-08-07**: 迁移 82 篇旧文章到 _vault/，全部补充 published 字段
5. **2026-08-07**: life-vault 改造为 _vault/ 架构，文件添加 frontmatter
6. **2026-08-08**: 清理旧结构，统一命名规范 (D1/D2)

## 6. 当前 B2 目录下的文件

| 文件 | 内容 | 状态 |
|---|---|---|
| `README-项目总览.md` | 本文件，项目全貌 | 活跃 |
| `2026-07-11-portfolio-optimization-log.md` | 网站优化日志 | 归档 |
| `LIFE_MANAGEMENT_SYSTEM_DISCOVERY.md` | 早期需求探索 | 历史参考 |
| `LIFE_MANAGEMENT_SYSTEM_PRD_V1.md` | v1 PRD | 历史参考 |
| `_index.md` | 目录索引 | 占位 |

## 7. 待办 / 已知问题

- [ ] `_vault/` 中部分子目录只有 `_index.md` 占位，尚未有实际内容（如 B3-估值雷达、B4-信息雷达）
- [ ] `safe-publish.ps1` 有编码兼容问题，需要用 UTF-8 BOM 重写
- [ ] `vault_generator.rb` 只生成了子目录索引页，A1-A4 顶层入口由 `_tabs/vault.md` 手动维护
- [ ] life-vault 的 `_vault/` 中只有 A2-规划 和 A3-项目 有内容，其他目录为空
- [ ] 本地无 Ruby 环境，无法做 Jekyll 构建验证，依赖 GitHub Actions
- [ ] HTTPS 方式 push 不稳定，已切换为 SSH
- [ ] `docs/VAULT_GUIDE.md` 中的目录结构截图已过时

## 8. 月度迁移流程

```
1. 宿舍电脑: cd life-vault && git pull
2. 手动复制 life-vault/_vault/ 文件到 hejiahua007.github.io/_vault/ 对应目录
3. 确认 frontmatter 的 published 字段
4. cd hejiahua007.github.io && .\tools\safe-publish.ps1
5. git commit -m "迁移: YYYY年MM月" && git push
```
