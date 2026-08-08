# 智能体入口

本项目只保留两个窄职责智能体：

1. [迁移智能体](./migration-agent.md)：读取 inventory，输出 JSON 路由计划，不操作文件。
2. [整理智能体](./curation-agent.md)：只整理已复制的目标 Markdown，不决定公开、不执行 Git。

确定性操作由脚本完成：

```text
monthly-migration Prepare
  → 迁移智能体输出 routing-plan.json
  → monthly-migration Apply
  → 整理智能体修改目标副本
  → validate-vault
  → safe-publish -DryRun
  → 人工检查
  → safe-publish
  → 人工 commit/push
  → monthly-migration Finalize -ConfirmCleanup
  → 人工检查并提交 life-vault 清理
```

低成本模型失败时可以重新执行智能体，因为 Prepare 和 Apply 都不会删除源文件；Apply 遇到目标冲突会停止，不会覆盖。
