---
stepsCompleted: [1, 2, 3, 4]
status: 'complete'
inputDocuments: ['prd.md', 'architecture.md', 'ux-design-specification.md']
---

# ColorFuLedger - Epic Breakdown

## Overview

This document provides the complete epic and story breakdown for ColorFuLedger, decomposing the requirements from the PRD, UX Design, and Architecture into implementable stories.

## Requirements Inventory

### Functional Requirements

- FR1: 用户可以快速创建一笔收入或支出记录（金额 + 分类）
- FR2: 用户可以选择预设的收支分类来归类每笔记录
- FR3: 系统可以根据用户使用频率自动排序分类列表
- FR4: 用户可以编辑已有的记账记录
- FR5: 用户可以删除已有的记账记录（需二次确认）
- FR6: 用户可以为每笔记录添加备注信息
- FR7: 系统提供一套默认的收支分类
- FR8: 用户可以自定义分类（新增、编辑、删除）
- FR9: 用户可以分别管理收入分类和支出分类
- FR10: 用户可以创建自定义标签
- FR11: 用户可以为每笔记录打上一个或多个标签
- FR12: 用户可以按标签筛选和查看记录
- FR13: 用户可以按标签汇总查看收支统计
- FR14: 用户可以查看月度收支饼图（按分类占比）
- FR15: 用户可以查看收支趋势折线图（按月度变化）
- FR16: 用户可以查看标签分组柱状图
- FR17: 用户可以选择报表的时间范围
- FR18: 用户可以按关键词搜索历史记账记录
- FR19: 用户可以按时间范围筛选记录
- FR20: 用户可以按分类筛选记录
- FR21: 用户可以将全部数据导出为备份文件到系统文件管理
- FR22: 用户可以从备份文件导入恢复全部数据
- FR23: 系统可以校验备份文件的完整性
- FR24: 系统可以在用户记账达到一定数量后提醒首次备份
- FR25: 系统可以定期提醒用户进行备份（频率可调整或关闭）
- FR26: 用户可以在恢复失败时获得明确的错误提示和引导
- FR27: 用户可以将记账数据导出为 CSV 文件
- FR28: 用户可以自定义 CSV 导出的内容和字段顺序
- FR29: 用户可以设置 App 密码锁
- FR30: 用户打开 App 时需输入密码才能访问
- FR31: 用户可以修改或关闭 App 密码
- FR32: 所有数据完全存储在用户本地设备上，不进行任何网络传输
- FR33: 首次打开 App 时展示新手引导流程
- FR34: 用户可以跳过新手引导
- FR35: 用户可以在设置中重新触发新手引导
- FR36: 用户可以在设置中关闭新手引导
- FR37: 用户可以在中文和英文之间切换 App 语言
- FR38: 系统根据用户地区设置自动适配数字、日期和货币符号格式
- FR39: App 提供一套默认精品主题
- FR40: 系统预留主题切换架构，支持后续扩展更多主题
- FR41: 用户可以设置主货币
- FR42: 用户可以管理备份提醒频率
- FR43: 用户可以管理 App 密码设置
- FR44: 用户可以管理新手引导开关
- FR45: 用户可以切换 App 语言

### NonFunctional Requirements

- NFR-P1: App 冷启动 < 2 秒
- NFR-P2: 记账操作完成 < 3 秒
- NFR-P3: 报表加载 < 1 秒
- NFR-P4: 搜索响应 < 0.5 秒
- NFR-P5: 10 万条记录无卡顿
- NFR-P6: 备份文件 10 万条记录 < 50MB
- NFR-P7: 备份/恢复速度 10 万条记录 < 30 秒
- NFR-S1: App 不包含任何网络请求代码
- NFR-S2: App 密码锁在 App 进入后台后重新激活
- NFR-S3: 本地数据依赖 OS 级沙箱保护
- NFR-S4: 备份文件不包含 App 密码信息
- NFR-S5: 金额存储使用整数最小单位（分）
- NFR-A1: 遵循各平台基础无障碍标准（VoiceOver / TalkBack）
- NFR-A2: 界面元素提供语义化标签
- NFR-A3: 文字大小支持系统级动态字体调整
- NFR-A4: 交互按钮最小点击区域 44x44pt / 48x48dp
- NFR-R1: 数据写入采用事务机制，确保零数据丢失
- NFR-R2: App 异常退出后重新打开，数据保持完整
- NFR-R3: 备份恢复后数据 100% 完整还原
- NFR-R4: 设备存储空间不足时给出明确提示

