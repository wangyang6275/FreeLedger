# Story 4.1: 备份导出

Status: done

## Story

As a **user**,
I want **to export my data as a backup file**,
So that **I can protect my data from device loss**.

## Acceptance Criteria

1. **入口:** 设置页 → 备份与恢复 Section，点击"导出备份"
2. **文件选择:** 系统文件选择器打开，选择保存位置（FR21）
3. **备份内容:** JSON 文件包含所有数据（transactions, categories, tags, transaction_tags, settings）+ SHA-256 校验和
4. **安全:** 备份文件不包含密码哈希（NFR-S4）
5. **完成提示:** FriendlyDialog 显示"备份完成！共 X 条记录，文件已保存到你选择的位置"

## Tasks / Subtasks

- [x] Task 1: BackupData 模型 (AC: #3, #4)
  - [x] 1.1 BackupData 结构体（Codable）— version, checksum, transactions, categories, tags, transactionTags
  - [x] 1.2 SHA-256 校验和生成（CryptoKit）
- [x] Task 2: BackupService (AC: #3)
  - [x] 2.1 BackupService — dbQueue 单次读取所有表数据
  - [x] 2.2 JSONEncoder prettyPrinted + sortedKeys
- [x] Task 3: SettingsView 集成 (AC: #1, #2, #5)
  - [x] 3.1 备份与恢复 Section
  - [x] 3.2 导出备份按钮 → .fileExporter + BackupDocument (FileDocument)
  - [x] 3.3 FriendlyDialog 成功提示（withAnimation）
  - [x] 3.4 ContentView 传递 backupService
- [x] Task 4: i18n + 编译验证 (AC: all)
  - [x] 4.1 补充 Localizable.strings — 4 新字符串 × 2

## Dev Notes

### References

- [Source: epics.md#Story 4.1] — Acceptance Criteria

## Dev Agent Record

### Agent Model Used
Claude Sonnet 4 via Windsurf Cascade

### Debug Log References
- FriendlyDialogStyle 无 .normal → 改用 .info

### Completion Notes List
- BackupData: Codable 模型（version + checksum + 全部表数据）
- SHA-256 via CryptoKit
- BackupService: dbQueue 单次读取 + JSONEncoder
- BackupDocument: FileDocument 协议实现
- SettingsView: 备份 Section + .fileExporter + FriendlyDialog
- ContentView: +backupService 依赖
- Build: 0 errors, 0 warnings

### Change Log
- 2026-02-14: Story 4.1 实现 — 备份导出，JSON + SHA-256 + FileDocument + fileExporter

### File List
- ios/ColorFuLedger/data/model/BackupData.swift (new)
- ios/ColorFuLedger/data/service/BackupService.swift (new)
- ios/ColorFuLedger/ui/settings/SettingsView.swift (modified — +backup section + fileExporter + FriendlyDialog)
- ios/ColorFuLedger/ContentView.swift (modified — +backupService)
- ios/ColorFuLedger/i18n/Localizable.strings (modified — 4 new strings)
- ios/ColorFuLedger/i18n/en.lproj/Localizable.strings (modified — 4 new strings)
