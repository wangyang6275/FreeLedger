# Story 2.3: 标签筛选与统计

Status: done

## Story

As a **user**,
I want **to filter transactions by tag and see tag-level statistics**,
So that **I can track spending for specific trips or projects**.

## Acceptance Criteria

1. **标签列表:** Tags Tab 显示所有标签，每个标签显示关联交易数量
2. **空状态:** 无标签时显示友好提示
3. **标签详情:** 点击标签 → 标签详情页，按日期排序显示该标签下所有交易
4. **标签汇总:** 详情页顶部显示该标签的总支出和总收入
5. **主题一致:** 珊瑚橙渐变主题一致应用，所有颜色/间距/圆角使用 Design Tokens

## Tasks / Subtasks

- [x] Task 1: Data Layer 扩展 (AC: #1, #3, #4)
  - [x] 1.1 TagDAO 添加 getTransactionCountPerTag() 方法
  - [x] 1.2 TagDAO 添加 getTransactionsForTag(tagId:) 方法
  - [x] 1.3 TagRepository 扩展对应接口
- [x] Task 2: TagsView 标签列表 (AC: #1, #2)
  - [x] 2.1 创建 TagsViewModel — @Observable
  - [x] 2.2 重写 TagsView — 标签列表 + 交易计数 + 空状态
  - [x] 2.3 标签行：胶囊颜色 + 名称 + 交易数量
- [x] Task 3: TagDetailView 标签详情 (AC: #3, #4)
  - [x] 3.1 创建 TagDetailView — 标签下交易列表
  - [x] 3.2 创建 TagDetailViewModel — @Observable
  - [x] 3.3 顶部汇总卡片：总支出 + 总收入
  - [x] 3.4 按日期分组的交易列表（复用 TransactionCard）
- [x] Task 4: ContentView 集成 (AC: #1)
  - [x] 4.1 TagsView 接收 tagRepository + transactionRepository 等依赖
  - [x] 4.2 ContentView 传递依赖
- [x] Task 5: i18n + 编译验证 (AC: all)
  - [x] 5.1 补充 Localizable.strings (zh-Hans) — 3 新字符串
  - [x] 5.2 补充 en.lproj/Localizable.strings — 3 新字符串

## Dev Notes

### Architecture Compliance (MANDATORY)

**Tech Stack — 仅限 iOS：**
- Swift + SwiftUI + GRDB.swift, @Observable, iOS 17.0+
- MVVM + Repository
- 零网络

### 已有可复用组件

- `ui/components/TransactionCard.swift` — 交易卡片（复用）
- `ui/components/SummaryCard.swift` — 参考汇总卡片样式
- `data/repository/TagRepository.swift` — 标签数据
- `data/database/TagDAO.swift` — 需扩展查询

### 标签列表行样式

```
┌─────────────────────────────────────┐
│  🔴 巴黎周末                    5 条  │
│  🟠 午餐                       12 条  │
│  🟢 项目A                       3 条  │
└─────────────────────────────────────┘
```

### 标签详情页

```
┌─────────────────────────────────────┐
│  ← 巴黎周末                         │
│                                     │
│  ┌────────────────────────────────┐ │
│  │ 支出 ¥2,500    收入 ¥0        │ │
│  └────────────────────────────────┘ │
│                                     │
│  今天                               │
│  ┌──────────────────────────────┐  │
│  │ 🍔 餐饮  -¥88    12:30      │  │
│  │ 🛒 购物  -¥200   11:00      │  │
│  └──────────────────────────────┘  │
└─────────────────────────────────────┘
```

### References

- [Source: architecture.md#Data Architecture] — tags + transaction_tags 表
- [Source: epics.md#Story 2.3] — Acceptance Criteria
- [Source: ux-design-specification.md] — 标签筛选旅程

## Dev Agent Record

### Agent Model Used
Claude Sonnet 4 via Windsurf Cascade

### Debug Log References
- MCP session defaults 需要每次重新设置

### Completion Notes List
- TagDAO: 添加 getTransactionCountPerTag/getTransactionsForTag
- TagRepository: 扩展对应接口
- TagsViewModel: @Observable，加载标签+交易计数
- TagsView: 重写为完整标签列表（颜色圆点+名称+计数）+ 空状态
- TagDetailViewModel: @Observable，标签下交易+汇总计算+日期分组
- TagDetailView: 汇总卡片（支出/收入）+ 分组交易列表（复用 TransactionCard）
- ContentView: TagsView 接收全部依赖
- 标签详情可导航到 TransactionDetailView
- Build: 0 errors, 0 warnings
- Code Review: 0 issues

### Change Log
- 2026-02-14: Story 2.3 实现 — 标签筛选与统计，TagsView+TagDetailView，汇总卡片，i18n

### File List
- ios/FreeLedger/ui/tags/TagsViewModel.swift (new)
- ios/FreeLedger/ui/tags/TagDetailView.swift (new)
- ios/FreeLedger/ui/tags/TagDetailViewModel.swift (new)
- ios/FreeLedger/ui/tags/TagsView.swift (modified — full rewrite)
- ios/FreeLedger/data/database/TagDAO.swift (modified — +2 query methods)
- ios/FreeLedger/data/repository/TagRepository.swift (modified — +2 interface methods)
- ios/FreeLedger/ContentView.swift (modified — pass dependencies to TagsView)
- ios/FreeLedger/i18n/Localizable.strings (modified — 3 new strings)
- ios/FreeLedger/i18n/en.lproj/Localizable.strings (modified — 3 new strings)
