# Story 4.3: 备份提醒

Status: done

## Story

As a **user**,
I want **to be reminded to backup my data**,
So that **I don't forget and risk losing everything**.

## Acceptance Criteria

1. **首次提醒:** 记录 50+ 条交易且从未备份过时，App 启动时弹出提醒（FR24）
2. **定期提醒:** 上次备份距今超过 30 天时，App 启动时弹出提醒（FR25）
3. **提醒内容:** 友好提示文案，引导用户去设置页备份
4. **记录备份时间:** 导出备份成功后自动记录 last_backup_date 到 settings
5. **不重复打扰:** 用户关闭提醒后本次启动不再弹出

## Tasks / Subtasks

- [x] Task 1: Settings 存储备份时间 (AC: #4)
  - [x] 1.1 SettingsView 导出成功后写入 last_backup_date 到 settings
  - [x] 1.2 SettingsView 添加 settingsRepository 依赖
- [x] Task 2: BackupReminderService (AC: #1, #2)
  - [x] 2.1 BackupReminderService + ReminderType enum
  - [x] 2.2 首次提醒: 50+ 交易 && 无 last_backup_date
  - [x] 2.3 定期提醒: last_backup_date > 30 天前
- [x] Task 3: ContentView 集成 (AC: #3, #5)
  - [x] 3.1 onAppear checkBackupReminder → FriendlyDialog (.info)
  - [x] 3.2 确认跳转设置页 / 取消关闭
- [x] Task 4: i18n + 编译验证 (AC: all)
  - [x] 4.1 补充 Localizable.strings — 5 新字符串 × 2

## Dev Notes

### 设计决策
- 使用 App 内 FriendlyDialog 而非系统 Local Notification，因为 App 是本地工具不需要后台推送
- 备份时间存储在 settings 表（key: last_backup_date, value: ISO8601 字符串）

### References

- [Source: epics.md#Story 4.3] — Acceptance Criteria

## Dev Agent Record

### Agent Model Used
Claude Sonnet 4 via Windsurf Cascade

### Completion Notes List
- BackupReminderService: ReminderType enum (.firstBackup/.periodicBackup/.none)
- SettingsView: +settingsRepository 依赖，导出成功后写入 last_backup_date
- ContentView: +backupReminderService + onAppear 检查 + FriendlyDialog 提醒
- 确认“去备份”跳转设置 Tab，“下次再说”关闭
- Build: 0 errors, 0 warnings

### Change Log
- 2026-02-14: Story 4.3 实现 — 备份提醒

### File List
- ios/FreeLedger/data/service/BackupReminderService.swift (new)
- ios/FreeLedger/ui/settings/SettingsView.swift (modified — +settingsRepository + last_backup_date)
- ios/FreeLedger/ContentView.swift (modified — +backupReminderService + checkBackupReminder)
- ios/FreeLedger/i18n/Localizable.strings (modified — 5 new strings)
- ios/FreeLedger/i18n/en.lproj/Localizable.strings (modified — 5 new strings)