### Additional Requirements

**来自架构文档：**
- Monorepo 初始化：单仓库 (ios/ + android/ + shared/)，需作为 Epic 1 Story 1
- iOS: Swift + SwiftUI + GRDB.swift + Swift Charts, @Observable (iOS 17+)
- Android: Kotlin + Jetpack Compose + Room + Vico
- MVVM + Repository 双端对称架构
- 6 表数据库 schema (transactions, categories, tags, transaction_tags, settings, schema_version)
- Design Tokens JSON → 双端主题常量生成
- Ant Design SVG 图标 → 各端原生格式转换
- 备份格式 JSON + SHA-256 校验
- 密码 Keychain/KeyStore SHA-256+salt
- 10 条强制实现规则

**来自 UX 文档：**
- 11 个自定义 UI 组件 (AmountKeypad, CategoryGrid, SummaryCard, TransactionCard, TransactionDetail, FloatingAddButton, PieChart, TrendLineChart, TagSelector, OnboardingOverlay, FriendlyDialog)
- 珊瑚橙渐变主题 + 小红书式视觉
- 底部 Tab 导航 + 中央"+"浮动按钮
- 记账界面：数字键盘 + 分类网格 + 选分类即保存
- 温暖友好的提示语气
- 动效系统（300ms 上限，尊重减少动效设置）
- WCAG AA 无障碍合规

### FR Coverage Map

| FR | Epic | 说明 |
|----|------|------|
| FR1 | Epic 1 | 快速创建收支记录 |
| FR2 | Epic 1 | 选择预设分类 |
| FR3 | Epic 1 | 使用频率自动排序 |
| FR4 | Epic 1 | 编辑记录 |
| FR5 | Epic 1 | 删除记录（二次确认） |
| FR6 | Epic 1 | 添加备注 |
| FR7 | Epic 1 | 默认收支分类 |
| FR8 | Epic 2 | 自定义分类 |
| FR9 | Epic 2 | 分别管理收入/支出分类 |
| FR10 | Epic 2 | 创建自定义标签 |
| FR11 | Epic 2 | 为记录打标签 |
| FR12 | Epic 2 | 按标签筛选记录 |
| FR13 | Epic 2 | 按标签汇总统计 |
| FR14 | Epic 3 | 月度收支饼图 |
| FR15 | Epic 3 | 收支趋势折线图 |
| FR16 | Epic 3 | 标签分组柱状图 |
| FR17 | Epic 3 | 选择报表时间范围 |
| FR18 | Epic 3 | 关键词搜索 |
| FR19 | Epic 3 | 时间范围筛选 |
| FR20 | Epic 3 | 分类筛选 |
| FR21 | Epic 4 | 导出备份文件 |
| FR22 | Epic 4 | 导入恢复数据 |
| FR23 | Epic 4 | 备份完整性校验 |
| FR24 | Epic 4 | 首次备份提醒 |
| FR25 | Epic 4 | 定期备份提醒 |
| FR26 | Epic 4 | 恢复失败引导 |
| FR27 | Epic 4 | CSV 导出 |
| FR28 | Epic 4 | 自定义 CSV 字段 |
| FR29 | Epic 5 | 设置密码锁 |
| FR30 | Epic 5 | 打开 App 需密码 |
| FR31 | Epic 5 | 修改/关闭密码 |
| FR32 | Epic 1 | 数据完全本地存储 |
| FR33 | Epic 6 | 首次新手引导 |
| FR34 | Epic 6 | 跳过引导 |
| FR35 | Epic 6 | 重新触发引导 |
| FR36 | Epic 6 | 关闭引导 |
| FR37 | Epic 6 | 中英语言切换 |
| FR38 | Epic 1 | Locale 格式适配 |
| FR39 | Epic 1 | 默认精品主题 |
| FR40 | Epic 1 | 主题切换架构预留 |
| FR41 | Epic 1 | 设置主货币 |
| FR42 | Epic 6 | 管理备份提醒频率 |
| FR43 | Epic 6 | 管理密码设置 |
| FR44 | Epic 6 | 管理引导开关 |
| FR45 | Epic 6 | 切换语言 |

## Epic List

