# Story 4.2: 备份导入与恢复

Status: done

## Story

As a **user**,
I want **to restore my data from a backup file**,
So that **I can recover my data on a new device**.

## Acceptance Criteria

1. **入口:** 设置页 → 备份与恢复 Section，点击"导入恢复"
2. **警告确认:** FriendlyDialog 警告"导入备份会覆盖现有数据哦，确定继续吗？"
3. **文件选择:** 确认后打开系统文件选择器选择 JSON 文件
4. **校验:** 验证文件 SHA-256 校验和（FR23）
5. **恢复数据:** 校验通过后，覆盖所有数据完全恢复（FR22）
6. **成功提示:** FriendlyDialog 显示"恢复成功！共找回 X 条记录，一条不少 ✓"
7. **校验失败:** 校验和不匹配时显示"这个文件好像不是 FreeLedger 的备份文件，请重新选择"（FR26）

## Tasks / Subtasks

- [x] Task 1: BackupService 扩展 — 导入恢复 (AC: #4, #5, #7)
  - [x] 1.1 importBackup(data:) — JSONDecoder + SHA-256 校验和验证
  - [x] 1.2 恢复数据 — dbQueue.write 事务批量 DELETE + INSERT
  - [x] 1.3 BackupError enum (invalidFile / checksumMismatch)
- [x] Task 2: SettingsView 集成 (AC: #1, #2, #3, #6, #7)
  - [x] 2.1 导入恢复按钮
  - [x] 2.2 FriendlyDialog 覆盖警告 (.destructive) → 确认后 .fileImporter
  - [x] 2.3 FriendlyDialog 成功提示 + alert 失败提示
  - [x] 2.4 onDataRestored 回调刷新 HomeView
  - [x] 2.5 Security-scoped URL 访问
- [x] Task 3: i18n + 编译验证 (AC: all)
  - [x] 3.1 补充 Localizable.strings — 6 新字符串 × 2

## Dev Notes

### References

- [Source: epics.md#Story 4.2] — Acceptance Criteria

## Dev Agent Record

### Agent Model Used
Claude Sonnet 4 via Windsurf Cascade

### Completion Notes List
- BackupService.importBackup: JSONDecoder + SHA-256 校验 + 事务批量写入
- BackupError: invalidFile / checksumMismatch
- SettingsView: 导入恢复按钮 + 覆盖警告 (.destructive) + .fileImporter + 成功/失败提示
- Security-scoped URL: startAccessingSecurityScopedResource / defer stop
- onDataRestored 回调刷新 homeViewModel
- Build: 0 errors, 0 warnings

### Change Log
- 2026-02-14: Story 4.2 实现 — 备份导入与恢复

### File List
- ios/FreeLedger/data/service/BackupService.swift (modified — +importBackup + BackupError)
- ios/FreeLedger/ui/settings/SettingsView.swift (modified — +import flow)
- ios/FreeLedger/ContentView.swift (modified — +onDataRestored callback)
- ios/FreeLedger/i18n/Localizable.strings (modified — 6 new strings)
- ios/FreeLedger/i18n/en.lproj/Localizable.strings (modified — 6 new strings)
