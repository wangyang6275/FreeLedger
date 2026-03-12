# Story 3.3: 标签柱状图

Status: done

## Story

As a **user**,
I want **to see a bar chart comparing spending across tags**,
So that **I can compare costs between projects or trips**.

## Acceptance Criteria

1. **标签柱状图:** 报表页趋势图下方显示水平柱状图，按标签分组的支出总额（FR16）
2. **标签颜色:** 柱状图使用标签颜色
3. **当月数据:** 显示当前选中月份的标签支出
4. **空状态:** 无标签数据时不显示该区域
5. **主题一致:** 使用 Design Tokens

## Tasks / Subtasks

- [x] Task 1: Data Layer — 标签支出聚合 (AC: #1, #3)
  - [x] 1.1 TagExpenseBreakdown 数据模型
  - [x] 1.2 TagDAO 添加 getTagExpenseBreakdown SQL JOIN+GROUP BY
  - [x] 1.3 TagRepository 扩展对应接口
- [x] Task 2: ReportViewModel 扩展 (AC: #1, #3)
  - [x] 2.1 添加 tagBreakdown + tagRepository 依赖
  - [x] 2.2 loadData 中加载标签支出数据
- [x] Task 3: TagBarChart 组件 (AC: #1, #2)
  - [x] 3.1 创建 TagBarChart — Swift Charts BarMark
  - [x] 3.2 水平柱状图 + 标签颜色 + 金额 annotation
- [x] Task 4: ReportView 集成 (AC: #1, #4)
  - [x] 4.1 趋势图下方添加标签柱状图
  - [x] 4.2 无数据时隐藏
  - [x] 4.3 ContentView 传递 tagRepository 给 ReportView
- [x] Task 5: i18n + 编译验证 (AC: all)
  - [x] 5.1 补充 Localizable.strings — 1 新字符串 × 2

## Dev Notes

### 数据模型

```swift
struct TagExpenseBreakdown: Identifiable {
    let id: String  // tagId
    let tagName: String
    let colorHex: String
    let total: Int64
}
```

### References

- [Source: epics.md#Story 3.3] — Acceptance Criteria

## Dev Agent Record

### Agent Model Used
Claude Sonnet 4 via Windsurf Cascade

### Debug Log References
- AxisValueLabel 不支持 .foregroundColor 链式调用 → 移除样式修饰符

### Completion Notes List
- TagExpenseBreakdown 数据模型
- TagDAO: getTagExpenseBreakdown SQL 3表 JOIN + GROUP BY
- TagRepository: 扩展接口
- ReportViewModel: +tagBreakdown + tagRepository 依赖
- TagBarChart: Swift Charts BarMark 水平柱状图 + 标签颜色 + 金额 annotation
- ReportView: 标签柱状图 + 无数据隐藏
- ContentView: tagRepository 传递给 ReportView
- Build: 0 errors, 0 warnings
- Code Review: 0 issues

### Change Log
- 2026-02-14: Story 3.3 实现 — 标签柱状图，Swift Charts BarMark，标签颜色柱子

### File List
- ios/ColorFuLedger/data/model/TagExpenseBreakdown.swift (new)
- ios/ColorFuLedger/ui/report/TagBarChart.swift (new)
- ios/ColorFuLedger/data/database/TagDAO.swift (modified — +getTagExpenseBreakdown)
- ios/ColorFuLedger/data/repository/TagRepository.swift (modified — +getTagExpenseBreakdown)
- ios/ColorFuLedger/ui/report/ReportViewModel.swift (modified — +tagBreakdown + tagRepository)
- ios/ColorFuLedger/ui/report/ReportView.swift (modified — +tagBarChartSection + tagRepository param)
- ios/ColorFuLedger/ContentView.swift (modified — pass tagRepository to ReportView)
- ios/ColorFuLedger/i18n/Localizable.strings (modified — 1 new string)
- ios/ColorFuLedger/i18n/en.lproj/Localizable.strings (modified — 1 new string)
