# Epic 1 Retrospective: 极速记账（Quick Capture）

## Epic Summary

**目标：** 用户能快速记录收支、查看流水列表和月度汇总、查看/编辑/删除记录。

**Stories 完成情况：**

| Story | 标题 | Status | Code Review |
|-------|------|--------|-------------|
| 1.1 | 项目初始化与主题基础 | review | — |
| 1.2 | 记录一笔交易 | done ✅ | 4H+5M fixed |
| 1.3 | 首页流水列表 | done ✅ | 2H+1M fixed |
| 1.4 | 记录详情、编辑与删除 | done ✅ | 1H+3M fixed |

**结论：** Epic 1 所有功能 Story 已完成并通过 Code Review。1.1 项目基础设施处于 review 状态（无功能代码需审查）。

## What Went Well

1. **架构稳固** — MVVM + Repository + @Observable 模式从 1.2 建立后，1.3/1.4 复用顺畅，新功能能快速搭建
2. **Design Tokens 统一** — AppColors/AppSpacing/AppRadius/AppTypography 全局统一，UI 一致性好
3. **Code Review 有效** — 每个 Story 的 review 都发现了真实问题（不是形式主义），且修复后代码质量显著提升
4. **共享组件抽取** — CategoryIconView 从 1.3 review 中提取，1.4 直接复用
5. **i18n 从一开始就做** — 中英文 Localizable.strings 始终同步，无遗漏
6. **xcodebuildmcp 集成** — 配置完成后显著提升了构建-安装-验证效率

## What Could Be Improved

1. **swipeActions 需要 List** — 初始实现用 LazyVStack 导致 swipeActions 不生效，应在设计阶段就考虑 SwiftUI 组件限制
2. **错误处理需要纪律** — 多次出现 `catch {}` 空 catch 块，每次 Code Review 都要修。建议：**所有 catch 块必须有 errorMessage 或日志**
3. **DateFormatter 重复创建** — 1.2 和 1.4 都犯了同样的错误（每次调用创建新 formatter）。建议：**DateFormatter 一律 static let**
4. **UX 交互设计需更明确** — 1.2 的"点分类=保存"导致用户困惑，1.3 review 才修复。建议：Story AC 中明确描述交互流而非仅描述结果
5. **模拟器自动化测试不足** — xcodebuildmcp 无法模拟 tap/swipe，关键交互仍需人工验证

## Patterns Established (供后续 Epic 复用)

### 代码模式
- **ViewModel:** `@Observable final class XxxViewModel` + protocols for repositories
- **View → ViewModel:** `@State private var viewModel: XxxViewModel` + init 注入
- **错误处理:** `errorMessage: String?` + `.alert()` binding
- **导航:** `NavigationLink(value:)` + `.navigationDestination(for:)`
- **删除确认:** `FriendlyDialog` 组件（可直接复用）
- **日期格式:** `AppDateFormatter` + `static let` formatters
- **图标映射:** `CategoryIconView`（支持 size/iconSize 参数）

### 技术决策
- `Transaction` 需要 `Hashable` 才能用于 `NavigationLink(value:)`
- `ISO8601DateFormatter` 不是 `Sendable`，需 `nonisolated(unsafe)`
- `DateFormatter` 是 `Sendable`，不需要
- HomeView 使用 `List` 而非 `LazyVStack`（因 swipeActions 依赖）
- FriendlyDialog 使用 `withAnimation` + `transition` 实现平滑弹出

### Code Review 常见问题清单（检查项）
1. ❌ `catch {}` 空 catch 块
2. ❌ 每次调用创建新 DateFormatter/NumberFormatter
3. ❌ 裸字符串代替 enum（如 transaction.type）
4. ❌ 状态变更不在 MainActor
5. ❌ force-unwrap
6. ❌ 不尊重 reduceMotion
7. ❌ 重复代码未抽取共享组件

## Metrics

- **总 Code Review 发现：** 7 HIGH + 9 MEDIUM issues
- **编译状态：** 0 errors, 0 warnings
- **i18n 覆盖：** 100%（zh-Hans + en）
- **新增文件：** ~25 个 Swift 源文件
- **新增 i18n 字符串：** ~50+ keys
