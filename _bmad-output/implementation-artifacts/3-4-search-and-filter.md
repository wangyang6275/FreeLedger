# Story 3.4: 搜索与筛选

Status: done

## Story

As a **user**,
I want **to search and filter my transaction history**,
So that **I can quickly find any past record**.

## Acceptance Criteria

1. **搜索入口:** 明细页点击搜索图标，顶部出现搜索栏并自动聚焦键盘
2. **关键词搜索:** 输入关键词后匹配 note 和分类名称，结果 <0.5s 显示（FR18, NFR-P4）
3. **日期范围筛选:** 可选日期范围筛选，仅显示范围内交易（FR19）
4. **分类筛选:** 可选分类筛选，仅显示该分类的交易（FR20）
5. **组合筛选:** 搜索关键词 + 日期 + 分类可组合使用
6. **空结果:** 无匹配时显示空状态提示

## Tasks / Subtasks

- [x] Task 1: Data Layer — 搜索查询 (AC: #2, #3, #4, #5)
  - [x] 1.1 TransactionDAO 添加 search() 方法，动态 SQL WHERE 拼接
  - [x] 1.2 TransactionRepository 扩展对应接口
- [x] Task 2: SearchViewModel (AC: #1, #2, #5, #6)
  - [x] 2.1 创建 SearchViewModel — searchText / dateRange / categoryId / results
  - [x] 2.2 搜索逻辑 — performSearch + clearFilters
- [x] Task 3: SearchView (AC: #1, #3, #4, #6)
  - [x] 3.1 搜索栏 + 自动聚焦键盘
  - [x] 3.2 日期筛选芯片（今天/本周/本月）
  - [x] 3.3 分类筛选 Menu
  - [x] 3.4 空结果 + 初始状态
  - [x] 3.5 NavigationLink 跳转 TransactionDetailView
- [x] Task 4: HomeView 集成 (AC: #1)
  - [x] 4.1 toolbar 搜索按钮 + sheet 呈现 SearchView
- [x] Task 5: i18n + 编译验证 (AC: all)
  - [x] 5.1 补充 Localizable.strings — 14 新字符串 × 2

## Dev Notes

### SQL 搜索策略

```sql
SELECT t.* FROM transactions t
LEFT JOIN categories c ON t.category_id = c.id
WHERE (t.note LIKE '%keyword%' OR c.name_key LIKE '%keyword%')
  AND t.created_at >= ? AND t.created_at < ?
  AND t.category_id = ?
ORDER BY t.created_at DESC
```

### References

- [Source: epics.md#Story 3.4] — Acceptance Criteria

## Dev Agent Record

### Agent Model Used
Claude Sonnet 4 via Windsurf Cascade

### Debug Log References
- ISO8601DateFormatter 并发安全 → nonisolated(unsafe) static let
- CategoryRepositoryProtocol 无 getAll() → 使用 getExpenseCategories + getIncomeCategories

### Completion Notes List
- TransactionDAO.search: 动态 SQL WHERE + LEFT JOIN categories
- TransactionRepository: +search 接口
- SearchViewModel: searchText/dateRange/categoryId/results + performSearch/clearFilters
- SearchView: 搜索栏 + 日期/分类筛选芯片 + 结果列表 + 空状态
- HomeView: toolbar 搜索按钮 + sheet
- Build: 0 errors, 0 warnings

### Change Log
- 2026-02-14: Story 3.4 实现 — 搜索与筛选，动态 SQL + 组合筛选 UI

### File List
- ios/FreeLedger/ui/search/SearchView.swift (new)
- ios/FreeLedger/ui/search/SearchViewModel.swift (new)
- ios/FreeLedger/data/database/TransactionDAO.swift (modified — +search)
- ios/FreeLedger/data/repository/TransactionRepository.swift (modified — +search)
- ios/FreeLedger/ui/home/HomeView.swift (modified — +toolbar search + sheet)
- ios/FreeLedger/i18n/Localizable.strings (modified — 14 new strings)
- ios/FreeLedger/i18n/en.lproj/Localizable.strings (modified — 14 new strings)