### Epic 1: 极速记账（Core Recording Experience）
用户可以快速记录收支、查看流水列表、编辑和删除记录。包含项目初始化、数据库搭建、主题系统、国际化框架、首页和记账界面。
**FRs covered:** FR1, FR2, FR3, FR4, FR5, FR6, FR7, FR32, FR38, FR39, FR40, FR41

### Epic 2: 智能分类与标签（Smart Organization）
用户可以自定义分类、创建标签、按标签筛选和汇总，让记账更有条理。
**FRs covered:** FR8, FR9, FR10, FR11, FR12, FR13

### Epic 3: 数据洞察（Data Insights & Reports）
用户可以通过饼图、折线图、柱状图了解消费结构，搜索和筛选历史记录。
**FRs covered:** FR14, FR15, FR16, FR17, FR18, FR19, FR20

### Epic 4: 数据保护（Backup & Export）
用户可以备份和恢复数据、导出 CSV，确保数据不丢失。
**FRs covered:** FR21, FR22, FR23, FR24, FR25, FR26, FR27, FR28

### Epic 5: 安全与隐私（Security & Privacy）
用户可以设置 App 密码锁，保护财务数据隐私。
**FRs covered:** FR29, FR30, FR31

### Epic 6: 新手引导与设置（Onboarding & Settings）
新用户可以通过引导快速上手，所有偏好设置集中管理。
**FRs covered:** FR33, FR34, FR35, FR36, FR37, FR42, FR43, FR44, FR45

## Epic 1: 极速记账（Core Recording Experience）

用户可以快速记录收支、查看流水列表、编辑和删除记录。包含项目初始化、数据库搭建、主题系统、国际化框架、首页和记账界面。

### Story 1.1: 项目初始化与主题基础

As a **developer**,
I want **to set up the monorepo, platform projects, Design Tokens, and i18n framework**,
So that **all subsequent development has a consistent foundation**.

**Acceptance Criteria:**

**Given** a new development environment
**When** the monorepo is initialized
**Then** the structure contains ios/, android/, shared/ directories
**And** shared/tokens/ contains colors.json, spacing.json, radius.json, typography.json, animation.json
**And** shared/icons/ contains all Ant Design SVG icons for categories and navigation
**And** shared/default-data/ contains categories-expense.json and categories-income.json

**Given** the iOS project is created
**When** dependencies are configured
**Then** GRDB.swift and Swift Charts are added via SPM
**And** AppColors, AppSpacing, AppRadius, AppTypography are generated from Design Tokens
**And** i18n strings files for zh-Hans and en are initialized
**And** the app launches with a Tab navigation shell (4 tabs + center FAB placeholder)

**Given** the Android project is created
**When** dependencies are configured
**Then** Room, Vico are added via Gradle
**And** AppColors, AppSpacing, AppRadius, AppTypography, ColorFuLedgerTheme are generated from Design Tokens
**And** strings.xml for zh and en are initialized
**And** the app launches with matching Tab navigation shell

### Story 1.2: 记录一笔交易

As a **user**,
I want **to quickly record an income or expense transaction**,
So that **I can track my spending in under 3 seconds**.

**Acceptance Criteria:**

**Given** the database does not yet exist
**When** the app launches for the first time
**Then** tables transactions, categories, settings, schema_version are created
**And** default expense and income categories are seeded from shared/default-data/ (FR7)
**And** default currency is set based on system Locale (FR41)

**Given** I am on the home page
**When** I tap the "+" FloatingAddButton
**Then** the record page slides in from the bottom with AmountKeypad and CategoryGrid visible

**Given** I am on the record page
**When** I enter an amount using the AmountKeypad
**Then** the amount displays in real-time in the display area with currency symbol (FR38)
**And** I can use backspace to correct input

**Given** I have entered an amount
**When** I tap a category icon in the CategoryGrid
**Then** the category highlights with ✓ animation
**And** the transaction is saved automatically (FR1, FR2)
**And** the record page slides out and returns to home

**Given** categories have been used multiple times
**When** I open the record page
**Then** categories are sorted by usage_count descending (FR3)

**Given** I am on the record page with an amount entered
**When** I tap the note area
**Then** a text input expands for optional note entry (FR6)

**Given** I am on the record page
**When** I tap the income/expense toggle
**Then** the view switches between expense and income categories

### Story 1.3: 首页流水列表

As a **user**,
I want **to see my transaction history and monthly summary on the home page**,
So that **I know my financial status at a glance**.

