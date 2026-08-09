# 何嘉华的生活花园

访问地址：[https://hejiahua007.github.io](https://hejiahua007.github.io)

这是一个关于生活、阅读、创造和成长的个人数字花园。网站基于 Jekyll 自建主题，公开目录严格对应本地 `_vault`，只有明确标记为 `published: true` 的内容才会进入 GitHub 和网站。

## 本地运行

```bash
bundle install
bundle exec jekyll serve
```

正式发布 Vault 内容前必须运行：

```powershell
.\tools\validate-vault.ps1 -ChangedOnly
.\tools\safe-publish.ps1 -DryRun
.\tools\safe-publish.ps1
```
