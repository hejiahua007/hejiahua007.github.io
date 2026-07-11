# 网站内容维护指南

## 分支职责

- `main`：唯一需要日常编辑和提交的源码分支。
- `gh-pages`：GitHub Actions 自动生成的静态网页分支，不要手工修改。

发布链路：`main` → Actions 执行 `tools/deploy.sh` → `gh-pages` → GitHub Pages。

## 内容目录

```text
_posts/                    所有需要发布的文章
assets/blog_res/           文章图片和附件
_tabs/projects.md          作品集页面
_tabs/about.md             在线简历
docs/CONTENT_GUIDE.md      本维护说明
```

不要再次创建 `_posts/_posts/`。

## 文章命名

文章必须直接放在 `_posts/`，文件名使用：

```text
YYYY-MM-DD-slug.md
```

例如：

```text
2026-07-11-portfolio-optimization-log.md
2026-07-12-pa-agent-development-log.md
```

## Front Matter 模板

```yaml
---
title: 标题
date: 2026-07-11 20:00:00 +0800
categories: [项目日志, PA Agent]
tags: [Python, PyQt6, AI]
pin: false
toc: true
comments: true
---
```

## 推荐分类

- `项目日志 / 项目名称`
- `每日日志`
- `技术笔记 / 技术方向`
- `生活记录`
- `阅读笔记`

分类用于建立层级，标签用于描述技术关键词。不要把同一个概念同时创建多个不同写法，例如 `Python`、`python` 和 `PYTHON`。

## 图片

每篇文章建立独立资源目录：

```text
assets/blog_res/YYYY-MM-DD-slug/
```

引用方式：

```markdown
![说明](/assets/blog_res/YYYY-MM-DD-slug/image.png)
```

## 发布步骤

```bash
git add .
git commit -m "docs: 新增某项目开发日志"
git push origin main
```

推送后查看 GitHub Actions。构建成功后，生成的网站会自动进入 `gh-pages`。
