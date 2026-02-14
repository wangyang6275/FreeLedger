# Epic 3 Retrospective: 数据洞察

## Summary

Epic 3 包含 4 个 Story，全部在单次开发会话中完成。涵盖月度饼图、趋势折线图、标签柱状图、搜索与筛选四大功能模块，全面引入 Swift Charts 框架。

| Story | 描述 | Code Review |
|-------|------|-------------|
| 3.1 | 月度饼图 | 0 issues |
| 3.2 | 趋势折线图 | 0 issues |
| 3.3 | 标签柱状图 | 0 issues |
| 3.4 | 搜索与筛选 | 0 issues |

## What Went Well

1. **Swift Charts 全面掌握** — 4 种图表类型（SectorMark、LineMark、PointMark、BarMark）一次性全部实现，覆盖 FR14-FR16
2. **SQL 聚合模式成熟** — GROUP BY + JOIN 在 DAO 层直接聚合，Story 3.1 确立模式后 3.3/3.4 快速复用
3. **Code Review 零缺陷** — 4 个 Story 全部 0 issues，Epic 2 的 10 条检查清单严格遵守
4. **增量式架构** — ReportViewModel 从 Story 3.1 开始，3.2/3.3 逐步扩展属性和依赖，无需重写
5. **搜索功能动态 SQL** — Story 3.4 实现可组合筛选（keyword + dateRange + categoryId），架构灵活
6. **组件复用** — TransactionCard、CategoryIconView、AmountFormatter 等跨 Story 复用良好

## What Could Be Improved

1. **Swift Charts 编译器类型检查超时** — 2/4 Story 遇到（3.2 TrendLineChart、3.3 TagBarChart），Swift Charts 的链式 API + ForEach 特别容易触发
2. **API 探索成本** — 3/4 Story 有 API 不匹配修复：
   - Story 3.1: categoryDAO vs categoryRepository 混淆
   - Story 3.3: AxisValueLabel 不支持 .foregroundColor
   - Story 3.4: CategoryRepositoryProtocol 无 getAll()、ISO8601DateFormatter 并发安全
3. **依赖注入链继续增长** — ReportView 需要 3 个 repository（transaction、settings、tag），Epic 2 提出的 DI 优化仍未实施
4. **搜索未实现 debounce** — Story 3.4 当前是手动提交搜索，未实现实时搜索 debounce

## Epic 2 Retro Follow-Through

| Action Item | Status |
|-------------|--------|
| ✅ 使用 Swift Charts 原生框架 | 完成 — SectorMark, LineMark, PointMark, BarMark |
| ✅ DAO 层 SQL GROUP BY 聚合 | 完成 — getCategoryBreakdown, getTagExpenseBreakdown |
| ✅ ReportView 重写 | 完成 — 全新报表页含 3 种图表 |
| ⏳ DI 优化（Environment 注入） | 未实施 — 依赖链继续增长 |
| ✅ 搜索用 LIKE 查询 | 完成 — 动态 SQL WHERE + LEFT JOIN |
| ✅ 复杂 body 拆分子视图（规则 #10） | 严格遵守 |

**Follow-Through Rate: 5/6 (83%)**

## Code Review 经验总结

### Epic 3 新增检查项

| # | 规则 | 来源 |
|---|------|------|
| 11 | Swift Charts 复杂表达式使用转换模型 + 拆分子视图 | Story 3.2/3.3 编译修复 |
| 12 | 使用新 API 前验证可用性（尤其 Charts AxisMarks） | Story 3.3 AxisValueLabel |
| 13 | ISO8601DateFormatter 等非 Sendable 类型用 nonisolated(unsafe) | Story 3.4 并发安全 |

### 完整检查清单（13 条）

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

## Architecture Notes

### 新增数据层

- **CategoryBreakdown 模型** — 分类支出聚合（categoryId, name, icon, color, total, percentage）
- **MonthlyTrend 模型** — 月度趋势（year, month, monthLabel, expense, income）
- **TagExpenseBreakdown 模型** — 标签支出聚合（tagId, name, colorHex, total）
- **TransactionDAO** — +getCategoryBreakdown (GROUP BY), +search (动态 SQL WHERE)
- **TagDAO** — +getTagExpenseBreakdown (3表 JOIN + GROUP BY)
- **TransactionRepository** — +getCategoryBreakdown, +getLast6MonthsSummary, +search
- **TagRepository** — +getTagExpenseBreakdown

### 新增 UI 层

| 文件 | 类型 | 功能 |
|------|------|------|
| ReportView | View | 重写 — 月份选择器 + 汇总 + 饼图 + 趋势图 + 标签柱状图 |
| ReportViewModel | ViewModel | 报表数据管理（月份导航 + 多维数据加载） |
| PieChartView | View | Swift Charts SectorMark 环形饼图 + 交互 + 图例 |
| TrendLineChart | View | Swift Charts LineMark + PointMark 双线趋势图 |
| TagBarChart | View | Swift Charts BarMark 水平柱状图 |
| SearchView | View | 搜索栏 + 日期/分类筛选芯片 + 结果列表 |
| SearchViewModel | ViewModel | 搜索状态管理 + 组合筛选 |

### i18n 增量

- Story 3.1: +5 字符串
- Story 3.2: +1 字符串
- Story 3.3: +1 字符串
- Story 3.4: +14 字符串
- 总计: +21 字符串（zh-Hans + en 各 21）

## Metrics

| 指标 | 值 |
|------|-----|
| Stories 完成 | 4/4 |
| 新增文件 | 8 |
| 修改文件 | ~16 |
| 新增 i18n 字符串 | 21 × 2 = 42 |
| Code Review Issues | 0 (all stories) |
| 编译错误修复 | 5（类型检查超时 ×2, API 不匹配 ×3） |
| 数据库迁移 | 0（复用现有 schema） |

## Recommendations for Epic 4

1. **Codable 序列化** — Backup 需要序列化所有模型（Transaction, Category, Tag, TransactionTag, Settings），确保 Codable 完整覆盖
2. **DocumentPicker** — iOS 文件选择器需要 UIViewControllerRepresentable 包装
3. **SHA-256 校验** — 使用 CryptoKit 生成备份文件校验和
4. **大数据处理** — 备份导入需要事务批量写入，避免逐条插入性能问题
5. **DI 优化** — 随着 repository 数量增加（目前 4 个），强烈建议在 Epic 4 引入 Environment 注入模式
6. **进度指示器** — Story 4.1/4.2 需要导出/导入进度 UI，考虑 ProgressView
