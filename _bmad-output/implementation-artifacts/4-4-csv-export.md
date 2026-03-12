# Story 4.4: CSV 导出

Status: done

## Story

As a **user**,
I want **to export my data as a CSV file**,
So that **I can share it with others or analyze in a spreadsheet**.

## Acceptance Criteria

1. **入口:** 设置页备份与恢复 Section，点击"导出 CSV"
2. **字段选择:** 可选择导出字段（日期、金额、类型、分类、备注、标签）（FR28）
3. **CSV 生成:** 按选中字段生成 CSV 文件（FR27）
4. **分享:** 生成后打开系统分享面板（email、消息、文件保存等）

## Tasks / Subtasks

- [x] Task 1: CSVExportService (AC: #2, #3)
  - [x] 1.1 CSVExportService — dbQueue 单次读取所有表 + 生成 CSV Data
  - [x] 1.2 CSVExportField 模型 + 字段选择（date/amount/type/category/note/tags）
  - [x] 1.3 CSV 转义处理（逗号/引号/换行）
  - [x] 1.4 分类名称解析（自定义 vs 预设）+ 标签关联查询
- [x] Task 2: CSVExportView (AC: #1, #2, #4)
  - [x] 2.1 Toggle 字段选择列表
  - [x] 2.2 导出按钮 → .fileExporter + CSVDocument (FileDocument)
  - [x] 2.3 无字段选中时禁用导出
- [x] Task 3: SettingsView 集成 (AC: #1)
  - [x] 3.1 备份 Section 添加“导出 CSV”按钮 + .sheet
  - [x] 3.2 ContentView 传递 csvExportService
- [x] Task 4: i18n + 编译验证 (AC: all)
  - [x] 4.1 补充 Localizable.strings — 10 新字符串 × 2

## Dev Notes

### References

- [Source: epics.md#Story 4.4] — Acceptance Criteria

## Dev Agent Record

### Agent Model Used
Claude Sonnet 4 via Windsurf Cascade

### Completion Notes List
- CSVExportField: 字段选择模型（id + labelKey + isSelected）
- CSVExportService: dbQueue 单次读取 + CSV 生成 + 转义处理 + 分类解析 + 标签关联
- CSVExportView: Toggle 字段选择 + .fileExporter + CSVDocument
- SettingsView: +csvExportService + “导出 CSV”按钮 + .sheet
- ContentView: +csvExportService 依赖
- Build: 0 errors, 0 warnings

### Change Log
- 2026-02-14: Story 4.4 实现 — CSV 导出

### File List
- ios/ColorFuLedger/data/service/CSVExportService.swift (new)
- ios/ColorFuLedger/ui/settings/CSVExportView.swift (new)
- ios/ColorFuLedger/ui/settings/SettingsView.swift (modified — +csvExportService + CSV 按钮 + sheet)
- ios/ColorFuLedger/ContentView.swift (modified — +csvExportService)
- ios/ColorFuLedger/i18n/Localizable.strings (modified — 10 new strings)
- ios/ColorFuLedger/i18n/en.lproj/Localizable.strings (modified — 10 new strings)
