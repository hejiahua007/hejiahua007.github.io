# 何嘉华的生活花园

访问地址：[https://hejiahua007.github.io](https://hejiahua007.github.io)

这是一个关于生活、阅读、创造和成长的个人数字花园。网站基于 Jekyll 自建主题，公开目录严格对应本地 `_vault`，只有明确标记为 `published: true` 的内容才会进入 GitHub 和网站。

## 本地运行

```bash
bundle install
bundle exec jekyll serve
```

从 `life-vault` 原路径同步（默认只生成计划，不复制）：

```powershell
.\tools\sync-from-lifevault.ps1 -Mode Plan
.\tools\sync-from-lifevault.ps1 -Mode Apply
```

直接在 `_vault/` 中增加或移动文件后，用一个命令完成公开校验、构建、提交和推送：

```powershell
.\tools\publish-vault.ps1 -Message "content: 更新生活记录" -Push
```
