# 网站内容维护指南

## 唯一内容源

新内容只写入 `_vault/`。网站展示层级由 `_vault` 的文件夹层级决定。

```text
_vault/
├─ A1-回忆归档/
├─ A2-规划/
├─ A3-项目/
└─ A4-知识库/
```

`_posts/` 是旧文章过渡区，不再新增。构建插件遇到与 `_vault` 同名的旧文章时优先使用 `_vault`，避免重复页面。旧文件审计见 [LEGACY_POSTS_AUDIT.md](./LEGACY_POSTS_AUDIT.md)。

## 文件命名

- A/B/C 前缀只给文件夹排序；
- 时间记录：`YYYY年MM月DD日-简短标题.md`；
- 长期文章：`简短语义标题.md`；
- 新文章不要求 D 编号；
- 旧 D 编号和旧英文日期文件名暂不批量修改，以免破坏历史链接。

## 最小 Front Matter

```yaml
---
title: 文章标题
date: 2026-08-08 20:00:00 +0800
tags: [标签1, 标签2]
published: false
---
```

- `categories` 可不填写，由目录自动推导；
- `published` 必须显式为布尔值；
- 新文件默认 `false`，人工决定公开时再改为 `true`；
- 缺字段、字符串形式或重复字段都会阻止发布。

## 图片

推荐将图片与文章放在同一目录并使用相对引用：

```text
_vault/A3-项目/B7-PA Agent/
├─ 功能说明.md
└─ chart.png
```

```markdown
![图表](chart.png)
```

Vault 构建插件会把明确公开文章引用的本地图片复制到公开资源目录。`safe-publish.ps1` 只暂存公开文章真正引用到的资源。

也兼容已有的绝对资源路径：

```markdown
![图表](/assets/blog_res/example/chart.png)
```

## 发布

### 直接维护网站 Vault

只需要在 `_vault/` 的目标文件夹中增加或移动 Markdown 和相对图片，不需要修改 `_posts`、页面配置或 `_site`。文章网页地址自动等于其 Vault 相对路径。

先预演：

```powershell
.\tools\publish-vault.ps1 -Message "content: 内容说明" -DryRun
```

确认后发布：

```powershell
.\tools\publish-vault.ps1 -Message "content: 内容说明" -Push
```

脚本会依次验证 front matter、仅暂存 `published: true`、清理并构建 `_site`、检查网页与 `_vault` 路径一一对应、提交，并在指定 `-Push` 时推送。

### 从 life-vault 同步

同一层级直接同步，不调用 AI、不分类、不改名：

```powershell
.\tools\sync-from-lifevault.ps1 -Mode Plan
.\tools\sync-from-lifevault.ps1 -Mode Apply
```

同路径同内容会跳过；新文件会原路径复制；同路径不同内容会保留源文件并列入冲突报告，禁止覆盖。同步不会删除 `life-vault` 文件。

不要使用 `git add -A` 发布 Vault 内容。`.gitignore` 默认忽略 `_vault`，发布脚本只强制加入明确公开的文件和资源。

## 分支

- `main`：源码和公开内容；
- `gh-pages`：GitHub Actions 生成，不手工修改。

发布链路：`main → GitHub Actions → tools/deploy.sh → gh-pages → GitHub Pages`。
