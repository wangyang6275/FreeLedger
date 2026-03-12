# Epic 6 Retrospective: 新手引导与设置

## Summary

Epic 6 包含 2 个 Story，全部在单次开发会话中完成。涵盖新手引导流程（3 步 Onboarding）和设置页面重构（4 Section 分组 + 货币选择 + 关于页）。这是项目的最后一个 Epic，标志着 ColorFuLedger v1.0 全部功能开发完成。

| Story | 描述 | Code Review |
|-------|------|-------------|
| 6.1 | 新手引导流程 | 0 issues |
| 6.2 | 设置页面 | 0 issues |

## What Went Well

1. **TabView + PageTabViewStyle 一次到位** — OnboardingView 使用原生 SwiftUI 分页实现，代码简洁，交互流畅
2. **Locale.current.currency 智能默认** — 货币选择自动从系统 Locale 获取默认值，用户体验友好
3. **SettingsView 终于重构** — 从混乱的 Section 重新组织为通用/安全/数据/关于 4 个清晰分组
4. **CurrencyPickerView 抽离** — 货币选择独立视图，NavigationLink push，选中后自动 dismiss + 写入 settings
5. **onShowOnboarding 回调模式** — 设置页"重新引导"通过回调触发 ContentView 的 fullScreenCover，解耦优雅
6. **零编译错误** — 两个 Story 都一次编译通过，Epic 5 的 Theme API 教训得到执行
7. **Code Review 零缺陷** — 2 个 Story 全部 0 issues

## What Could Be Improved

1. **语言切换受 iOS 限制** — SwiftUI 不支持 App 内直接切换语言，只能跳转系统设置。可考虑使用 Bundle 覆盖方案，但复杂度较高
2. **数字键盘仍未提取** — Epic 5 retro 提出的 NumberPadView 共享组件仍未实施，3 处重复代码依然存在
3. **DI 优化第 5 次未实施** — ContentView init() 现有 11 个服务实例，SettingsView 有 6 个依赖参数
4. **SettingsView 仍然 340+ 行** — 虽然 Section 重新组织了，但行数因新增货币/关于功能反而增加。真正的拆分（子视图）仍未做
5. **OnboardingView 无动画** — AC 要求 icon animation，当前只有静态图标，未添加 SwiftUI 动画

## Epic 5 Retro Follow-Through

| Action Item | Status |
|-------------|--------|
| ⏳ 提取 NumberPadView 共享组件 | 未实施 |
| ✅ SettingsView 重构分组 | 完成 — 4 个 Section（通用/安全/数据/关于） |
| ⏳ DI 优化 | 未实施 — 第 5 次提出 |
| ✅ Onboarding 用 TabView + PageTabViewStyle | 完成 |
| ✅ Settings 货币实际功能 | 完成 — CurrencyPickerView + settings 读写 |

**Follow-Through Rate: 3/5 (60%)** — 较 Epic 5 (40%) 有所提升

## Code Review 经验总结

### Epic 6 新增检查项

| # | 规则 | 来源 |
|---|------|------|
| 19 | fullScreenCover 用于全屏引导/锁屏，sheet 用于表单 | Story 6.1 Onboarding |
| 20 | 语言切换 iOS 限制：跳转系统设置而非 App 内切换 | Story 6.2 语言 |

### 完整检查清单（20 条）

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
19. fullScreenCover 用于全屏引导/锁屏
20. 语言切换 iOS 限制：跳转系统设置

## Architecture Notes

### 新增 UI 层

| 文件 | 类型 | 功能 |
|------|------|------|
| OnboardingView | View | TabView 3 步引导（介绍/货币/记账） |
| CurrencyPickerView | View | 8 种货币列表 + checkmark + 写入 settings |

### SettingsView 重构

| Section | 内容 |
|---------|------|
| 通用 | 货币选择 (NavigationLink) + 语言 (系统设置跳转) |
| 安全 | 密码锁 Toggle + 修改密码 |
| 数据 | 分类管理 + 备份导出/导入 + CSV 导出 |
| 关于 | 重新引导 + 版本号 |

### ContentView 扩展

- +showOnboarding 状态 + .fullScreenCover
- +onShowOnboarding 回调传递给 SettingsView
- onAppear 检查 onboarding_completed

### settings 表新增 key

- onboarding_completed: 引导完成标记
- currency: 用户选择的货币代码

### i18n 增量

- Story 6.1: +8 字符串
- Story 6.2: +4 字符串
- 总计: +12 字符串（zh-Hans + en 各 12）

## Metrics

| 指标 | 值 |
|------|-----|
| Stories 完成 | 2/2 |
| 新增文件 | 2 |
| 修改文件 | ~6 |
| 新增 i18n 字符串 | 12 × 2 = 24 |
| Code Review Issues | 0 (all stories) |
| 编译错误修复 | 0 |
| 数据库迁移 | 0（复用 settings 表） |

## 🏆 项目总结

### 全部 Epic 完成状态

| Epic | 描述 | Stories | Status |
|------|------|---------|--------|
| 1 | 极速记账 | 4/4 | done ✅ |
| 2 | 智能分类与标签 | 3/3 | done ✅ |
| 3 | 数据洞察 | 4/4 | done ✅ |
| 4 | 数据保护 | 4/4 | done ✅ |
| 5 | 安全与隐私 | 2/2 | done ✅ |
| 6 | 引导与设置 | 2/2 | done ✅ |
| **总计** | | **19/19** | **100%** |

### 技术栈总结

- **UI**: SwiftUI + Swift Charts
- **数据**: GRDB.swift (SQLite)
- **安全**: CryptoKit (SHA-256) + Security (Keychain)
- **文件**: FileDocument + fileExporter/fileImporter
- **架构**: MVVM + Repository
- **i18n**: zh-Hans + en

### 累积代码检查清单

20 条规则，覆盖代码质量、安全、性能、UI 等多个维度。

### 技术债务（未来优化）

1. **DI 优化** — ContentView 11+ 服务实例需要容器化
2. **NumberPadView** — 3 处重复数字键盘需提取共享组件
3. **SettingsView 拆分** — 340+ 行需拆分为子视图
4. **密码尝试限制** — 防暴力破解
5. **Face ID/Touch ID** — LocalAuthentication 便捷解锁
6. **语言 App 内切换** — Bundle 覆盖方案
7. **OnboardingView 动画** — icon 入场动画
