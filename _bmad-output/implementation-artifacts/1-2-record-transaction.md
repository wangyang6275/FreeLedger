# Story 1.2: 记录一笔交易

Status: done

## Story

As a **user**,
I want **to quickly record an income or expense transaction**,
So that **I can track my spending in under 3 seconds**.

## Acceptance Criteria

1. **DB 初始化:** 首次启动时创建 transactions, categories, settings, schema_version 四张表；从 shared/default-data/ 导入默认分类；根据系统 Locale 设置默认货币 (FR7, FR41)
2. **记账入口:** 点击 "+" FloatingAddButton → 记账页从底部滑入（300ms ease-out），AmountKeypad 和 CategoryGrid 可见
3. **金额输入:** AmountKeypad 输入金额实时显示在顶部显示区，带货币符号（FR38），支持退格修改
4. **选分类保存:** 点击 CategoryGrid 中的分类图标 → 图标高亮 + ✓ 动效 → 自动保存交易 → 页面滑出返回首页 (FR1, FR2)
5. **智能排序:** 分类按 usage_count 降序排列，常用分类排在前面 (FR3)
6. **备注输入:** 点击备注区展开文字输入框，可选填备注 (FR6)
7. **收支切换:** 点击收入/支出 toggle 切换分类列表

## Tasks / Subtasks

