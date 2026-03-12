# Story 1.4: 记录详情、编辑与删除

Status: done

## Story

As a **user**,
I want **to view, edit, and delete my transaction records**,
So that **I can correct mistakes and manage my data**.

## Acceptance Criteria

1. **详情页展示:** 点击首页 TransactionCard → 全屏 TransactionDetail 页面，显示分类图标（大）、金额（Display 字号）、分类名、备注、日期时间
2. **编辑功能:** 点击导航栏右上角"编辑"按钮 → 进入编辑模式，可修改金额、分类、备注 → 保存/取消
3. **编辑保存:** 点击"保存"后数据库更新，首页列表自动刷新反映变更
4. **删除确认:** 点击底部"删除"按钮 → FriendlyDialog 弹出："确定删除这条记录吗？删除后无法恢复哦" → 确认/取消
5. **删除执行:** 确认删除后记录永久删除，自动返回首页，列表中该记录消失
6. **左滑删除:** 首页 TransactionCard 左滑显示红色删除按钮
7. **主题一致:** 珊瑚橙渐变主题一致应用，所有颜色/间距/圆角使用 Design Tokens

## Tasks / Subtasks

- [x] Task 1: TransactionDetail 详情页 (AC: #1)
  - [x] 1.1 创建 ui/detail/TransactionDetailView.swift — 全屏页面，NavigationStack 内
  - [x] 1.2 创建 ui/detail/TransactionDetailViewModel.swift — @Observable，管理交易详情 + 分类信息 + 编辑状态
  - [x] 1.3 详情布局：顶部大图标 (80pt) + 金额 (Display) + 分类名 + 备注 + 日期时间（iOS 风格分组列表）
  - [x] 1.4 无障碍：页面标题"记录详情"，所有字段有语义标签
- [x] Task 2: 编辑模式 (AC: #2, #3)
  - [x] 2.1 导航栏右上角"编辑"按钮 → 切换 isEditing 状态
  - [x] 2.2 编辑态：金额可重新输入（内联 AmountKeypad 或 TextField）、分类可重选（CategoryGrid sheet）、备注可修改
  - [x] 2.3 编辑态导航栏：左"取消" + 右"保存"
  - [x] 2.4 保存逻辑：调用 TransactionRepository.update，更新 updatedAt 时间戳
  - [x] 2.5 保存成功后退出编辑模式，详情页刷新数据
- [x] Task 3: FriendlyDialog 组件 (AC: #4)
  - [x] 3.1 创建 ui/components/FriendlyDialog.swift — 自定义弹窗组件
  - [x] 3.2 圆角 16pt 卡片居中，半透明遮罩背景
  - [x] 3.3 变体支持：信息提示（单按钮）、确认操作（双按钮）、危险操作（确认按钮柔橙红）
  - [x] 3.4 无障碍：弹窗出现时 VoiceOver 聚焦到标题
- [x] Task 4: 删除功能 (AC: #4, #5)
  - [x] 4.1 详情页底部"删除记录"按钮（红色文字）
  - [x] 4.2 点击 → FriendlyDialog 弹出确认
  - [x] 4.3 确认删除 → TransactionRepository.delete → 返回首页
  - [x] 4.4 首页自动刷新（通过 NavigationStack pop + HomeViewModel.loadData）
- [x] Task 5: 左滑删除 (AC: #6)
  - [x] 5.1 HomeView TransactionCard 添加 .swipeActions → 红色删除按钮
  - [x] 5.2 左滑删除也弹出 FriendlyDialog 确认
  - [x] 5.3 确认后删除 + 刷新列表
- [x] Task 6: 导航集成 (AC: #1, #3, #5)
  - [x] 6.1 HomeView TransactionCard 添加 NavigationLink → TransactionDetailView
  - [x] 6.2 传递 transaction + categoryDict + repositories
  - [x] 6.3 详情页返回后自动刷新首页数据
- [x] Task 7: i18n 补充 (AC: all)
  - [x] 7.1 补充 Localizable.strings (zh-Hans) — 详情页、编辑、删除、FriendlyDialog 文本
  - [x] 7.2 补充 en.lproj/Localizable.strings — 英文翻译

## Dev Notes

### Architecture Compliance (MANDATORY)

**Tech Stack — 仅限 iOS：**
- Swift + SwiftUI + GRDB.swift, @Observable, iOS 17.0+
- MVVM + Repository
- 零网络

**10 条强制规则全部适用（同 Story 1.2/1.3）**

### TransactionDetail 规范

```
┌─────────────────────────────────────┐
│  ← 记录详情              编辑       │  ← NavigationBar
│                                     │
│         🍔 (80pt 大图标)            │
│       ¥ 25.00 (Display 32pt)       │
│         餐饮                        │
│                                     │
│  ┌─────────────────────────────┐    │
│  │ 备注        午餐             │    │  ← iOS 风格分组
│  │ 日期        2月14日 12:30    │    │
│  │ 类型        支出             │    │
│  └─────────────────────────────┘    │
│                                     │
│       删除记录 (红色文字)            │  ← 底部
└─────────────────────────────────────┘
```

- 背景：AppColors.background
- 大图标：CategoryIconView(size: 80, iconSize: 40)
- 金额：AppTypography.display, AppColors.textPrimary
- 分类名：AppTypography.title2, AppColors.textPrimary
- 信息列表：iOS GroupedListStyle 风格
- 删除按钮：AppColors.expense (红色文字)，无背景

### FriendlyDialog 规范

```
┌─────────────────────────────────┐
│                                 │
│   确定删除这条记录吗？           │  ← 标题 (title2, bold)
│   删除后无法恢复哦               │  ← 描述 (body, textSecondary)
│                                 │
│   ┌──────────┐ ┌──────────┐    │
│   │   取消   │ │   删除   │    │  ← 双按钮
│   └──────────┘ └──────────┘    │
│                                 │
└─────────────────────────────────┘
```

- 卡片：白色背景，圆角 AppRadius.lg (16pt)，内边距 AppSpacing.xl
- 遮罩：黑色 0.4 透明度
- 取消按钮：AppColors.textSecondary 背景，白色文字
- 危险确认按钮：AppColors.expense 背景，白色文字
- 普通确认按钮：AppColors.primary 背景，白色文字

### 编辑模式规范

- 编辑态金额：使用 TextField + NumberFormatter，或内联 AmountKeypad
- 编辑态分类：点击分类区域 → 弹出 CategoryGrid sheet
- 编辑态备注：TextField 可编辑
- 保存时更新 updatedAt = ISO8601DateFormatter().string(from: Date())
- 取消时恢复原始数据

### 左滑删除规范

```swift
.swipeActions(edge: .trailing, allowsFullSwipe: false) {
    Button(role: .destructive) {
        // show FriendlyDialog
    } label: {
        Label(String(localized: "action_delete"), systemImage: "trash")
    }
}
```

### Previous Story Intelligence (Story 1.2 + 1.3)

**已有可复用的文件：**
- `data/model/Transaction.swift` — 含 TransactionType enum
- `data/model/Category.swift` — 分类模型 (Equatable)
- `data/repository/TransactionRepository.swift` — 已有 update/delete 方法
- `ui/components/CategoryIconView.swift` — 共享图标组件（可传 size/iconSize）
- `ui/components/CategoryGrid.swift` — 分类选择网格（支持 selectedId）
- `ui/components/AmountKeypad.swift` — 金额键盘
- `ui/components/TransactionCard.swift` — 流水卡片
- `ui/home/HomeViewModel.swift` — 已有 loadData() 刷新方法
- `util/AmountFormatter.swift` — 金额格式化
- `util/DateFormatter+App.swift` — 日期格式化
- `theme/AppColors.swift` — 含 expense, income, primaryGradient

**Code Review 经验（避免重犯）：**
- 使用 TransactionType enum 而非裸字符串
- 静态 DateFormatter 避免重复创建
- 错误不能静默吞掉，需要用户可见的提示
- 尊重 reduceMotion 无障碍设置
- 避免 force-unwrap
- @Observable 状态变更确保在 MainActor 上
- 使用共享 CategoryIconView 而非重复图标映射

### References

- [Source: architecture.md#Data Architecture] — transactions 表 schema + 索引
- [Source: architecture.md#Mobile Architecture] — MVVM + @Observable, NavigationStack
- [Source: architecture.md#Implementation Patterns] — 命名规范、格式规范
- [Source: architecture.md#Enforcement Guidelines] — 10 条强制规则
- [Source: ux-design-specification.md#TransactionDetail] — 详情页规范
- [Source: ux-design-specification.md#FriendlyDialog] — 温暖弹窗规范
- [Source: ux-design-specification.md#Accessibility] — VoiceOver 标签规范
- [Source: epics.md#Story 1.4] — Acceptance Criteria (BDD)

## Dev Agent Record

### Agent Model Used
Claude Sonnet 4 via Windsurf Cascade

### Debug Log References
- swipeActions 需要 List 而非 LazyVStack，重构 HomeView 为 List + .listStyle(.plain)
- .onAppear 位置从 NavigationStack 外层移到内层，确保从详情页返回后刷新

### Completion Notes List
- TransactionDetailView: 全屏详情页，大图标(80pt) + Display金额 + iOS风格分组信息列表
- 编辑模式: TextField金额 + CategoryGrid sheet分类 + TextField备注
- FriendlyDialog: 3种变体(info/confirm/destructive)，圆角卡片 + 半透明遮罩
- 删除: 详情页底部红色按钮 + FriendlyDialog 确认 + dismiss返回
- 左滑删除: HomeView List swipeActions + FriendlyDialog 确认
- 导航: NavigationLink(value:) + .navigationDestination + .onAppear刷新
- Transaction 模型: 添加 Hashable + currentISO() 静态方法
- i18n: 20+ 新字符串 (zh-Hans + en)
- Build: 0 errors, 0 warnings

### Change Log
- 2026-02-14: Story 1.4 实现 — TransactionDetail详情/编辑/删除，FriendlyDialog组件，左滑删除，导航集成，i18n
- 2026-02-14: Code review — fixed 1 HIGH + 3 MEDIUM issues:
  - H1: HomeView 左滑删除 catch{} 静默吞错误 → 添加 errorMessage + alert
  - M1: formattedDate 每次创建 DateFormatter → static let
  - M2: FriendlyDialog 无过渡动画 → 添加 transition + withAnimation
  - M3: 编辑模式下图标不跟随分类变化 → 绑定 editCategory

### File List
- ios/ColorFuLedger/ui/detail/TransactionDetailView.swift (new)
- ios/ColorFuLedger/ui/detail/TransactionDetailViewModel.swift (new)
- ios/ColorFuLedger/ui/components/FriendlyDialog.swift (new)
- ios/ColorFuLedger/data/model/Transaction.swift (modified — added Hashable, currentISO())
- ios/ColorFuLedger/ui/home/HomeView.swift (modified — List + NavigationLink + swipeActions + FriendlyDialog)
- ios/ColorFuLedger/ContentView.swift (modified — pass repositories to HomeView)
- ios/ColorFuLedger/i18n/Localizable.strings (modified — 20+ new strings)
- ios/ColorFuLedger/i18n/en.lproj/Localizable.strings (modified — 20+ new strings)