**Acceptance Criteria:**

**Given** I have recorded transactions
**When** I open the app (home page)
**Then** a SummaryCard shows current month's total expense, income, and balance
**And** the SummaryCard uses coral-orange gradient background with white text

**Given** I have transactions for today
**When** I view the home page
**Then** transactions are listed as TransactionCards grouped by date
**And** each card shows category icon, category name, note, amount, and time
**And** expense amounts show in coral-orange, income in mint-green
**And** amounts are formatted with currency symbol per Locale (FR38)

**Given** I have no transactions yet
**When** I view the home page
**Then** an empty state with friendly illustration and guidance is shown

### Story 1.4: 记录详情、编辑与删除

As a **user**,
I want **to view, edit, and delete my transaction records**,
So that **I can correct mistakes and manage my data**.

**Acceptance Criteria:**

**Given** I am on the home page
**When** I tap a TransactionCard
**Then** a full-screen TransactionDetail page opens showing category icon (large), amount (Display size), category name, note, date/time

**Given** I am on the TransactionDetail page
**When** I tap the "Edit" button (navigation bar right)
**Then** I enter edit mode where I can modify amount, category, note
**And** I can save changes or cancel

**Given** I have edited a transaction
**When** I tap "Save"
**Then** the transaction updates in the database
**And** the home page list reflects the changes

**Given** I am on the TransactionDetail page
**When** I tap the "Delete" button
**Then** a FriendlyDialog appears: "确定删除这条记录吗？删除后无法恢复哦" (FR5)
**And** I can confirm or cancel

**Given** I confirm deletion
**When** the dialog closes
**Then** the record is permanently deleted
**And** I return to the home page with the record removed

**Given** I am on a TransactionCard in the home list
**When** I swipe left
**Then** a red delete button appears

**Given** the app theme
**When** any UI is rendered
**Then** the coral-orange gradient theme is applied consistently (FR39)
**And** theme tokens are used for all colors, spacing, and radius (FR40)

## Epic 2: 智能分类与标签（Smart Organization）

用户可以自定义分类、创建标签、按标签筛选和汇总，让记账更有条理。

### Story 2.1: 自定义分类管理

As a **user**,
I want **to create, edit, and delete my own categories**,
So that **my categories match my actual spending habits**.

**Acceptance Criteria:**

**Given** I open category management (from settings or long-press CategoryGrid)
**When** I view the category list
**Then** I see expense categories and income categories in separate tabs (FR9)
**And** default categories are marked as non-custom
**And** custom categories are distinguishable

**Given** I tap "Add Category"
**When** I provide a name, select an icon, and choose a color
**Then** a new custom category is created (FR8)
**And** it appears in the CategoryGrid on the record page

**Given** I select an existing custom category
**When** I choose to edit it
**Then** I can modify name, icon, and color
**And** existing transactions with this category are unaffected

**Given** I select an existing custom category
**When** I choose to delete it
**Then** a FriendlyDialog confirms the deletion
**And** the category is deactivated (is_active = 0), preserving historical records

### Story 2.2: 标签创建与关联

As a **user**,
I want **to create tags and assign them to transactions**,
So that **I can organize records by project or occasion**.

**Acceptance Criteria:**

**Given** the tags and transaction_tags tables do not exist
**When** this feature is first used
**Then** both tables are created in the database

**Given** I am recording or editing a transaction
**When** I tap the tag button on the AmountKeypad
**Then** a TagSelector bottom sheet appears showing existing tags as capsule buttons (FR10)

**Given** I am in the TagSelector
**When** I tap "+" to create a new tag
**Then** I can enter a tag name and select a color
**And** the new tag is created and immediately selectable

**Given** I have tags available
**When** I tap on tag capsules
**Then** I can select multiple tags (fill color + white text when selected) (FR11)
**And** selected tags are saved with the transaction

### Story 2.3: 标签筛选与统计

As a **user**,
I want **to filter transactions by tag and see tag-level statistics**,
So that **I can track spending for specific trips or projects**.

**Acceptance Criteria:**

**Given** I open the Tags tab in bottom navigation
**When** I view the tags list
**Then** I see all my tags with transaction count per tag

**Given** I tap on a specific tag
**When** the tag detail page opens
**Then** I see all transactions with that tag, sorted by date (FR12)
**And** the top shows total amount for that tag

