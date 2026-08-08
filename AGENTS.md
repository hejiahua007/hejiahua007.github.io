# Repository instructions for AI agents

## Scope

Keep this project small. The supported workflow is only:

`life-vault → monthly routing plan → verified copy → optional curation → explicit publication`.

Do not add dashboards, Electron apps, autonomous schedulers, knowledge graphs, or extra agents unless the user separately requests them after the manual workflow has been proven.

## Read before changing content

1. `config/vault-taxonomy.json`
2. `docs/VAULT_GUIDE.md`
3. `plan/月度自动化迁移与发布计划.md`
4. The relevant prompt under `agents/`

## Safety rules

- Never infer public visibility. Only exact YAML boolean `published: true` is public.
- Missing or malformed `published` must become or remain `false`.
- Never run `git add -A` or `git add .` for Vault publication.
- Never commit or push without an explicit human publication review.
- Never overwrite a different target file during migration.
- Never delete life-vault sources before Apply created and verified a backup.
- When classification confidence is below 0.80, retain the source for review.
- Preserve user changes in a dirty worktree.

## Content rules

- `_vault/` is the only source for new articles.
- `_posts/` is legacy and receives no new content.
- Folder hierarchy determines website hierarchy.
- A/B/C prefixes order folders; new article filenames do not require D numbers.
- Keep relative local images beside their Markdown article.
- Curation may remove repetition but must not invent facts or silently discard unique information.

## Required checks

For content changes:

```powershell
.\tools\validate-vault.ps1 -ChangedOnly
.\tools\safe-publish.ps1 -DryRun
```

For monthly transfer, use `tools/monthly-migration.ps1`. Do not reproduce migration behavior with ad-hoc copy/delete commands.