- [x] Task 1: 数据模型 + 数据库初始化 (AC: #1)
  - [x] 1.1 创建 data/model/Transaction.swift — GRDB Record 类型，字段与架构文档一致
  - [x] 1.2 创建 data/model/Category.swift — GRDB Record 类型
  - [x] 1.3 创建 data/model/Setting.swift — GRDB Record 类型 (key-value)
  - [x] 1.4 创建 data/database/AppDatabase.swift — DatabaseQueue 初始化 + 建表迁移 (transactions, categories, settings, schema_version) + 索引
  - [x] 1.5 创建 data/database/CategoryDAO.swift — getAll(type:), getByType(sorted:), insert, updateUsageCount
  - [x] 1.6 创建 data/database/TransactionDAO.swift — insert, getAll, getById, update, delete
  - [x] 1.7 创建 data/database/SettingsDAO.swift — get(key:), set(key:value:)
  - [x] 1.8 实现首次启动种子数据：读取 Bundle 中的 categories-expense.json / categories-income.json → 插入 categories 表
  - [x] 1.9 实现默认货币设置：读取 Locale.current → 写入 settings 表 key="currency"
- [x] Task 2: Repository 层 (AC: #1, #4, #5)
  - [x] 2.1 创建 data/repository/CategoryRepository.swift — protocol + 实现，getExpenseCategories(sorted:), getIncomeCategories(sorted:), incrementUsageCount
  - [x] 2.2 创建 data/repository/TransactionRepository.swift — protocol + 实现，insert(amount:type:categoryId:note:) 含事务内 usage_count 更新
  - [x] 2.3 创建 data/repository/SettingsRepository.swift — protocol + 实现，getCurrency()
- [x] Task 3: 工具类 (AC: #3)
  - [x] 3.1 创建 util/AmountFormatter.swift — Int64 分 → 带货币符号的显示字符串，使用 NumberFormatter + Locale
  - [x] 3.2 创建 util/AppError.swift — 错误类型枚举
- [x] Task 4: AmountKeypad 组件 (AC: #3)
  - [x] 4.1 创建 ui/components/AmountKeypad.swift — 4x3 网格数字键盘 (1-9, 标签, 0, 退格)
  - [x] 4.2 金额输入逻辑：最多 2 位小数，最大 999999 元，实时回调
  - [x] 4.3 触觉反馈：每次按键 UIImpactFeedbackGenerator(.light)
  - [x] 4.4 无障碍：每个按键设置 accessibilityLabel
- [x] Task 5: CategoryGrid 组件 (AC: #4, #5, #7)
  - [x] 5.1 创建 ui/components/CategoryGrid.swift — LazyVGrid 4 列，圆形彩色背景 + SF Symbol 图标 + 分类名
  - [x] 5.2 选中动效：图标高亮 + ✓ overlay + spring(0.3, 0.6) 动画
  - [x] 5.3 按 usage_count 降序排列
  - [x] 5.4 无障碍：每个分类项 accessibilityLabel = "分类名，按钮"
- [x] Task 6: RecordView 记账页面 (AC: #2, #3, #4, #6, #7)
  - [x] 6.1 创建 ui/record/RecordViewModel.swift — @Observable，管理金额输入状态、分类列表、收支切换、保存逻辑
  - [x] 6.2 创建 ui/record/RecordView.swift — 页面布局：顶部金额显示区 + 收支 toggle + 备注区 + CategoryGrid + AmountKeypad
  - [x] 6.3 底部滑入呈现：.sheet() + .presentationDetents([.large]) + dragIndicator
  - [x] 6.4 保存流程：选分类 → 事务内 insert transaction + incrementUsageCount → dismiss
  - [x] 6.5 备注区：默认收起，点击展开 TextField
- [x] Task 7: 导航集成 (AC: #2)
  - [x] 7.1 修改 ContentView.swift — FloatingAddButton 点击 → .sheet 呈现 RecordView
  - [x] 7.2 保存成功后 onChange(didSave) → dismiss 自动关闭
- [x] Task 8: i18n 补充 (AC: all)
  - [x] 8.1 补充 Localizable.strings (zh-Hans) — 记账页、分类、错误、无障碍文本
  - [x] 8.2 补充 en.lproj/Localizable.strings — 英文翻译

## Dev Notes

### Architecture Compliance (MANDATORY)

**Tech Stack — 仅限 iOS（Android 暂不开发）：**
- Swift + SwiftUI + GRDB.swift, @Observable, iOS 17.0+
- 架构: MVVM + Repository
- 零网络: 不添加任何网络库

**10 条强制规则 — 全部适用：**
1. 金额 Int64（分）存储，显示 / 100
2. 日期 ISO 8601 字符串存储，显示用 Locale 格式化
3. 所有 DB 写操作在事务中执行
4. 所有用户可见文本通过 i18n key — 禁止硬编码
5. 所有 UI 颜色/间距/圆角引用 Design Tokens — 禁止硬编码
6. 所有可交互元素设置 accessibilityLabel
7. 错误提示"温暖友好"语气
8. Repository 接口双端对称（当前仅实现 iOS 端）
9. 文件/类命名遵循规范
10. 不引入网络库

### Database Schema (Story 1.2 需创建的表)

**transactions:**
```
id          TEXT (UUID) PRIMARY KEY
amount      INTEGER (Int64) — 单位：分
type        TEXT — "income" / "expense"
category_id TEXT (UUID) — FK → categories
note        TEXT — 可空
created_at  TEXT (ISO 8601)
updated_at  TEXT (ISO 8601)
```

**categories:**
```
id          TEXT (UUID) PRIMARY KEY
name_key    TEXT — i18n key
icon_name   TEXT — Ant Design 图标名
color_hex   TEXT — 背景色
type        TEXT — "income" / "expense"
sort_order  INTEGER
usage_count INTEGER DEFAULT 0
is_custom   INTEGER (0/1) DEFAULT 0
is_active   INTEGER (0/1) DEFAULT 1
```

**settings:**
```
key         TEXT PRIMARY KEY
value       TEXT
```

**schema_version:**
```
version     INTEGER
migrated_at TEXT (ISO 8601)
```

**索引：**
- `idx_transactions_created_at` → transactions(created_at DESC)
- `idx_transactions_category_id` → transactions(category_id)
- `idx_transactions_type_created_at` → transactions(type, created_at)
- `idx_categories_type_usage` → categories(type, usage_count DESC)

### GRDB.swift 使用模式

```swift
// Model 定义
struct Transaction: Codable, FetchableRecord, PersistableRecord {
    var id: String  // UUID string
    var amount: Int64
    var type: String  // "income" / "expense"
    var categoryId: String
    var note: String?
    var createdAt: String  // ISO 8601
    var updatedAt: String  // ISO 8601

    static let databaseTableName = "transactions"

    enum Columns: String, ColumnExpression {
        case id, amount, type, categoryId = "category_id"
        case note, createdAt = "created_at", updatedAt = "updated_at"
    }
}

// 数据库初始化
var migrator = DatabaseMigrator()
migrator.registerMigration("v1") { db in
    try db.create(table: "transactions") { t in
        t.column("id", .text).primaryKey()
        t.column("amount", .integer).notNull()
        // ...
    }
}
try migrator.migrate(dbQueue)
```

### AmountKeypad 布局规范

```
┌─────────────────────────────┐
│     ¥ 0.00                  │  ← 金额显示区 (Display 32pt, bold)
│     支出 ◉ ○ 收入           │  ← 收支 toggle
│     点击添加备注...          │  ← 备注区 (可展开)
├─────────────────────────────┤
│  🍔  🛒  🚗  🏠             │  ← CategoryGrid (3-4 列)
│  📱  🎮  👔  💊             │
│  📚  🌍  👶                 │
├─────────────────────────────┤
│  1  │  2  │  3  │           │  ← AmountKeypad (4x3)
│  4  │  5  │  6  │           │
│  7  │  8  │  9  │           │
│  🏷  │  0  │  ⌫  │           │  ← 标签(Story 2.2) / 0 / 退格
└─────────────────────────────┘
```

- 按键高度：56pt，间距 AppSpacing.sm (8pt)
- 数字字体：AppTypography.keypadNumber (28pt bold)
- 退格图标：SF Symbol "delete.backward"
- 标签按钮：SF Symbol "tag"（Story 2.2 激活，当前禁用灰色）

### CategoryGrid 规范

- 列数：4 列（iPhone），间距 AppSpacing.md (12pt)
- 每项：圆形背景 (48pt) + 图标 (24pt) + 名称 (Caption 13pt)
- 选中态：背景加深 + 白色 ✓ overlay + spring(0.6) 动画
- 图标来源：使用 SF Symbols 作为占位（后续替换为 Ant Design SVG Asset）
- 排序：usage_count DESC, sort_order ASC

### 金额输入逻辑

```
状态: amountString = ""
- 输入数字: append digit, 最多 8 位整数 + 2 位小数
- 输入小数点: 只允许一次
- 退格: 删除最后一个字符
- 转换: Int64(cents) = Double(amountString) * 100
- 显示: AmountFormatter.format(cents, locale)
- 验证: amount > 0 才允许选分类保存
```

### 保存流程

```
1. 用户输入金额 → amountString 更新
2. 用户点击分类 →
   a. 验证 amount > 0
   b. 创建 Transaction(id: UUID, amount: cents, type, categoryId, note, createdAt: ISO8601.now, updatedAt: ISO8601.now)
   c. 在事务中: INSERT transaction + UPDATE category.usage_count += 1
   d. dismiss RecordView
3. 返回首页（Story 1.3 实现列表刷新）
```

### Previous Story Intelligence (Story 1.1)

**已创建的文件（可直接使用）：**
- `theme/AppColors.swift` — 所有颜色常量 + Color(hex:) 扩展
- `theme/AppSpacing.swift` — 间距常量
- `theme/AppRadius.swift` — 圆角常量
- `theme/AppTypography.swift` — 字体常量
- `ui/components/FloatingAddButton.swift` — FAB 组件
- `ContentView.swift` — TabView + FAB（需修改添加导航）
- `i18n/Localizable.strings` — 已有 tab 和空状态文本
- `FreeLedgerApp.swift` — App 入口

**已有的 Xcode 项目配置：**
- `ios/project.yml` — xcodegen 配置，已包含 GRDB SPM 依赖
- `ios/FreeLedger.xcodeproj` — 已生成，编译通过

**注意事项：**
- 新增文件后需运行 `xcodegen generate` 重新生成 .xcodeproj
- 或手动在 Xcode 中添加文件引用
- Bundle 资源（JSON 文件）需确保 Copy Bundle Resources 包含

### References

- [Source: architecture.md#Data Architecture] — 6 表 schema 定义、索引策略
- [Source: architecture.md#Mobile Architecture] — MVVM + Repository, @Observable, NavigationStack
- [Source: architecture.md#Implementation Patterns] — 命名规范、格式规范、错误处理
- [Source: architecture.md#Enforcement Guidelines] — 10 条强制规则
- [Source: architecture.md#Project Structure] — 完整目录结构
- [Source: ux-design-specification.md#AmountKeypad] — 键盘组件规范
- [Source: ux-design-specification.md#CategoryGrid] — 分类网格规范
- [Source: ux-design-specification.md#Experience Mechanics] — 记账界面布局和交互流程
- [Source: ux-design-specification.md#Animation System] — 动效时长和曲线
- [Source: ux-design-specification.md#Accessibility] — VoiceOver 标签规范
- [Source: epics.md#Story 1.2] — Acceptance Criteria (BDD)
- [Source: prd.md#FR1-FR7] — 核心记账功能需求

## Dev Agent Record

### Agent Model Used

Claude (Cascade)

### Debug Log References

- Swift 6 Sendable concurrency error on AppDatabase.shared → Fixed by marking class as `Sendable`
- Initial `nonisolated(unsafe)` was unnecessary after Sendable conformance → Removed

### Completion Notes List

- **Data Layer:** 3 models (Transaction, Category, Setting) + AppDatabase with v1 migration (4 tables + 4 indexes) + 3 DAOs + seed data from Bundle JSON
- **Repository Layer:** 3 repositories with protocol + implementation. TransactionRepository.insert uses single transaction for both INSERT + usage_count UPDATE
- **Utilities:** AmountFormatter (cents ↔ display with Locale) + AppError enum
- **UI Components:** AmountKeypad (4x3 grid, haptic feedback, 2-decimal limit, a11y) + CategoryGrid (4-col LazyVGrid, spring animation, SF Symbol icons, a11y)
- **Record Page:** RecordViewModel (@Observable) + RecordView (amount display + type toggle + note + CategoryGrid + AmountKeypad)
- **Navigation:** ContentView.sheet → RecordView, auto-dismiss on save
- **i18n:** 50+ strings added (zh-Hans + en) — record page, 16 categories, errors, accessibility
- **Build:** xcodebuild passes with 0 errors, 0 warnings
- CategoryGrid uses SF Symbols as icon placeholders (maps Ant Design icon names → SF Symbols)

### Change Log

- 2026-02-14: Story 1.2 implementation — database layer, repository layer, AmountKeypad, CategoryGrid, RecordView, navigation integration, i18n
- 2026-02-14: Code review — fixed 4 HIGH + 5 MEDIUM issues (decimal point button, error handling, JSON load logging, static formatter, DI optimization, type enum, reduce motion, force-unwrap, a11y key)

### File List

- ios/FreeLedger/data/model/Transaction.swift (new)
- ios/FreeLedger/data/model/Category.swift (new)
- ios/FreeLedger/data/model/Setting.swift (new)
- ios/FreeLedger/data/database/AppDatabase.swift (new)
- ios/FreeLedger/data/database/CategoryDAO.swift (new)
- ios/FreeLedger/data/database/TransactionDAO.swift (new)
- ios/FreeLedger/data/database/SettingsDAO.swift (new)
- ios/FreeLedger/data/repository/CategoryRepository.swift (new)
- ios/FreeLedger/data/repository/TransactionRepository.swift (new)
- ios/FreeLedger/data/repository/SettingsRepository.swift (new)
- ios/FreeLedger/util/AmountFormatter.swift (new)
- ios/FreeLedger/util/AppError.swift (new)
- ios/FreeLedger/ui/components/AmountKeypad.swift (new)
- ios/FreeLedger/ui/components/CategoryGrid.swift (new)
- ios/FreeLedger/ui/record/RecordViewModel.swift (new)
- ios/FreeLedger/ui/record/RecordView.swift (new)
- ios/FreeLedger/data/categories-expense.json (copied from shared)
- ios/FreeLedger/data/categories-income.json (copied from shared)
- ios/FreeLedger/ContentView.swift (modified — added sheet navigation)
- ios/FreeLedger/FreeLedgerApp.swift (modified — added seed data init)
- ios/FreeLedger/i18n/Localizable.strings (modified — added 50+ strings)
- ios/FreeLedger/i18n/en.lproj/Localizable.strings (modified — added 50+ strings)
- ios/project.yml (modified — added JSON resources)
