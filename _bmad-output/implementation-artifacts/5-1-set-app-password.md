# Story 5.1: 设置 App 密码

Status: done

## Story

As a **user**,
I want **to set up a password lock for the app**,
So that **others cannot access my financial data**.

## Acceptance Criteria

1. **入口:** 设置页 → 密码锁 Section，Toggle 开关
2. **设置密码:** 开启 Toggle → 弹出数字密码输入界面，输入两次确认（FR29）
3. **存储:** 密码哈希（SHA-256 + salt）存储在 Keychain
4. **成功提示:** 设置成功后提示"密码锁已开启"
5. **密码不匹配:** 两次输入不一致时显示友好提示"两次输入不一致，请重试"

## Tasks / Subtasks

- [x] Task 1: PasswordService — Keychain 存储 (AC: #3)
  - [x] 1.1 SHA-256 + 随机 salt 哈希 (CryptoKit)
  - [x] 1.2 Keychain CRUD (Security 框架 SecItemAdd/CopyMatching/Delete)
  - [x] 1.3 isPasswordSet / verifyPassword / setPassword / removePassword
- [x] Task 2: SetPasswordView (AC: #2, #5)
  - [x] 2.1 4 位数字键盘 + 圆点指示器
  - [x] 2.2 两步流程: enter → confirm
  - [x] 2.3 不匹配 shake 动画 + 重置到 enter 步骤
- [x] Task 2b: VerifyPasswordView
  - [x] 2b.1 输入密码验证 + 错误提示 + shake
- [x] Task 3: SettingsView 集成 (AC: #1, #4)
  - [x] 3.1 安全 Section + 密码锁 Toggle
  - [x] 3.2 开启 → sheet SetPasswordView + 成功 FriendlyDialog
  - [x] 3.3 关闭 → sheet VerifyPasswordView → removePassword
  - [x] 3.4 onAppear 同步 isPasswordEnabled 状态
  - [x] 3.5 ContentView +passwordService 依赖
- [x] Task 4: i18n + 编译验证 (AC: all)
  - [x] 4.1 补充 Localizable.strings — 11 新字符串 × 2

## Dev Notes

### References

- [Source: epics.md#Story 5.1] — Acceptance Criteria

## Dev Agent Record

### Agent Model Used
Claude Sonnet 4 via Windsurf Cascade

### Debug Log References
- AppTypography 无 .headline → 改用 .title2
- AppColors 无 .border → 改用 .divider

### Completion Notes List
- PasswordService: SHA-256 + salt via CryptoKit + Keychain (Security 框架)
- SetPasswordView: 4 位数字键盘 + enter/confirm 两步流程 + shake 动画
- VerifyPasswordView: 密码验证 + 错误提示 + shake
- SettingsView: 安全 Section + Toggle + 2 sheets + FriendlyDialog
- ContentView: +passwordService
- Build: 0 errors, 0 warnings

### Change Log
- 2026-02-14: Story 5.1 实现 — 设置 App 密码

### File List
- ios/ColorFuLedger/data/service/PasswordService.swift (new)
- ios/ColorFuLedger/ui/settings/SetPasswordView.swift (new)
- ios/ColorFuLedger/ui/settings/VerifyPasswordView.swift (new)
- ios/ColorFuLedger/ui/settings/SettingsView.swift (modified — +passwordService + 安全 Section)
- ios/ColorFuLedger/ContentView.swift (modified — +passwordService)
- ios/ColorFuLedger/i18n/Localizable.strings (modified — 11 new strings)
- ios/ColorFuLedger/i18n/en.lproj/Localizable.strings (modified — 11 new strings)