**Given** I am viewing a tag's transactions
**When** I look at the summary
**Then** I see total expense and income for that tag (FR13)

## Epic 3: 数据洞察（Data Insights & Reports）

用户可以通过饼图、折线图、柱状图了解消费结构，搜索和筛选历史记录。

### Story 3.1: 月度饼图报表

As a **user**,
I want **to see a pie chart of my spending by category**,
So that **I understand where my money goes**.

**Acceptance Criteria:**

**Given** I tap the "Report" tab in bottom navigation
**When** the report page loads
**Then** I see a monthly summary card (total income/expense/balance)
**And** a donut PieChart showing expense breakdown by category (FR14)
**And** the chart uses category colors (darkened versions)
**And** center shows total expense amount

**Given** I am viewing the pie chart
**When** I tap a chart sector
**Then** the sector highlights and shows category name, amount, and percentage

**Given** I am on the report page
**When** I tap left/right arrows next to the month label
**Then** the report switches to the previous/next month (FR17)
**And** all charts update accordingly

### Story 3.2: 趋势折线图

As a **user**,
I want **to see a trend line chart of my income and expenses**,
So that **I can track my financial progress over time**.

**Acceptance Criteria:**

**Given** I scroll down on the report page
**When** the trend section is visible
**Then** a TrendLineChart shows the last 6 months of expense (coral-orange) and income (mint-green) (FR15)
**And** data points are shown as circles on the line

**Given** I am viewing the trend chart
**When** I long-press on a data point
**Then** a tooltip shows the exact amount for that month

### Story 3.3: 标签柱状图

As a **user**,
I want **to see a bar chart comparing spending across tags**,
So that **I can compare costs between projects or trips**.

**Acceptance Criteria:**

**Given** I scroll further on the report page
**When** the tag chart section is visible
**Then** a horizontal bar chart shows spending totals grouped by tag (FR16)
**And** bars use tag colors

### Story 3.4: 搜索与筛选

As a **user**,
I want **to search and filter my transaction history**,
So that **I can quickly find any past record**.

**Acceptance Criteria:**

**Given** I am on the home page
**When** I tap the search icon
**Then** a search bar appears at the top with keyboard focus

**Given** I type a keyword in the search bar
**When** results are found
**Then** matching transactions are displayed (searching note and category name) (FR18)
**And** results appear within 0.5 seconds (NFR-P4)

**Given** I want to filter by date
**When** I select a date range filter
**Then** only transactions within that range are shown (FR19)

**Given** I want to filter by category
**When** I select a category filter
**Then** only transactions with that category are shown (FR20)

## Epic 4: 数据保护（Backup & Export）

用户可以备份和恢复数据、导出 CSV，确保数据不丢失。

### Story 4.1: 备份导出

As a **user**,
I want **to export my data as a backup file**,
So that **I can protect my data from device loss**.

**Acceptance Criteria:**

**Given** I go to Settings → Backup & Restore
**When** I tap "Export Backup"
**Then** the system file picker opens to choose a save location (FR21)

**Given** I select a location
**When** the export begins
**Then** a progress indicator shows export progress
**And** the backup JSON file is generated with all data + SHA-256 checksum
**And** the backup file does NOT contain password hash (NFR-S4)

**Given** the export completes
**When** I see the result
**Then** a FriendlyDialog shows: "备份完成！共 X 条记录，文件已保存到你选择的位置"

### Story 4.2: 备份导入与恢复

As a **user**,
I want **to restore my data from a backup file**,
So that **I can recover my data on a new device**.

**Acceptance Criteria:**

**Given** I go to Settings → Backup & Restore
**When** I tap "Import Restore"
**Then** a FriendlyDialog warns: "导入备份会覆盖现有数据哦，确定继续吗？"

**Given** I confirm import
**When** I select a backup file from the file picker
**Then** the system validates the file checksum (FR23)

**Given** the checksum is valid
**When** import begins
**Then** all data is restored completely (FR22)
**And** a success message shows: "恢复成功！共找回 X 条记录，一条不少 ✓"

**Given** the checksum fails or file is invalid
**When** validation completes
**Then** a FriendlyDialog shows: "这个文件好像不是 ColorFuLedger 的备份文件，请重新选择" (FR26)

### Story 4.3: 备份提醒

As a **user**,
I want **to be reminded to backup my data**,
So that **I don't forget and risk losing everything**.

