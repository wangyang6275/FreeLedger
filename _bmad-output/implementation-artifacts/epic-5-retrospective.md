# Epic 5 Retrospective: 安全与隐私

## Summary

Epic 5 包含 2 个 Story，全部在单次开发会话中完成。涵盖密码设置与 Keychain 存储、App 锁屏与生命周期管理、修改密码流程，引入 Security 框架（Keychain）和 scenePhase 生命周期监听。

| Story | 描述 | Code Review |
|-------|------|-------------|
| 5.1 | 设置 App 密码 | 0 issues |
| 5.2 | 密码锁定与解锁 | 0 issues |

## What Went Well

1. **Keychain + CryptoKit 无缝集成** — PasswordService 使用原生 Security 框架操作 Keychain，SHA-256 + salt 哈希复用 Epic 4 已引入的 CryptoKit，零额外依赖
2. **数字键盘 UI 复用** — SetPasswordView、VerifyPasswordView、LockScreenView 共享相同的 numberPad 布局和 shake 动画模式
3. **scenePhase 生命周期锁定** — 使用 SwiftUI 原生 `@Environment(\.scenePhase)` 监听，简洁高效，无需 NotificationCenter
4. **两步密码设置流程** — enter → confirm 两步确认 + 不匹配自动重置，用户体验清晰
5. **修改密码流程** — verify-then-set 两步 sheet 链，代码简洁且安全
6. **Code Review 零缺陷** — 2 个 Story 全部 0 issues

## What Could Be Improved

1. **数字键盘代码重复** — SetPasswordView、VerifyPasswordView、LockScreenView 三个视图有大量重复的 numberPad 代码。应该提取为共享的 `NumberPadView` 组件
2. **API 验证不足** — Story 5.1 遇到 AppTypography 无 `.headline` 和 AppColors 无 `.border` 两个编译错误。规则 #12（新 API 使用前验证）需更严格执行
3. **SettingsView 继续膨胀** — 现在 280+ 行、5 个依赖（+passwordService）、6 个 sheet、4 个 overlay。Epic 4 retro 提出的拆分建议仍未实施
4. **DI 优化仍未实施** — 第 4 次提出。ContentView init() 已有 10+ 个服务实例
5. **无密码尝试限制** — 当前可无限次输入错误密码，未实现锁定/延迟机制
6. **无 Face ID/Touch ID** — Epic 4 retro 建议考虑 LocalAuthentication，未实施

## Epic 4 Retro Follow-Through

| Action Item | Status |
|-------------|--------|
| ✅ Keychain 存储密码哈希 | 完成 — Security 框架 SecItemAdd/CopyMatching/Delete |
| ✅ SHA-256 + Salt via CryptoKit | 完成 — 随机 16 字节 salt + SHA-256 |
| ⏳ DI 优化（Environment 注入） | 未实施 — 第 4 次提出 |
| ⏳ SettingsView 拆分子视图 | 未实施 — 继续膨胀到 280+ 行 |
| ⏳ Face ID/Touch ID | 未实施 — 可在 Epic 6 后补充 |

**Follow-Through Rate: 2/5 (40%)**

## Code Review 经验总结

### Epic 5 新增检查项

| # | 规则 | 来源 |
|---|------|------|
| 17 | Keychain 操作需 @discardableResult + delete-before-add 模式 | Story 5.1 Keychain CRUD |
| 18 | scenePhase 监听锁屏需在最外层 overlay 确保覆盖所有内容 | Story 5.2 LockScreen |

### 完整检查清单（18 条）

1. 不允许空 catch 块
2. DateFormatter/NumberFormatter 一律 static let
3. 使用 enum 不用裸字符串
4. 错误需用户可见提示（errorMessage + alert）
5. FriendlyDialog 用 withAnimation 过渡
6. @Observable 状态变更在 MainActor
7. 共享组件优先复用
8. NavigationLink 不可点击项不应显示箭头
9. navigationDestination 用专用类型
10. 复杂 body 拆分子视图
11. Swift Charts 用转换模型解决编译器超时
12. 新 API 使用前验证可用性
13. 非 Sendable 类型 static 属性用 nonisolated(unsafe)
14. FileDocument 协议用于 fileExporter/fileImporter
15. Security-scoped URL 必须 start/defer stop
16. 破坏性操作先 FriendlyDialog (.destructive) 确认
17. Keychain 操作需 delete-before-add 模式
18. scenePhase 锁屏 overlay 需在最外层

## Architecture Notes

### 新增数据层

- **PasswordService** — SHA-256 + salt 哈希 + Keychain CRUD（Security 框架）
  - isPasswordSet / setPassword / verifyPassword / removePassword

### 新增 UI 层

| 文件 | 类型 | 功能 |
|------|------|------|
| SetPasswordView | View | 4 位数字键盘 + enter/confirm 两步流程 |
| VerifyPasswordView | View | 密码验证 + 错误提示 + shake |
| LockScreenView | View | 全屏锁屏 + 锁图标 + 解锁回调 |

### SettingsView 扩展

- +安全 Section（密码锁 Toggle + 修改密码按钮）
- +passwordService 依赖
- +showSetPassword / showVerifyToDisable / showChangePasswordVerify / showChangePasswordSet sheets
- +showPasswordSetSuccess FriendlyDialog

### ContentView 扩展

- +passwordService + isLocked 状态
- +@Environment(\.scenePhase) 生命周期监听
- +LockScreenView overlay

### i18n 增量

- Story 5.1: +11 字符串
- Story 5.2: +3 字符串
- 总计: +14 字符串（zh-Hans + en 各 14）

## Metrics

| 指标 | 值 |
|------|-----|
| Stories 完成 | 2/2 |
| 新增文件 | 4 |
| 修改文件 | ~6 |
| 新增 i18n 字符串 | 14 × 2 = 28 |
| Code Review Issues | 0 (all stories) |
| 编译错误修复 | 2（AppTypography .headline, AppColors .border） |
| 数据库迁移 | 0（使用 Keychain） |
| 新增框架 | Security (Keychain) |

## Recommendations for Epic 6

1. **提取 NumberPadView** — 将数字键盘 + 圆点指示器提取为共享组件，减少 3 处重复代码
2. **SettingsView 拆分** — **第 3 次提出**。建议拆分为 GeneralSection、SecuritySection、BackupSection 子视图
3. **DI 优化** — **第 4 次提出**。建议引入 AppDependencies 容器或 Environment 注入
4. **Onboarding 设计** — Story 6.1 引导流程建议使用 TabView + PageTabViewStyle，简洁优雅
5. **Settings 完善** — Story 6.2 需要实现货币选择和语言切换的实际功能（当前只是静态文本）
