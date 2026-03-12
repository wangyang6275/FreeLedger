# Story 6.1: 新手引导流程

Status: done

## Story

As a **new user**,
I want **to be guided through the app's core features on first launch**,
So that **I can start recording transactions confidently**.

## Acceptance Criteria

1. **首次启动:** 首次打开 App 时显示引导流程（3 步）
2. **Step 1:** "3 秒记一笔"功能介绍 + 图标动画（FR33）
3. **Step 2:** 货币选择（默认取系统 Locale）
4. **Step 3:** 引导首次记账，高亮"+"按钮
5. **跳过:** 底部"跳过引导"按钮可直接跳过（FR34）
6. **不重复:** 完成或跳过后，再次打开 App 不再显示

## Tasks / Subtasks

- [x] Task 1: OnboardingView (AC: #1, #2, #3, #4, #5)
  - [x] 1.1 OnboardingView — TabView + .page indexDisplayMode
  - [x] 1.2 Step 1: bolt 图标 + “3 秒记一笔”介绍
  - [x] 1.3 Step 2: 8 种常用货币列表 + 系统 Locale 默认选中
  - [x] 1.4 Step 3: plus.circle 图标 + 记账引导说明
  - [x] 1.5 “下一步”/“开始使用” + “跳过引导”按钮
  - [x] 1.6 completeOnboarding: 写入 currency + onboarding_completed
- [x] Task 2: 首次启动检测 (AC: #1, #6)
  - [x] 2.1 settings 表 key: onboarding_completed
  - [x] 2.2 ContentView onAppear 检查 + .fullScreenCover
- [x] Task 3: i18n + 编译验证 (AC: all)
  - [x] 3.1 补充 Localizable.strings — 8 新字符串 × 2

## Dev Notes

### 设计决策
- 使用 TabView + PageTabViewStyle 实现滑动引导页
- 货币选择直接写入 settings 表
- onboarding_completed 标记存储在 settings 表

### References

- [Source: epics.md#Story 6.1] — Acceptance Criteria

## Dev Agent Record

### Agent Model Used
Claude Sonnet 4 via Windsurf Cascade

### Completion Notes List
- OnboardingView: TabView + .page + 3 步引导（功能介绍/货币选择/记账引导）
- 货币选择: 8 种常用货币 + Locale.current.currency 默认
- ContentView: onAppear 检查 onboarding_completed + .fullScreenCover
- completeOnboarding: 写入 currency + onboarding_completed 到 settings
- Build: 0 errors, 0 warnings

### Change Log
- 2026-02-14: Story 6.1 实现 — 新手引导流程

### File List
- ios/ColorFuLedger/ui/onboarding/OnboardingView.swift (new)
- ios/ColorFuLedger/ContentView.swift (modified — +showOnboarding + fullScreenCover)
- ios/ColorFuLedger/i18n/Localizable.strings (modified — 8 new strings)
- ios/ColorFuLedger/i18n/en.lproj/Localizable.strings (modified — 8 new strings)
