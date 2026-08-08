---
title: 知识库
icon: fas fa-book
order: 3
---

欢迎来到我的知识库。这里按照分类层级组织了我的学习笔记、项目文档和生活记录。

你可以通过下方的分类入口浏览感兴趣的内容，也可以在左侧边栏使用标签和归档功能。

## 分类导览

{% for section in site.data.vault_sections %}
### [{{ section.label }}]({{ section.url | relative_url }})

{{ section.description }}
{% else %}
目前还没有公开的知识库内容。
{% endfor %}

---

> **提示**：你可以使用 [Obsidian](https://obsidian.md/) 打开本项目文件夹 `_vault/` 进行本地阅读和编辑。
