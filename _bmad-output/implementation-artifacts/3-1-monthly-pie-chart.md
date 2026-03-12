# Story 3.1: 月度饼图报表

Status: done

## Story

As a **user**,
I want **to see a pie chart of my spending by category**,
So that **I understand where my money goes**.

## Acceptance Criteria

1. **报表页重写:** 点击"报表" Tab → 显示月度汇总卡片（总收入/支出/结余）
2. **环形饼图:** 使用 Swift Charts 显示支出按分类的占比（FR14），使用分类颜色
3. **饼图中心:** 显示当月总支出金额
4. **扇区交互:** 点击饼图扇区 → 高亮并显示分类名称、金额、占比百分比
5. **月份切换:** 左右箭头切换月份（FR17），所有数据随之更新
6. **空状态:** 无交易数据时显示友好提示
7. **主题一致:** 珊瑚橙渐变主题，所有颜色/间距/圆角使用 Design Tokens

## Tasks / Subtasks

- [x] Task 1: Data Layer — 分类统计查询 (AC: #1, #2)
  - [x] 1.1 TransactionDAO 添加 getCategoryBreakdown(year:month:type:) SQL GROUP BY 聚合
  - [x] 1.2 CategoryBreakdown 数据模型
  - [x] 1.3 TransactionRepository 添加 getCategoryBreakdown 方法（带分类名称解析）
- [x] Task 2: ReportViewModel (AC: #1, #2, #4, #5)
  - [x] 2.1 创建 ReportViewModel — @Observable
  - [x] 2.2 月份状态管理（currentYear, currentMonth, previousMonth/nextMonth）
  - [x] 2.3 加载月度汇总 + 支出分类明细
  - [x] 2.4 selectedCategoryId 用于扇区交互（toggle 选中）
- [x] Task 3: ReportView 重写 (AC: #1, #5, #6)
  - [x] 3.1 重写 ReportView — 月份选择器 + 汇总卡片 + 饼图区域
  - [x] 3.2 月份切换：左右箭头 + 月份文字
  - [x] 3.3 汇总卡片：支出 / 收入 / 结余
  - [x] 3.4 空状态处理
- [x] Task 4: PieChartView 饼图组件 (AC: #2, #3, #4)
  - [x] 4.1 创建 ui/report/PieChartView.swift — Swift Charts SectorMark
  - [x] 4.2 环形饼图：innerRadius(.ratio(0.6)) + 分类颜色 + 中心总额
  - [x] 4.3 chartAngleSelection 扇区点击交互 → 高亮 + 显示详情
  - [x] 4.4 分类图例列表（CategoryIconView + 名称 + 金额 + 百分比）
- [x] Task 5: ContentView 集成 (AC: #1)
  - [x] 5.1 ReportView 接收 transactionRepository + settingsRepository
  - [x] 5.2 ContentView 传递依赖
- [x] Task 6: i18n + 编译验证 (AC: all)
  - [x] 6.1 补充 Localizable.strings (zh-Hans) — 4 新字符串
  - [x] 6.2 补充 en.lproj/Localizable.strings — 4 新字符串

## Dev Notes

### Architecture Compliance (MANDATORY)

**Tech Stack — 仅限 iOS：**
- Swift + SwiftUI + GRDB.swift + **Swift Charts**, @Observable, iOS 17.0+
- MVVM + Repository
- 零网络

### Swift Charts 使用

```swift
import Charts

// 环形饼图
Chart(categoryData, id: \.categoryId) { item in
    SectorMark(
        angle: .value("Amount", item.total),
        innerRadius: .ratio(0.6),  // 环形
        angularInset: 1.5
    )
    .foregroundStyle(Color(hex: item.colorHex))
    .opacity(selectedId == nil || selectedId == item.categoryId ? 1.0 : 0.5)
}
.chartAngleSelection(value: $rawSelection)  // iOS 17+ 交互
```

### 数据模型

```swift
struct CategoryBreakdown {
    let categoryId: String
    let categoryName: String
    let colorHex: String
    let total: Int64
    var percentage: Double  // 计算属性
}
```

### 月份选择器

```
┌─────────────────────────────┐
│    ◀   2026年2月   ▶        │  ← 左右切换月份
└─────────────────────────────┘
```

### 饼图区域

```
┌─────────────────────────────┐
│         ╭─────╮             │
│        ╱  总支出 ╲           │
│       │ ¥2,500  │           │
│        ╲       ╱            │
│         ╰─────╯             │
│                             │
│  🍔 餐饮   ¥800   32%      │  ← 图例列表
│  🛒 购物   ¥600   24%      │
│  🚌 交通   ¥400   16%      │
│  ...                        │
└─────────────────────────────┘
```

### 已有可复用

- `ui/components/SummaryCard.swift` — 汇总卡片样式参考
- `data/repository/TransactionRepository.swift` — getMonthlySummary 已有
- `util/AmountFormatter.swift` — 金额格式化
- `util/AppDateFormatter.swift` — 日期格式化
- `ui/components/CategoryIconView.swift` — 分类图标

### Code Review 检查清单

- 所有 catch 块必须有 errorMessage
- DateFormatter 一律 static let
- 复杂 body 拆分子视图
- Swift Charts 颜色使用分类 colorHex

### References

- [Source: architecture.md] — Swift Charts 选型
- [Source: epics.md#Story 3.1] — Acceptance Criteria
- [Source: ux-design-specification.md#旅程4] — 报表查看交互流程

## Dev Agent Record

### Agent Model Used
Claude Sonnet 4 via Windsurf Cascade

### Debug Log References
- getCategoryBreakdown 初始使用了不存在的 categoryRepository，修复为 categoryDAO.getAllAsDict()

### Completion Notes List
- TransactionDAO: getCategoryBreakdown SQL GROUP BY 聚合查询
- CategoryBreakdown 数据模型（categoryId, name, icon, color, total, percentage）
- TransactionRepository: getCategoryBreakdown 带分类信息解析（支持自定义分类 nameKey）
- ReportViewModel: 月份管理 + 汇总 + 支出分类明细 + 扇区选中
- ReportView: 完全重写，月份选择器 + 汇总卡片（支出/收入/结余）+ 饼图 + 空状态
- PieChartView: Swift Charts SectorMark 环形饼图 + chartAngleSelection 交互 + 中心总额/详情 + 图例列表
- ContentView: 传递 transactionRepository + settingsRepository 给 ReportView
- Build: 0 errors, 0 warnings
- Code Review: 0 issues

### Change Log
- 2026-02-14: Story 3.1 实现 — 月度饼图报表，Swift Charts SectorMark，月份切换，扇区交互

### File List
- ios/ColorFuLedger/data/model/CategoryBreakdown.swift (new)
- ios/ColorFuLedger/ui/report/ReportViewModel.swift (new)
- ios/ColorFuLedger/ui/report/PieChartView.swift (new)
- ios/ColorFuLedger/ui/report/ReportView.swift (modified — full rewrite)
- ios/ColorFuLedger/data/database/TransactionDAO.swift (modified — +getCategoryBreakdown)
- ios/ColorFuLedger/data/repository/TransactionRepository.swift (modified — +getCategoryBreakdown)
- ios/ColorFuLedger/ContentView.swift (modified — pass dependencies to ReportView)
- ios/ColorFuLedger/i18n/Localizable.strings (modified — 4 new strings)
- ios/ColorFuLedger/i18n/en.lproj/Localizable.strings (modified — 4 new strings)
