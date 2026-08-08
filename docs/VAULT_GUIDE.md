# Vault 使用与迁移指南

## 架构

本地 `_vault/` 同时是宿舍电脑的长期 Markdown 主库和网站内容源，但二者通过 `published` 严格隔离：

| 状态 | 本地可见 | Git 暂存 | 网站展示 |
|---|---:|---:|---:|
| `published: true` | 是 | 是 | 是 |
| `published: false` | 是 | 否 | 否 |
| 缺失或非法 | 是 | 阻止发布 | 否 |

公开采用 fail-closed：只有明确、唯一、未加引号的布尔值 `true` 才公开。

## 层级

```text
_vault/
├─ A1-回忆归档/   日记、日志、生活记录、阶段回顾
├─ A2-规划/       目标、计划、职业规划
├─ A3-项目/       项目设计、过程、成果和证据
└─ A4-知识库/     可复用知识与阅读笔记
```

文件夹是网站导航层级。A/B/C 前缀只负责排序，不表达文章编号。新文章不再强制 D 编号。

完整机器规则见 [config/vault-taxonomy.json](../config/vault-taxonomy.json)。

## 新建或整理文章

最小 front matter：

```yaml
---
title: "文章标题"
date: 2026-08-08 20:00:00 +0800
tags: []
published: false
---
```

旧文章缺少字段时可以运行：

```powershell
.\tools\normalize-vault-frontmatter.ps1
.\tools\normalize-vault-frontmatter.ps1 -Apply
```

脚本只补缺失字段，并始终将缺失的 `published` 补为 `false`。

## 网站构建行为

`_plugins/vault_generator.rb`：

1. 递归扫描 `_vault/*.md`；
2. 只接收 `published: true`；
3. 从路径推导分类；
4. 生成稳定且唯一的文章 URL；
5. 为分类目录生成索引；
6. 分类数量只统计公开文章；
7. 重写公开文章的相对图片路径并复制图片；
8. 与旧 `_posts` 同名时优先使用 Vault 版本。

## 发布门控

```powershell
.\tools\validate-vault.ps1 -ChangedOnly
.\tools\safe-publish.ps1 -DryRun
.\tools\safe-publish.ps1
```

`safe-publish.ps1`：

- 只清理 `_vault` 范围的暂存状态；
- 保留其他代码的暂存状态；
- 暂存 `published: true`；
- 对 `false` 或非法文件执行本地保留、Git 取消跟踪；
- 暂存公开文章引用的本地资源；
- 图片不存在时失败；
- 不提交、不推送。

## 月度迁移

月度迁移由一个控制脚本和两个窄职责智能体组成：

```text
Prepare → 迁移智能体(JSON) → Apply → 整理智能体(Markdown)
        → 校验 → 人工发布 → Finalize → 人工清理源仓提交
```

完整步骤见 [plan/月度自动化迁移与发布计划.md](../plan/月度自动化迁移与发布计划.md)。

关键安全性：

- Prepare 只生成 inventory；
- 迁移智能体不操作文件；
- Apply 先预检和备份，再复制，禁止覆盖不同内容；
- 整理智能体不能把 `false` 改成 `true`；
- Finalize 需要显式参数，并只删除哈希验证通过的源文件；
- 两个仓库的 commit/push 都由人工执行。

## 旧 Word 规划转换

2026 年一月至七月的 Word 规划可以重复执行以下命令转换：

```powershell
& 'C:\Users\Administrator\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe' `
  .\tools\convert-planning-docx.py `
  --source 'C:\Users\Administrator\Desktop\新建文件夹\规划' `
  --target '.\_vault\A2-规划\B2-2026年计划'
```

脚本使用显式月份映射，保留段落、标题、列表、表格和内嵌图片，并输出每份文件的源文字数与 Markdown 正文字数。转换结果固定为 `published: false`，避免私人计划被意外发布。

## 旧 `_posts`

`_posts` 不再新增。当前先保留文件，构建时按同名去重。运行以下命令更新审计：

```powershell
.\tools\audit-legacy-posts.ps1
```

只有审计为 exact 的文件才有资格后续删除；非 exact 文件必须人工比较。Git 历史可以恢复已删除的旧文件。

## 建议的人工检查

每月正式推送前检查：

1. `validate-vault` 为 0 error；
2. `safe-publish -DryRun` 数量合理；
3. `git diff --cached` 不含私密文章；
4. Agent 整理结果没有新增不存在的事实；
5. 本地图片都能打开；
6. GitHub Actions 构建成功后再 Finalize 源仓。
