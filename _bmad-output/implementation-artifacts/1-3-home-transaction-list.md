# Story 1.3: 首页流水列表

Status: done

## Story

As a **user**,
I want **to see my transaction history and monthly summary on the home page**,
So that **I know my financial status at a glance**.

## Acceptance Criteria

1. **月度汇总卡片:** 首页顶部 SummaryCard 显示当月总支出、总收入、结余；珊瑚橙渐变背景 + 白色文字；显示当前月份
2. **流水列表:** 交易记录以 TransactionCard 形式按日期分组展示；每张卡片显示分类图标、分类名、备注、金额、时间
3. **金额颜色:** 支出金额显示珊瑚橙色 (AppColors.expense)，收入金额显示薄荷绿色 (AppColors.income)
4. **金额格式:** 金额按 Locale 格式化，带货币符号 (FR38)
5. **空状态:** 无交易记录时显示友好的空状态插图和引导文字

## Tasks / Subtasks

- [x] Task 1: 数据查询扩展 (AC: #1, #2)
  - [x] 1.1 扩展 TransactionDAO — 添加 getByMonth(year:month:) 方法
  - [x] 1.2 扩展 TransactionRepository — 添加 getTransactionsForMonth, getMonthlySummary 方法
  - [x] 1.3 创建 domain/model/TransactionSummary.swift — 包含 totalExpense, totalIncome, balance
  - [x] 1.4 扩展 CategoryDAO/Repository — 添加 getById + getAllAsDict 方法
- [x] Task 2: SummaryCard 组件 (AC: #1)
  - [x] 2.1 创建 ui/components/SummaryCard.swift — 珊瑚橙渐变背景, 圆角 24pt
  - [x] 2.2 显示内容：月份标题、总支出 (Display)、总收入、结余
  - [x] 2.3 白色文字，使用 AppTypography 字体层级
  - [x] 2.4 无障碍：accessibilityElement(children: .combine) + a11y_summary
- [x] Task 3: TransactionCard 组件 (AC: #2, #3, #4)
  - [x] 3.1 创建 ui/components/TransactionCard.swift — 白色圆角 12pt, minHeight 64pt
  - [x] 3.2 布局：左侧分类图标 (40pt) → 中间分类名+备注 → 右侧金额+时间
  - [x] 3.3 金额颜色：支出 AppColors.expense，收入 AppColors.income
  - [x] 3.4 金额格式：前缀 +/- + AmountFormatter.format
  - [x] 3.5 无障碍：accessibilityElement(children: .combine) + 分类名、金额、备注、时间
- [x] Task 4: HomeView 改造 (AC: #1, #2, #5)
  - [x] 4.1 创建 ui/home/HomeViewModel.swift — @Observable，管理月度汇总 + 交易列表 + categoryDict
  - [x] 4.2 改造 ui/home/HomeView.swift — SummaryCard + LazyVStack 按日期分组的 TransactionCard
  - [x] 4.3 空状态视图：tray 图标 + 引导文字
  - [x] 4.4 列表按 created_at DESC 排序，按日期分组（今天/昨天/X月X日）
  - [x] 4.5 记账完成后 onChange(showRecord) 自动刷新列表
- [x] Task 5: 日期格式化工具 (AC: #2)
  - [x] 5.1 创建 util/DateFormatter+App.swift — 日期分组标题 + 时间格式化 + 月份标题 + groupTransactionsByDate
- [x] Task 6: i18n 补充 (AC: all)
  - [x] 6.1 补充 Localizable.strings (zh-Hans) — 汇总卡片、日期分组、error_load_failed、a11y_summary
  - [x] 6.2 补充 en.lproj/Localizable.strings — 英文翻译

## Dev Notes

### Architecture Compliance (MANDATORY)

**Tech Stack — 仅限 iOS：**
- Swift + SwiftUI + GRDB.swift, @Observable, iOS 17.0+
- MVVM + Repository
- 零网络

**10 条强制规则全部适用（同 Story 1.2）**

### SummaryCard 规范

```
┌─────────────────────────────────────┐
│  2月                    珊瑚橙渐变   │
│                                     │
│  本月支出                            │
│  ¥ 2,500.00           (Display 32pt)│
│                                     │
│  收入 ¥8,000   结余 ¥5,500          │
└─────────────────────────────────────┘
```

- 背景：AppColors.primaryGradient（#FF6B6B → #FF8E8E）
- 圆角：AppRadius.xl (24pt)
- 内边距：AppSpacing.xl (20pt)
- 文字：全部白色
- 月份标题：AppTypography.body
- 支出金额：AppTypography.display (32pt bold)
- 收入/结余：AppTypography.body

### TransactionCard 规范

```
┌──────────────────────────────────────┐
│  🍔  餐饮          ¥25.00  (珊瑚橙)  │
│      午餐          12:30             │
└──────────────────────────────────────┘
```

- 白色背景，圆角 AppRadius.md (12pt)
- 高度 ≥ 64pt
- 左侧：分类图标（圆形彩色背景 40pt + 图标 20pt）
- 中间：分类名 (bodyLarge) + 备注 (caption, textTertiary)
- 右侧：金额 (bodyLarge, bold) + 时间 (caption, textTertiary)
- 支出金额色：AppColors.expense（珊瑚橙）
- 收入金额色：AppColors.income（薄荷绿）

### 日期分组逻辑

```
今天
  - TransactionCard
  - TransactionCard
昨天
  - TransactionCard
2月12日
  - TransactionCard
```

- 分组标题：AppTypography.caption, AppColors.textTertiary
- 日期判断：Calendar.current.isDateInToday / isDateInYesterday
- 其他日期：M月d日 格式

### 月度汇总计算

```swift
// TransactionSummary
struct TransactionSummary {
    let totalExpense: Int64  // 分
    let totalIncome: Int64   // 分
    var balance: Int64 { totalIncome - totalExpense }
}

// 查询当月记录
let startOfMonth = Calendar.current.date(from: Calendar.current.dateComponents([.year, .month], from: Date()))!
let endOfMonth = Calendar.current.date(byAdding: .month, value: 1, to: startOfMonth)!
// WHERE created_at >= startISO AND created_at < endISO
```

### Previous Story Intelligence (Story 1.2)

**已有可复用的文件：**
- `data/model/Transaction.swift` — 含 TransactionType enum
- `data/model/Category.swift` — 分类模型
- `data/database/TransactionDAO.swift` — 需扩展 getByMonth
- `data/database/CategoryDAO.swift` — 需扩展 getById
- `data/repository/TransactionRepository.swift` — 需扩展月度查询
- `util/AmountFormatter.swift` — 金额格式化
- `ui/components/CategoryGrid.swift` — categoryIcon 映射可复用
- `theme/AppColors.swift` — 含 primaryGradient, expense, income
- `ContentView.swift` — 需传递刷新信号

**Story 1.2 Code Review 修复的问题（避免重犯）：**
- 使用 TransactionType enum 而非裸字符串
- 静态 DateFormatter 避免重复创建
- 错误不能静默吞掉，需要用户可见的提示
- 尊重 reduceMotion 无障碍设置
- 避免 force-unwrap

### References

- [Source: architecture.md#Data Architecture] — transactions 表 schema + 索引
- [Source: architecture.md#Mobile Architecture] — MVVM + @Observable, NavigationStack
- [Source: architecture.md#Implementation Patterns] — 命名规范、格式规范
- [Source: architecture.md#Enforcement Guidelines] — 10 条强制规则
- [Source: ux-design-specification.md#SummaryCard] — 汇总卡片规范
- [Source: ux-design-specification.md#TransactionCard] — 流水卡片规范
- [Source: ux-design-specification.md#Accessibility] — VoiceOver 标签规范
- [Source: epics.md#Story 1.3] — Acceptance Criteria (BDD)

## Dev Agent Record

### Agent Model Used

Claude (Cascade)

### Debug Log References

- ISO8601DateFormatter is NOT Sendable in Swift 6 (unlike DateFormatter) → requires `nonisolated(unsafe)`
- DateFormatter IS Sendable → no annotation needed

### Completion Notes List

- **Data Layer:** TransactionDAO.getByMonth, TransactionRepository.getMonthlySummary, CategoryDAO.getById/getAllAsDict, TransactionSummary domain model
- **UI Components:** SummaryCard (coral gradient, white text, a11y) + TransactionCard (icon + name + note + amount + time, expense/income colors, a11y)
- **HomeView:** Complete rewrite with HomeViewModel (@Observable), SummaryCard + LazyVStack grouped by date, empty state with tray icon
- **DateFormatter:** AppDateFormatter with ISO parsing, time format, date group titles (today/yesterday/M月d日), groupTransactionsByDate
- **Navigation:** ContentView passes HomeViewModel, auto-refreshes on record sheet dismiss via onChange
- **i18n:** 10+ new strings (zh-Hans + en) — summary labels, date groups, error_load_failed, a11y_summary
- **Build:** 0 errors, 0 warnings

### Change Log

- 2026-02-14: Story 1.3 implementation — data query extensions, SummaryCard, TransactionCard, HomeView rewrite, date formatter, i18n
- 2026-02-14: Code review — fixed 2 HIGH + 1 MEDIUM issues:
  - H1: RecordView 添加明确的“保存”按钮，CategoryGrid 改为选择模式（用户报告无法保存）
  - H2: CategoryGrid onSelect 回调加 @MainActor 确保主线程执行
  - M1: 抽取 CategoryIconView 共享组件，消除 CategoryGrid/TransactionCard 图标映射重复代码

### File List

- ios/ColorFuLedger/domain/model/TransactionSummary.swift (new)
- ios/ColorFuLedger/util/DateFormatter+App.swift (new)
- ios/ColorFuLedger/ui/components/SummaryCard.swift (new)
- ios/ColorFuLedger/ui/components/TransactionCard.swift (new)
- ios/ColorFuLedger/ui/home/HomeViewModel.swift (new)
- ios/ColorFuLedger/ui/home/HomeView.swift (modified — complete rewrite)
- ios/ColorFuLedger/data/database/TransactionDAO.swift (modified — added getByMonth)
- ios/ColorFuLedger/data/database/CategoryDAO.swift (modified — added getById, getAllAsDict)
- ios/ColorFuLedger/data/repository/TransactionRepository.swift (modified — added getTransactionsForMonth, getMonthlySummary)
- ios/ColorFuLedger/data/repository/CategoryRepository.swift (modified — added getAllAsDict)
- ios/ColorFuLedger/ContentView.swift (modified — HomeViewModel injection, auto-refresh)
- ios/ColorFuLedger/i18n/Localizable.strings (modified — added 10+ strings)
- ios/ColorFuLedger/i18n/en.lproj/Localizable.strings (modified — added 10+ strings)
- ios/ColorFuLedger/ui/components/CategoryIconView.swift (new — code review: shared icon component)
- ios/ColorFuLedger/ui/record/RecordView.swift (modified — code review: added save button + selection mode)
- ios/ColorFuLedger/ui/components/CategoryGrid.swift (modified — code review: external selectedId, removed internal state)
- ios/ColorFuLedger/data/model/Category.swift (modified — code review: added Equatable)
