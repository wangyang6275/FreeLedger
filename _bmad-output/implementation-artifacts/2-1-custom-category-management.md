# Story 2.1: 自定义分类管理

Status: done

## Story

As a **user**,
I want **to create, edit, and delete my own categories**,
So that **my categories match my actual spending habits**.

## Acceptance Criteria

1. **分类管理入口:** 设置页面"分类管理"入口 → 全屏 CategoryManagement 页面
2. **分类列表:** 支出/收入分类分两个 Tab 展示，默认分类标记为"内置"，自定义分类可区分
3. **新增分类:** 点击"添加分类" → 填写名称、选择图标、选择颜色 → 保存后新分类出现在列表和记账页 CategoryGrid
4. **编辑分类:** 选择自定义分类 → 可修改名称、图标、颜色 → 保存后更新，已有交易不受影响
5. **删除分类:** 选择自定义分类 → FriendlyDialog 确认 → 分类设置 is_active=0（软删除），历史记录保留
6. **图标选择器:** 提供系统图标网格供选择
7. **颜色选择器:** 提供预定义颜色色板供选择
8. **主题一致:** 珊瑚橙渐变主题一致应用，所有颜色/间距/圆角使用 Design Tokens

## Tasks / Subtasks

- [x] Task 1: Data Layer 扩展 (AC: #3, #4, #5)
  - [x] 1.1 CategoryDAO 添加 update/deactivate/getNextSortOrder 方法
  - [x] 1.2 CategoryRepository 添加 create/update/deactivate/getNextSortOrder 方法
  - [x] 1.3 CategoryRepositoryProtocol 扩展接口
- [x] Task 2: CategoryManagementView 分类列表 (AC: #1, #2)
  - [x] 2.1 创建 ui/settings/CategoryManagementView.swift — 全屏页面
  - [x] 2.2 创建 ui/settings/CategoryManagementViewModel.swift — @Observable
  - [x] 2.3 支出/收入 Picker 切换（Segmented Control）
  - [x] 2.4 分类列表：图标 + 名称 + "内置"/"自定义"标签
  - [x] 2.5 自定义分类支持左滑删除（FriendlyDialog 确认）
  - [x] 2.6 导航栏右上角"+"添加按钮
- [x] Task 3: CategoryEditView 新增/编辑 (AC: #3, #4, #6, #7)
  - [x] 3.1 创建 ui/settings/CategoryEditView.swift — 新增/编辑共用
  - [x] 3.2 名称输入 TextField
  - [x] 3.3 图标选择器：系统图标网格（复用 CategoryIconView 图标映射）
  - [x] 3.4 颜色选择器：12色预定义色板（圆形色块网格）
  - [x] 3.5 实时预览：顶部显示当前选择的图标+颜色组合
  - [x] 3.6 保存逻辑：新增调用 create / 编辑调用 update
- [x] Task 4: 设置页入口 (AC: #1)
  - [x] 4.1 SettingsView 添加"分类管理"行 → NavigationLink
- [x] Task 5: 删除逻辑 (AC: #5)
  - [x] 5.1 软删除：is_active = 0，不物理删除
  - [x] 5.2 FriendlyDialog 确认弹窗 + withAnimation
  - [x] 5.3 删除后列表刷新，记账页 CategoryGrid 不再显示该分类
- [x] Task 6: i18n 补充 (AC: all)
  - [x] 6.1 补充 Localizable.strings (zh-Hans) — 12 新字符串
  - [x] 6.2 补充 en.lproj/Localizable.strings — 12 新字符串

## Dev Notes

### Architecture Compliance (MANDATORY)

**Tech Stack — 仅限 iOS：**
- Swift + SwiftUI + GRDB.swift, @Observable, iOS 17.0+
- MVVM + Repository
- 零网络

**10 条强制规则全部适用（同前 Stories）**

### 分类管理页面规范

```
┌─────────────────────────────────────┐
│  ← 分类管理                    +     │  ← NavigationBar
│                                     │
│  ┌──────────┐┌──────────┐           │
│  │   支出   ││   收入   │           │  ← Segmented Control
│  └──────────┘└──────────┘           │
│                                     │
│  🍔 餐饮           内置              │
│  🛒 购物           内置              │
│  🚗 交通           内置              │
│  ☕ 下午茶         自定义            │  ← 可编辑/删除
│  🎮 游戏           自定义            │
│                                     │
└─────────────────────────────────────┘
```

### 分类编辑页面规范

```
┌─────────────────────────────────────┐
│  取消    添加分类          保存       │
│                                     │
│         🍔 (预览图标)                │
│                                     │
│  名称  ┌─────────────────────┐      │
│        │ 下午茶               │      │
│        └─────────────────────┘      │
│                                     │
│  图标                               │
│  ☕ 🍔 🛒 🚗 🏠 📱 🎮 👗         │
│  💊 📖 🌍 😊 💼 💻 📈 🎁         │
│                                     │
│  颜色                               │
│  🔴 🟠 🟡 🟢 🔵 🟣 ⚫ ⚪         │
│  （预定义颜色色板）                   │
│                                     │
└─────────────────────────────────────┘
```

### 颜色色板

```swift
let presetColors = [
    "#FFE8E8", "#F3E8FF", "#FFF3E0", "#E8F4FD",
    "#E8FFE8", "#FFF0F5", "#F5F5DC", "#E0FFFF",
    "#FFDAB9", "#D8BFD8", "#FFB6C1", "#B0E0E6",
]
```

### 已有可复用的文件

- `data/model/Category.swift` — 含 isCustom, isActive 字段
- `data/database/CategoryDAO.swift` — 已有 getByType, insert（需扩展 update/deactivate）
- `data/repository/CategoryRepository.swift` — 需扩展 create/update/deactivate
- `ui/components/CategoryIconView.swift` — 图标映射（可复用图标列表）
- `ui/components/FriendlyDialog.swift` — 删除确认弹窗
- `theme/AppColors.swift` — 主题颜色
- `ui/settings/SettingsView.swift` — 设置页（需添加入口）

### Code Review 经验（Epic 1 回顾，避免重犯）

- **所有 catch 块必须有 errorMessage 或日志**（不允许空 catch）
- **DateFormatter/NumberFormatter 一律 static let**
- **使用 TransactionType enum 而非裸字符串**
- **错误需要用户可见的提示**
- **FriendlyDialog 使用 withAnimation 过渡**
- **@Observable 状态变更确保在 MainActor 上**
- **共享组件优先复用，避免重复代码**

### 自定义分类 nameKey 约定

自定义分类的 `nameKey` 不使用 i18n key，而是直接存储用户输入的名称。
显示时判断 `isCustom`：
- `isCustom == false` → `String(localized: nameKey)`
- `isCustom == true` → `nameKey`（直接显示）

### References

- [Source: architecture.md#Data Architecture] — categories 表 schema
- [Source: architecture.md#Implementation Patterns] — 命名规范
- [Source: epics.md#Story 2.1] — Acceptance Criteria (BDD)
- [Source: epic-1-retrospective.md] — Code Review 常见问题清单

## Dev Agent Record

### Agent Model Used
Claude Sonnet 4 via Windsurf Cascade

### Debug Log References
- Swift 编译器类型检查超时 → 拆分 CategoryManagementView body 为多个 computed properties
- Category 需要 Hashable 才能用于 NavigationLink(value:)

### Completion Notes List
- CategoryDAO: 添加 update/deactivate/getNextSortOrder 3个新方法
- CategoryRepository + Protocol: 扩展 create/update/deactivate/getNextSortOrder 接口
- CategoryManagementView: 支出/收入 Tab + 分类列表 + 左滑删除 + FriendlyDialog
- CategoryManagementViewModel: @Observable，管理分类加载/删除/显示名称
- CategoryEditView: 新增/编辑共用，名称+图标选择+颜色选择+实时预览
- SettingsView: 添加"分类管理" NavigationLink 入口
- ContentView: 传递 categoryRepository 给 SettingsView
- Category: 添加 Hashable 协议
- 自定义分类 nameKey 直接存用户输入，显示时根据 isCustom 判断
- Build: 0 errors, 0 warnings

### Change Log
- 2026-02-14: Story 2.1 实现 — 分类管理页面，新增/编辑/软删除，图标+颜色选择器，设置页入口，i18n
- 2026-02-14: Code review — fixed 2 MEDIUM issues:
  - M1: 内置分类显示 NavigationLink 箭头但不可点击 → 条件渲染，只对自定义分类显示 NavigationLink
  - M2: navigationDestination(for: String.self) 过于通用 → 使用专用 NewCategoryDestination enum

### File List
- ios/FreeLedger/ui/settings/CategoryManagementView.swift (new)
- ios/FreeLedger/ui/settings/CategoryManagementViewModel.swift (new)
- ios/FreeLedger/ui/settings/CategoryEditView.swift (new)
- ios/FreeLedger/data/database/CategoryDAO.swift (modified — added update/deactivate/getNextSortOrder)
- ios/FreeLedger/data/repository/CategoryRepository.swift (modified — added create/update/deactivate/getNextSortOrder)
- ios/FreeLedger/data/model/Category.swift (modified — added Hashable)
- ios/FreeLedger/ui/settings/SettingsView.swift (modified — added categoryRepository + NavigationLink)
- ios/FreeLedger/ContentView.swift (modified — pass categoryRepository to SettingsView)
- ios/FreeLedger/i18n/Localizable.strings (modified — 12 new strings)
- ios/FreeLedger/i18n/en.lproj/Localizable.strings (modified — 12 new strings)
