# Story 5.2: 密码锁定与解锁

Status: done

## Story

As a **user**,
I want **the app to lock when I leave and require my password to re-enter**,
So that **my data stays private even if someone picks up my phone**.

## Acceptance Criteria

1. **启动锁定:** 设置密码后，App 启动或从后台返回时显示 LockScreen（FR30）
2. **正确密码:** 输入正确密码后 LockScreen 消失，进入 App
3. **错误密码:** 输入错误密码时显示友好错误提示，可重试
4. **修改密码:** 设置页 → 密码锁 Section → "修改密码"按钮，先验证当前密码再设新密码（FR31）
5. **关闭密码锁:** Toggle 关闭时验证当前密码后移除（Story 5.1 已实现）

## Tasks / Subtasks

- [x] Task 1: LockScreenView (AC: #1, #2, #3)
  - [x] 1.1 LockScreenView — 全屏密码输入 + 锁图标
  - [x] 1.2 正确密码 → withAnimation onUnlocked
  - [x] 1.3 错误密码 → shake + 错误提示 + 清空输入
- [x] Task 2: App 生命周期锁定 (AC: #1)
  - [x] 2.1 ContentView @Environment(\.scenePhase)
  - [x] 2.2 background + isPasswordSet → isLocked = true
  - [x] 2.3 onAppear + isPasswordSet → isLocked = true
  - [x] 2.4 LockScreenView overlay + .transition(.opacity)
- [x] Task 3: 修改密码 (AC: #4)
  - [x] 3.1 SettingsView “修改密码”按钮（isPasswordEnabled 时显示）
  - [x] 3.2 VerifyPasswordView → 成功后 sheet SetPasswordView
- [x] Task 4: i18n + 编译验证 (AC: all)
  - [x] 4.1 补充 Localizable.strings — 3 新字符串 × 2

## Dev Notes

### References

- [Source: epics.md#Story 5.2] — Acceptance Criteria

## Dev Agent Record

### Agent Model Used
Claude Sonnet 4 via Windsurf Cascade

### Completion Notes List
- LockScreenView: 全屏锁屏 + 数字键盘 + shake + 解锁动画
- ContentView: scenePhase 监听 + onAppear 锁定 + LockScreenView overlay
- SettingsView: +“修改密码”按钮 + verify-then-set 流程
- Build: 0 errors, 0 warnings

### Change Log
- 2026-02-14: Story 5.2 实现 — 密码锁定与解锁

### File List
- ios/ColorFuLedger/ui/lock/LockScreenView.swift (new)
- ios/ColorFuLedger/ContentView.swift (modified — +scenePhase + isLocked + LockScreenView overlay)
- ios/ColorFuLedger/ui/settings/SettingsView.swift (modified — +修改密码按钮 + 2 sheets)
- ios/ColorFuLedger/i18n/Localizable.strings (modified — 3 new strings)
- ios/ColorFuLedger/i18n/en.lproj/Localizable.strings (modified — 3 new strings)