**Acceptance Criteria:**

**Given** I have recorded 50+ transactions and never backed up
**When** the threshold is reached
**Then** a local notification reminds: "你已经记了 50 笔账啦！建议备份一下，以防万一" (FR24)

**Given** I have backed up before
**When** one month has passed since last backup
**Then** a periodic local notification reminds me to backup (FR25)

### Story 4.4: CSV 导出

As a **user**,
I want **to export my data as a CSV file**,
So that **I can share it with others or analyze in a spreadsheet**.

**Acceptance Criteria:**

**Given** I am viewing a tag's transactions or all transactions
**When** I tap the "Export" button
**Then** an export settings panel opens (FR28)

**Given** I am in the export settings
**When** I select fields and their order
**Then** I can choose which columns to include (date, amount, category, note, tags)

**Given** I confirm export
**When** the CSV is generated (FR27)
**Then** the system share sheet opens (email, messaging, file save)

## Epic 5: 安全与隐私（Security & Privacy）

用户可以设置 App 密码锁，保护财务数据隐私。

### Story 5.1: 设置 App 密码

As a **user**,
I want **to set up a password lock for the app**,
So that **others cannot access my financial data**.

**Acceptance Criteria:**

**Given** I go to Settings → Password Lock
**When** I toggle password lock on
**Then** I am prompted to enter a new numeric password twice

**Given** I enter and confirm a password
**When** the passwords match
**Then** the password hash (SHA-256 + salt) is stored in Keychain/KeyStore (FR29)
**And** a success message confirms password is set

**Given** the passwords don't match
**When** I see the error
**Then** I am prompted to try again with a friendly message

### Story 5.2: 密码锁定与解锁

As a **user**,
I want **the app to lock when I leave and require my password to re-enter**,
So that **my data stays private even if someone picks up my phone**.

**Acceptance Criteria:**

**Given** a password is set and I open the app
**When** the app launches or returns from background
**Then** a LockScreen appears requiring password entry (FR30)

**Given** I enter the correct password
**When** I tap confirm
**Then** the LockScreen dismisses and I access the app

**Given** I enter an incorrect password
**When** I tap confirm
**Then** a friendly error message appears and I can retry

**Given** I want to change my password
**When** I go to Settings → Password Lock → Change Password
**Then** I enter current password, then new password twice (FR31)

**Given** I want to disable the password
**When** I go to Settings → Password Lock and toggle off
**Then** I enter current password to confirm, then password lock is removed (FR31)

## Epic 6: 新手引导与设置（Onboarding & Settings）

新用户可以通过引导快速上手，所有偏好设置集中管理。

### Story 6.1: 新手引导流程

As a **new user**,
I want **to be guided through the app's core features on first launch**,
So that **I can start recording transactions confidently**.

**Acceptance Criteria:**

**Given** I open the app for the first time
**When** the app launches
**Then** an onboarding flow starts with 3 steps:
**And** Step 1: "3 秒记一笔" introduction with Ant Design icon animation (FR33)
**And** Step 2: Currency selection (default from system Locale)
**And** Step 3: Guided first transaction with OnboardingOverlay highlighting the "+" button

**Given** I am in the onboarding flow
**When** I tap "跳过引导" at the bottom
**Then** the onboarding is skipped and I go directly to the home page (FR34)

**Given** I complete or skip the onboarding
**When** I reopen the app
**Then** the onboarding does not appear again

### Story 6.2: 设置页面

As a **user**,
I want **a centralized settings page to manage all my preferences**,
So that **I can customize the app to my needs**.

**Acceptance Criteria:**

**Given** I tap the "Settings" tab in bottom navigation
**When** the settings page loads
**Then** I see iOS-style grouped settings list with sections:
**And** "General" section: Currency, Language (FR45)
**And** "Security" section: Password Lock (FR43)
**And** "Data" section: Backup & Restore, Export (FR42)
**And** "About" section: Onboarding (FR44), Version

**Given** I tap "Language"
**When** the language picker appears
**Then** I can switch between 中文 and English (FR37)
**And** the app UI updates immediately

**Given** I tap "Onboarding"
**When** I see the option
**Then** I can re-trigger the onboarding flow (FR35)
**And** I can toggle onboarding on/off (FR36)

**Given** I tap "Backup Reminder"
**When** I see frequency options
**Then** I can set monthly/weekly/off for backup reminders (FR42)
