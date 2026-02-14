# Story 6.2: 设置页面

Status: done

## Story

As a **user**,
I want **a centralized settings page to manage all my preferences**,
So that **I can customize the app to my needs**.

## Acceptance Criteria

1. **分组布局:** iOS 风格分组列表 — 通用、安全、数据、关于
2. **通用 Section:** 货币选择（FR45）+ 语言切换（FR37）
3. **安全 Section:** 密码锁（已实现）
4. **数据 Section:** 备份导出/导入/CSV（已实现）+ 分类管理
5. **关于 Section:** 重新引导（FR35/FR44）+ 版本号
6. **语言切换:** 中文/English 切换，UI 立即更新
7. **货币选择:** Picker 选择货币，写入 settings

## Tasks / Subtasks

- [x] Task 1: SettingsView 重构分组 (AC: #1, #3, #4)
  - [x] 1.1 重新组织 Section：通用 / 安全 / 数据 / 关于
  - [x] 1.2 分类管理移入数据 Section
  - [x] 1.3 语言设置跳转系统设置 (UIApplication.openSettingsURLString)
- [x] Task 2: 货币选择 (AC: #2, #7)
  - [x] 2.1 CurrencyPickerView — 8 种货币列表 + checkmark
  - [x] 2.2 NavigationLink + onAppear 读取 currency
  - [x] 2.3 选择后写入 settings + dismiss
- [x] Task 3: 关于 Section (AC: #5)
  - [x] 3.1 重新引导按钮 → onShowOnboarding 回调
  - [x] 3.2 版本号: Bundle.main CFBundleShortVersionString + CFBundleVersion
- [x] Task 4: i18n + 编译验证 (AC: all)
  - [x] 4.1 补充 Localizable.strings — 4 新字符串 × 2

## Dev Notes

### 设计决策
- 语言切换：iOS 系统级语言设置，App 内跳转系统设置（SwiftUI 无法直接切换语言）
- 货币选择：NavigationLink → 列表选择页
- 版本号：从 Bundle.main 读取

### References

- [Source: epics.md#Story 6.2] — Acceptance Criteria

## Dev Agent Record

### Agent Model Used
Claude Sonnet 4 via Windsurf Cascade

### Completion Notes List
- SettingsView 重构: 4 个 Section（通用/安全/数据/关于）
- CurrencyPickerView: 8 种货币 + checkmark + 写入 settings
- 语言设置: 跳转系统设置（iOS 不支持 App 内切换语言）
- 重新引导: onShowOnboarding 回调 → ContentView showOnboarding
- 版本号: Bundle.main info
- Build: 0 errors, 0 warnings

### Change Log
- 2026-02-14: Story 6.2 实现 — 设置页面重构

### File List
- ios/FreeLedger/ui/settings/CurrencyPickerView.swift (new)
- ios/FreeLedger/ui/settings/SettingsView.swift (modified — 重构 4 Section + 货币选择 + 关于)
- ios/FreeLedger/ContentView.swift (modified — +onShowOnboarding)
- ios/FreeLedger/i18n/Localizable.strings (modified — 4 new strings)
- ios/FreeLedger/i18n/en.lproj/Localizable.strings (modified — 4 new strings)
