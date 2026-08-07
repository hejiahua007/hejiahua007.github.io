# Vault 使用与迁移指南

## 概述

本项目采用了"单目录知识库"架构：

- **`_vault/`**：所有文章统一存放在此，按 A1-A4 四级分类层级组织
- **`tools/safe-publish.ps1`**：发布门控脚本，读取 frontmatter 的 `published` 字段，只将 `true` 的文件 git add
- **`_plugins/vault_generator.rb`**：Jekyll 插件，构建时自动扫描 `_vault/` 并注入站点

## 目录结构

```
_vault/
├── A1-回忆归档/
│   ├── B1-24年回忆/
│   ├── B2-22年回忆/
│   └── B3-23年回忆/
├── A2-规划/
│   ├── B1-人生曼陀罗图/
│   └── B2-2026年计划/
│       └── C1-1月计划/
│           └── E1-日记录/
├── A3-项目/
│   ├── B1-毕设/
│   ├── B2-人生管理体系/
│   ├── B3-估值雷达/
│   └── B4-信息雷达/
└── A4-知识库/
    ├── B1-基金/
    │   ├── C1-基金学习/
    │   ├── C2-低估基金挑选/
    │   └── C3-基金投资计划/
    ├── B2-阅读/
    │   └── C1-书籍：后真相时代/
    ├── B3-Python/
    ├── B4-嵌入式/
    └── B5-求职技能/
```

## 文章 Frontmatter 规范

所有新文章必须包含以下 frontmatter 模板：

```yaml
---
title: "文章标题"
date: YYYY-MM-DD HH:MM:SS +0800
categories: [主分类, 子分类]
tags: [标签1, 标签2]
pin: false
published: true
author:
    name: hejiahua007
    link: https://space.bilibili.com/507838758
toc: true
comments: true
math: false
mermaid: true
---
```

### published 字段说明

| 值 | 含义 | git 行为 | 网站行为 |
|---|---|---|---|
| `true` | 公开 | `safe-publish.ps1` 会 git add | Jekyll 构建并展示 |
| `false` | 私密（仅本地） | `safe-publish.ps1` 跳过，不提交 | 不在站点出现 |

**注意**：`published: false` 的文件存在于本地 `_vault/` 中，可被 Obsidian 正常读写，但永远不会被推送到 GitHub。

## 日常使用

### 1. 写新文章

直接在 `_vault/` 对应分类目录下创建 `.md` 文件，使用上述 frontmatter 模板。

### 2. 使用 Obsidian 阅读编辑

用 Obsidian 打开本项目根目录作为 Vault，即可浏览和编辑 `_vault/` 中所有文件（包括 `published: false` 的私密文件）。

### 3. 发布流程（替代 `git add -A`）

**不要使用 `git add -A` 或 `git add .`！** 使用安全发布脚本：

```powershell
# 预览模式（不实际修改）
.\tools\safe-publish.ps1 -DryRun

# 正式发布
.\tools\safe-publish.ps1

# 然后正常提交推送
git commit -m "your message"
git push
```

脚本会输出详细日志，显示哪些文件被暂存、哪些被排除。

## 每月迁移（life-vault → hejiahua007.github.io）

### 迁移步骤

1. **在宿舍电脑上拉取最新 life-vault**：
   ```powershell
   cd D:\DevTools\vs_project\life-vault
   git pull --rebase
   ```

2. **手动复制文件到 hejiahua007.github.io**：
   - 根据文件内容，将 life-vault 中的文件复制到 `_vault/` 对应分类目录
   - 日记类文件 → `A1-回忆归档/对应年份/`
   - 计划类文件 → `A2-规划/`
   - 项目文件 → `A3-项目/对应项目/`
   - 知识笔记 → `A4-知识库/对应分类/`

3. **添加/调整 frontmatter**：
   - 补充标题、日期、分类、标签等信息
   - **关键**：设置 `published: true` 或 `false`

4. **安全发布**：
   ```powershell
   cd D:\DevTools\vs_project\hejiahua007.github.io
   .\tools\safe-publish.ps1
   git commit -m "迁移：YYYY年MM月 life-vault 内容"
   git push
   ```

### 分类建议

| life-vault 内容 | 迁移到 |
|---|---|
| 日记、日志 | `A1-回忆归档/B?-XX年回忆/` |
| 年/月/日计划 | `A2-规划/B2-2026年计划/` |
| 项目相关笔记 | `A3-项目/B?-项目名/` |
| 技术学习笔记 | `A4-知识库/B?-分类/` |
| 阅读笔记 | `A4-知识库/B2-阅读/` |
| 工作反思 | `A1-回忆归档/` 或 `A2-规划/` |

## 技术说明

### Jekyll 插件工作原理

`_plugins/vault_generator.rb` 在 Jekyll 构建时：

1. 递归扫描 `_vault/` 下所有 `.md` 文件（排除 `_index.md`）
2. 解析 frontmatter，跳过 `published: false` 的文件
3. 从文件路径自动推导 `categories`（如 `_vault/A4-知识库/B3-Python/xxx.md` → `[知识库, Python]`）
4. 动态创建 `Jekyll::Document` 并注入 `site.posts` collection
5. 为每个分类目录生成索引页（面包屑 + 子分类 + 文章列表）

### safe-publish.ps1 工作原理

1. 执行 `git reset` 清空暂存区
2. 递归扫描 `_vault/` 中所有 `.md` 文件
3. 读取每个文件的 YAML frontmatter
4. 匹配 `published:` 字段：
   - `true` 或未设置 → `git add` 该文件
   - `false` → 跳过，输出黄色日志
5. 输出统计：暂存数、排除数、总计

## 常见问题

**Q: published: false 的文件在 Obsidian 中能看到吗？**
A: 可以。这些文件存在于本地 `_vault/` 中，Obsidian 正常读写。

**Q: 不小心用 git add -A 提交了私密文件怎么办？**
A: 使用 `safe-publish.ps1` 重置后再操作。如果已经推送，需要从 git 历史中清理。

**Q: 旧文章（_posts/ 下的）怎么处理？**
A: 已全部迁移到 `_vault/` 对应分类目录。`_posts/` 保留作为备份，后续可以清理。

**Q: 如何新增一个分类？**
A: 在 `_vault/` 下创建新目录，放入 `_index.md` 占位文件，插件会自动识别。
