# Epic 2 Retrospective: 智能分类与标签

## Summary

Epic 2 包含 3 个 Story，全部在单次开发会话中完成。涵盖自定义分类管理、标签创建与关联、标签筛选与统计三大功能模块。

| Story | 描述 | Code Review |
|-------|------|-------------|
| 2.1 | 自定义分类管理 | 2M fixed |
| 2.2 | 标签创建与关联 | 0 issues |
| 2.3 | 标签筛选与统计 | 0 issues |

## What Went Well

1. **开发效率高** — 3 个 Story 在一个会话中全部完成（创建+开发+Review），Epic 2 比 Epic 1 效率提升显著
2. **架构一致性好** — MVVM + Repository 模式已形成稳定套路，新功能开发直接套用模板
3. **Code Review 质量提升** — Story 2.2 和 2.3 均 0 issues，说明 Epic 1 总结的检查清单起了作用
4. **组件复用** — TransactionCard、FriendlyDialog、CategoryIconView、AmountKeypad 等组件跨 Story 复用良好
5. **FlowLayout 自定义布局** — 一次实现在 TagSelector 和 TransactionDetailView 中复用
6. **数据库迁移** — GRDB migration v2 顺利添加 tags + transaction_tags 表，无数据兼容问题

## What Could Be Improved

1. **依赖传递链过长** — ContentView → HomeView → TransactionDetailView 需要逐层传递 repository，随着功能增多参数列表变长。建议后续考虑 Environment 注入或 DI 容器
2. **Swift 编译器类型检查** — Story 2.1 遇到 body 表达式过复杂导致编译超时，需要手动拆分子视图。这是 SwiftUI 的已知限制，需要始终注意
3. **MCP Session Defaults** — 每次新会话都需要重新设置 scheme/simulatorId/bundleId，建议持久化配置
4. **模拟器交互测试有限** — 无法直接在模拟器中点击导航，只能通过截图和 UI 层级验证。实际功能验证依赖用户手动测试

## Code Review 经验总结

### Epic 2 新增检查项（追加到 Epic 1 清单）

| # | 规则 | 来源 |
|---|------|------|
| 8 | NavigationLink 不可点击项不应显示箭头（条件渲染） | Story 2.1 M1 |
| 9 | navigationDestination 用专用类型不用 String.self | Story 2.1 M2 |
| 10 | 复杂 body 拆分子视图避免编译器超时 | Story 2.1 编译修复 |

### 完整检查清单（10 条）

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

## Architecture Notes

### 新增数据层

- **Tag 模型** — id, name, colorHex, createdAt（Hashable for NavigationLink）
- **TransactionTag 模型** — 多对多关联表（transaction_id, tag_id）
- **TagDAO** — 完整 CRUD + getTagsForTransaction + getTransactionCountPerTag + getTransactionsForTag
- **TagRepository** — 协议 + 实现，7 个接口方法
- **GRDB Migration v2** — tags + transaction_tags 表 + 双索引 + ON DELETE CASCADE

### 新增 UI 层

| 文件 | 类型 | 功能 |
|------|------|------|
| CategoryManagementView | View | 分类管理列表（支出/收入 Tab） |
| CategoryManagementViewModel | ViewModel | 分类加载/删除/显示名称 |
| CategoryEditView | View | 新增/编辑共用（名称+图标+颜色+预览） |
| TagSelector | View | 底部面板标签选择器（FlowLayout+多选+内联创建） |
| FlowLayout | Layout | 自定义流式布局（SwiftUI Layout 协议） |
| TagsView | View | 标签列表（重写，含空状态） |
| TagsViewModel | ViewModel | 标签+交易计数 |
| TagDetailView | View | 标签详情（汇总卡片+交易列表） |
| TagDetailViewModel | ViewModel | 标签交易+汇总+日期分组 |

### i18n 增量

- Story 2.1: +12 字符串（分类管理相关）
- Story 2.2: +6 字符串（标签选择器相关）
- Story 2.3: +3 字符串（标签统计相关）
- 总计: +21 字符串（zh-Hans + en 各 21）

## Metrics

| 指标 | 值 |
|------|-----|
| Stories 完成 | 3/3 |
| 新增文件 | 12 |
| 修改文件 | ~20 |
| 新增 i18n 字符串 | 21 × 2 = 42 |
| Code Review Issues | 2M (Story 2.1) |
| 编译错误修复 | 2（类型检查超时 + Hashable） |
| 数据库迁移 | 1（v2: tags + transaction_tags） |

## Recommendations for Epic 3

1. **Swift Charts** — Epic 3 需要饼图和折线图，建议使用 iOS 16+ 原生 Swift Charts 框架
2. **数据聚合查询** — 报表需要按分类/月份聚合，建议在 DAO 层用 SQL GROUP BY 直接聚合，避免内存中处理大数据集
3. **ReportView 重写** — 当前是占位页面，需要完全重写为报表页
4. **DI 优化** — 如果继续增加 repository 依赖，考虑引入 Environment 注入模式减少参数传递
5. **搜索功能** — Story 3.4 搜索需要 GRDB FTS 或 LIKE 查询，提前规划索引策略
