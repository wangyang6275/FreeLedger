# Story 3.2: 趋势折线图

Status: done

## Story

As a **user**,
I want **to see a trend line chart of my income and expenses**,
So that **I can track my financial progress over time**.

## Acceptance Criteria

1. **趋势区域:** 报表页向下滚动，饼图下方显示趋势折线图
2. **双线图:** 支出线（珊瑚橙）+ 收入线（薄荷绿），近 6 个月数据（FR15）
3. **数据点:** 折线上显示圆形数据点
4. **月份标签:** X 轴显示月份标签
5. **主题一致:** 使用 Design Tokens

## Tasks / Subtasks

- [x] Task 1: Data Layer — 近 6 月汇总 (AC: #2)
  - [x] 1.1 MonthlyTrend 数据模型
  - [x] 1.2 TransactionRepository 添加 getLast6MonthsSummary() 方法
- [x] Task 2: ReportViewModel 扩展 (AC: #1, #2)
  - [x] 2.1 添加 trendData 属性
  - [x] 2.2 loadData 中加载趋势数据
- [x] Task 3: TrendLineChart 组件 (AC: #2, #3, #4)
  - [x] 3.1 创建 TrendLineChart — Swift Charts LineMark + PointMark
  - [x] 3.2 TrendChartEntry 转换模型（解决编译器类型检查超时）
  - [x] 3.3 双线（支出珊瑚橙/收入薄荷绿）+ 数据点圆圈 + catmullRom 插值
- [x] Task 4: ReportView 集成 (AC: #1)
  - [x] 4.1 饼图下方添加趋势图区域
- [x] Task 5: i18n + 编译验证 (AC: all)
  - [x] 5.1 补充 Localizable.strings — 1 新字符串 × 2

## Dev Notes

### 数据模型

```swift
struct MonthlyTrend: Identifiable {
    let id = UUID()
    let month: String      // "1月", "2月"
    let year: Int
    let monthNum: Int
    let expense: Int64
    let income: Int64
}
```

### Swift Charts 使用

```swift
Chart(trendData) { item in
    LineMark(x: .value("Month", item.month), y: .value("Amount", item.expense))
        .foregroundStyle(AppColors.expense)
    PointMark(x: .value("Month", item.month), y: .value("Amount", item.expense))
        .foregroundStyle(AppColors.expense)
    LineMark(x: .value("Month", item.month), y: .value("Amount", item.income))
        .foregroundStyle(AppColors.income)
    PointMark(x: .value("Month", item.month), y: .value("Amount", item.income))
        .foregroundStyle(AppColors.income)
}
```

### References

- [Source: epics.md#Story 3.2] — Acceptance Criteria
- [Source: ux-design-specification.md] — TrendLineChart 组件规范

## Dev Agent Record

### Agent Model Used
Claude Sonnet 4 via Windsurf Cascade

### Debug Log References
- Chart body 类型检查超时 → 拆分为 TrendChartEntry + chartTitle/chartView 子视图

### Completion Notes List
- MonthlyTrend 数据模型
- TransactionRepository: getLast6MonthsSummary 近 6 月汇总
- ReportViewModel: trendData + loadData 扩展
- TrendLineChart: Swift Charts LineMark + PointMark + catmullRom + 双线色彩
- TrendChartEntry 转换模型解决编译器类型检查超时
- ReportView: 饼图下方添加趋势图
- Build: 0 errors, 0 warnings
- Code Review: 0 issues

### Change Log
- 2026-02-14: Story 3.2 实现 — 趋势折线图，Swift Charts LineMark/PointMark，近 6 月收支趋势

### File List
- ios/ColorFuLedger/data/model/MonthlyTrend.swift (new)
- ios/ColorFuLedger/ui/report/TrendLineChart.swift (new)
- ios/ColorFuLedger/ui/report/ReportView.swift (modified — +trendChartSection)
- ios/ColorFuLedger/ui/report/ReportViewModel.swift (modified — +trendData)
- ios/ColorFuLedger/data/repository/TransactionRepository.swift (modified — +getLast6MonthsSummary)
- ios/ColorFuLedger/i18n/Localizable.strings (modified — 1 new string)
- ios/ColorFuLedger/i18n/en.lproj/Localizable.strings (modified — 1 new string)
