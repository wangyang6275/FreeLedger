# Story 2.2: 标签创建与关联

Status: done

## Story

As a **user**,
I want **to create tags and assign them to transactions**,
So that **I can organize records by project or occasion**.

## Acceptance Criteria

1. **数据库迁移:** tags 和 transaction_tags 表通过 GRDB migration v2 自动创建，含索引
2. **标签按钮入口:** 记账页 AmountKeypad 左下角标签按钮（已有 `.tag` KeypadKey）→ 弹出 TagSelector 底部面板
3. **TagSelector 面板:** 底部弹出面板，显示已有标签（胶囊按钮流式布局），支持多选
4. **标签选中态:** 未选中=描边，选中=填充标签颜色+白色文字
5. **新建标签:** TagSelector 中点击"+"→ 输入名称+选择颜色 → 创建后立即可选
6. **标签保存:** 选中的标签随交易一起保存到 transaction_tags 关联表
7. **编辑交易标签:** TransactionDetailView 编辑模式下可增删标签
8. **主题一致:** 珊瑚橙渐变主题一致应用，所有颜色/间距/圆角使用 Design Tokens

## Tasks / Subtasks

- [x] Task 1: Data Layer — Tag 模型 + DAO + Repository (AC: #1)
  - [x] 1.1 创建 data/model/Tag.swift — Tag struct (id, name, colorHex, createdAt)
  - [x] 1.2 创建 data/model/TransactionTag.swift — TransactionTag struct (transactionId, tagId)
  - [x] 1.3 AppDatabase migration v2: 创建 tags + transaction_tags 表 + 索引
  - [x] 1.4 创建 data/database/TagDAO.swift — CRUD + getByTransactionId + getAll
  - [x] 1.5 创建 data/repository/TagRepository.swift + TagRepositoryProtocol
- [x] Task 2: TransactionRepository 扩展 (AC: #6)
  - [x] 2.1 insert 方法增加 tagIds 参数，保存交易时同时写入 transaction_tags
  - [x] 2.2 添加 getTagsForTransaction(transactionId:) 方法
  - [x] 2.3 添加 setTagsForTransaction(transactionId:, tagIds:) 方法
- [x] Task 3: TagSelector 组件 (AC: #2, #3, #4)
  - [x] 3.1 创建 ui/components/TagSelector.swift — 底部面板 + FlowLayout
  - [x] 3.2 流式布局标签胶囊（自定义 FlowLayout）
  - [x] 3.3 多选逻辑：点击切换选中/未选中
  - [x] 3.4 选中态样式：填充标签颜色+白色文字；未选中态：描边+标签颜色文字
- [x] Task 4: 新建标签 (AC: #5)
  - [x] 4.1 TagSelector 中"+"按钮 → 内联输入名称+选颜色
  - [x] 4.2 创建后立即添加到列表并自动选中
- [x] Task 5: RecordView 集成 (AC: #2, #6)
  - [x] 5.1 RecordView 添加 @State selectedTagIds: Set<String>
  - [x] 5.2 AmountKeypad onTagTap → 弹出 TagSelector sheet (.medium)
  - [x] 5.3 RecordViewModel.saveTransaction 增加 tagIds 参数
  - [x] 5.4 ContentView 传递 tagRepository 到 RecordView + HomeView
- [x] Task 6: TransactionDetailView 集成 (AC: #7)
  - [x] 6.1 详情页显示关联标签（FlowLayout 胶囊列表）
  - [x] 6.2 编辑模式下可打开 TagSelector 增删标签
  - [x] 6.3 保存编辑时同步更新 transaction_tags
- [x] Task 7: i18n 补充 (AC: all)
  - [x] 7.1 补充 Localizable.strings (zh-Hans) — 6 新字符串
  - [x] 7.2 补充 en.lproj/Localizable.strings — 6 新字符串

## Dev Notes

### Architecture Compliance (MANDATORY)

**Tech Stack — 仅限 iOS：**
- Swift + SwiftUI + GRDB.swift, @Observable, iOS 17.0+
- MVVM + Repository
- 零网络

**10 条强制规则全部适用（同前 Stories）**

### 数据库 Schema

```sql
-- Migration v2
CREATE TABLE tags (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    color_hex TEXT NOT NULL,
    created_at TEXT NOT NULL
);

CREATE TABLE transaction_tags (
    transaction_id TEXT NOT NULL REFERENCES transactions(id) ON DELETE CASCADE,
    tag_id TEXT NOT NULL REFERENCES tags(id) ON DELETE CASCADE,
    PRIMARY KEY (transaction_id, tag_id)
);

CREATE INDEX idx_transaction_tags_transaction_id ON transaction_tags(transaction_id);
CREATE INDEX idx_transaction_tags_tag_id ON transaction_tags(tag_id);
```

### TagSelector 组件规范

```
┌─────────────────────────────────────┐
│  标签                         完成   │  ← 标题 + 完成按钮
│                                     │
│  ┌──────┐ ┌──────┐ ┌──────┐ ┌──┐  │
│  │巴黎游│ │午餐  │ │项目A │ │ + │  │  ← 胶囊按钮流式布局
│  └──────┘ └──────┘ └──────┘ └──┘  │
│                                     │
│  ┌────────────────────────────────┐ │
│  │ 新建标签                       │ │  ← 内联新建区域（点击+展开）
│  │ 名称: [________]              │ │
│  │ 颜色: 🔴🟠🟡🟢🔵🟣          │ │
│  │              [创建]            │ │
│  └────────────────────────────────┘ │
└─────────────────────────────────────┘
```

### 胶囊样式

```swift
// 选中态
Text(tag.name)
    .font(AppTypography.caption)
    .foregroundColor(.white)
    .padding(.horizontal, AppSpacing.md)
    .padding(.vertical, AppSpacing.xs)
    .background(Color(hex: tag.colorHex))
    .clipShape(Capsule())

// 未选中态
Text(tag.name)
    .font(AppTypography.caption)
    .foregroundColor(Color(hex: tag.colorHex))
    .padding(.horizontal, AppSpacing.md)
    .padding(.vertical, AppSpacing.xs)
    .overlay(Capsule().stroke(Color(hex: tag.colorHex), lineWidth: 1))
```

### 标签颜色色板（复用 CategoryEditView 的 presetColors）

```swift
let tagPresetColors = [
    "#FF6B6B", "#FF8E53", "#FFC107", "#4CAF50",
    "#2196F3", "#9C27B0", "#795548", "#607D8B",
]
```

### 已有可复用的文件

- `ui/components/AmountKeypad.swift` — 已有 `.tag` KeypadKey 和 `onTagTap` 回调
- `ui/components/FriendlyDialog.swift` — 可复用弹窗
- `ui/detail/TransactionDetailView.swift` — 需扩展标签显示/编辑
- `ui/detail/TransactionDetailViewModel.swift` — 需扩展标签状态
- `ui/record/RecordView.swift` — 需集成 TagSelector
- `ui/record/RecordViewModel.swift` — 需扩展 saveTransaction
- `data/repository/TransactionRepository.swift` — 需扩展标签关联
- `data/database/AppDatabase.swift` — 需添加 migration v2
- `ContentView.swift` — 需传递 tagRepository

### 关键设计决策

1. **transaction_tags 使用 ON DELETE CASCADE** — 删除交易时自动清理关联标签
2. **Tag 不软删除** — 标签直接硬删除（与分类不同，标签无历史依赖）
3. **TagSelector 使用 .sheet + .presentationDetents([.medium])** — 底部弹出面板
4. **新建标签内联在 TagSelector 中** — 不跳转新页面，减少步骤
5. **RecordView 中标签预览** — 已选标签以小胶囊显示在 header 区域备注下方

### Code Review 经验（避免重犯）

- **所有 catch 块必须有 errorMessage 或日志**
- **DateFormatter/NumberFormatter 一律 static let**
- **FriendlyDialog 使用 withAnimation 过渡**
- **复杂 body 拆分子视图避免编译器超时**
- **navigationDestination 用专用类型不用 String.self**
- **NavigationLink 不可点击项不应显示箭头**

### References

- [Source: architecture.md#Data Architecture] — tags + transaction_tags 表 schema
- [Source: ux-design-specification.md#TagSelector] — 组件规范
- [Source: epics.md#Story 2.2] — Acceptance Criteria (BDD)
- [Source: epic-1-retrospective.md] — Code Review 常见问题清单

## Dev Agent Record

### Agent Model Used
Claude Sonnet 4 via Windsurf Cascade

### Debug Log References
- MCP session defaults 需要重新设置 scheme/simulatorId/bundleId

### Completion Notes List
- Tag + TransactionTag 模型，GRDB migration v2 创建表+索引
- TagDAO: getAll/getById/insert/update/delete/getTagsForTransaction/setTagsForTransaction
- TagRepository + TagRepositoryProtocol
- TransactionRepository: insert 增加 tagIds，新增 getTagsForTransaction/setTagsForTransaction
- TagSelector: 底部面板 + FlowLayout 流式布局 + 多选胶囊 + 内联新建标签
- RecordView: onTagTap → TagSelector sheet，saveTransaction 传递 tagIds
- TransactionDetailView: 查看模式显示标签胶囊，编辑模式 TagSelector 增删标签
- TransactionDetailViewModel: tags 状态 + editTagIds + 保存时同步更新
- ContentView: 创建 tagDAO/tagRepository，传递给 HomeView/RecordView
- HomeView: 接收 tagRepository 传递给 TransactionDetailView
- Build: 0 errors, 0 warnings

### Change Log
- 2026-02-14: Story 2.2 实现 — 标签创建与关联，TagSelector 组件，FlowLayout，记账+详情集成，i18n
- 2026-02-14: Code review — passed, 0 issues found

### File List
- ios/ColorFuLedger/data/model/Tag.swift (new)
- ios/ColorFuLedger/data/model/TransactionTag.swift (new)
- ios/ColorFuLedger/data/database/TagDAO.swift (new)
- ios/ColorFuLedger/data/repository/TagRepository.swift (new)
- ios/ColorFuLedger/ui/components/TagSelector.swift (new — includes FlowLayout)
- ios/ColorFuLedger/data/database/AppDatabase.swift (modified — migration v2)
- ios/ColorFuLedger/data/repository/TransactionRepository.swift (modified — tagIds + tag methods)
- ios/ColorFuLedger/ui/record/RecordView.swift (modified — TagSelector integration)
- ios/ColorFuLedger/ui/record/RecordViewModel.swift (modified — tagIds in saveTransaction)
- ios/ColorFuLedger/ui/detail/TransactionDetailView.swift (modified — tag display + edit)
- ios/ColorFuLedger/ui/detail/TransactionDetailViewModel.swift (modified — tags state + editTagIds)
- ios/ColorFuLedger/ui/home/HomeView.swift (modified — tagRepository parameter)
- ios/ColorFuLedger/ContentView.swift (modified — tagDAO/tagRepository creation + passing)
- ios/ColorFuLedger/i18n/Localizable.strings (modified — 6 new strings)
- ios/ColorFuLedger/i18n/en.lproj/Localizable.strings (modified — 6 new strings)
