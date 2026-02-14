---
stepsCompleted: [1, 2, 3, 4, 5, 6, 7, 8]
lastStep: 8
status: 'complete'
completedAt: '2026-02-14'
inputDocuments: ['prd.md', 'product-brief-FreeLedger-2026-02-13.md', 'ux-design-specification.md']
workflowType: 'architecture'
project_name: 'FreeLedger'
user_name: 'Wangyang'
date: '2026-02-14'
---

# Architecture Decision Document

_This document builds collaboratively through step-by-step discovery. Sections are appended as we work through each architectural decision together._

## Project Context Analysis

### Requirements Overview

**Functional Requirements:**

45 个 FR，分布在 10 个功能域：

| 功能域 | FR 范围 | 架构影响 |
|--------|---------|---------|
| 记账核心 | FR1-FR6 | 数据模型核心、键盘/分类 UI 组件 |
| 分类管理 | FR7-FR9 | 分类 CRUD + 智能排序算法 |
| 标签与分组 | FR10-FR13 | 多对多关系模型、筛选查询 |
| 数据可视化 | FR14-FR17 | 图表库选型、数据聚合查询 |
| 搜索与筛选 | FR18-FR20 | SQLite 全文搜索或 LIKE 查询优化 |
| 备份与恢复 | FR21-FR26 | 文件格式设计、完整性校验、系统文件 API |
| 数据导出 | FR27-FR28 | CSV 生成、字段映射、系统分享 |
| 安全与隐私 | FR29-FR32 | App 密码锁、零网络架构 |
| 新手引导 | FR33-FR36 | 引导状态管理、遮罩 UI 组件 |
| 多语言/本地化/主题/设置 | FR37-FR45 | i18n 框架、Locale API、Design Tokens、用户偏好持久化 |

**Non-Functional Requirements:**

| NFR | 要求 | 架构影响 |
|-----|------|---------|
| 冷启动 < 2s | 启动路径优化 | 轻量初始化、延迟加载 |
| 记账 < 3s | 核心路径极致优化 | 预加载分类、键盘即时就绪 |
| 10 万条不卡顿 | SQLite 索引策略 | 分页查询、索引设计 |
| 零网络 | 完全离线 | 无任何网络层代码 |
| 零数据丢失 | 事务写入 | SQLite WAL 模式、事务保障 |
| 金额零误差 | 整数最小单位（分） | 数据模型用 Int64 存储 |

**UX Design Architectural Implications:**

| UX 决策 | 架构影响 |
|---------|---------|
| 11 个自定义组件 | 需要自定义 UI 组件库 |
| Ant Design SVG 图标 | 双端共享 SVG 资源管理 |
| Design Tokens 系统 | 跨平台主题变量抽象层 |
| 智能分类排序 | 使用频率统计 + 排序算法 |
| 动效系统（300ms 上限） | 原生动画 API、减少动效适配 |
| WCAG AA 合规 | 无障碍标签、动态字体、对比度 |

**Scale & Complexity:**

- Primary domain: 移动原生（双平台）
- Complexity level: 中等
- Estimated architectural components: ~8-10 个核心模块
- 实时特性: 无
- 多租户: 无
- 合规要求: 低（App Store/Play Store 隐私政策）
- 集成复杂度: 极低（无外部 API）

### Technical Constraints & Dependencies

| 约束 | 来源 | 影响 |
|------|------|------|
| 双平台原生 | PRD 决策 | iOS Swift + Android Kotlin，两套代码 |
| SQLite 唯一数据库 | PRD 决策 | 需手写或轻量封装 |
| 零网络依赖 | 核心架构原则 | 不引入任何带网络能力的库 |
| iOS 16+ / Android 10+ | PRD 决策 | 可使用较新 API（SwiftUI、Jetpack Compose） |
| 单一货币 | PRD 范围决策 | 简化数据模型，无汇率逻辑 |
| 不加密 | PRD 安全决策 | 备份文件明文、依赖 OS 沙箱 |

### Cross-Cutting Concerns Identified

| 关注点 | 影响范围 | 说明 |
|--------|---------|------|
| 数据持久化 | 全模块 | SQLite 统一数据层，事务写入 |
| i18n 国际化 | 全 UI | 中英双语字符串、Locale 格式化 |
| Design Tokens | 全 UI | 统一配色/间距/圆角/字号变量 |
| 无障碍 | 全 UI | VoiceOver/TalkBack 标签、动态字体 |
| App 密码锁 | 全局 | App 生命周期管理、前后台切换拦截 |
| 错误处理 | 全模块 | 温暖友好语气的统一错误处理 |
| 备份兼容性 | 数据层 | 备份格式需考虑版本升级兼容 |

## Starter Template Evaluation

### Primary Technology Domain

双平台原生移动应用。PRD 已明确：iOS (Swift/SwiftUI) + Android (Kotlin/Jetpack Compose) + SQLite。无需评估跨平台框架，双端原生是核心设计决策。

### iOS Platform Stack

| 领域 | 选型 | 理由 |
|------|------|------|
| **UI 框架** | SwiftUI (iOS 16+) | 声明式 UI，与 Design Tokens 系统契合，原生无障碍支持 |
| **SQLite 封装** | GRDB.swift | WAL 模式（零数据丢失）、数据库迁移（备份兼容性）、Combine 响应式查询、FTS5 全文搜索（FR18）、事务支持（NFR-R1） |
| **图表库** | Swift Charts (Apple 原生) | iOS 16+ 可用、零第三方依赖、原生 SwiftUI 集成、支持饼图/折线图/柱状图 |
| **架构模式** | MVVM + Repository | SwiftUI 天然适配、数据层与 UI 层清晰分离 |
| **依赖管理** | Swift Package Manager | Apple 原生方案 |
| **i18n** | NSLocalizedString + .strings | 平台原生方案 |

### Android Platform Stack

| 领域 | 选型 | 理由 |
|------|------|------|
| **UI 框架** | Jetpack Compose | 声明式 UI，与 iOS SwiftUI 对应，现代 Android 标准 |
| **SQLite 封装** | Room (Jetpack 官方) | 编译期 SQL 校验、内置迁移支持、Kotlin Flow 响应式查询、Google 官方维护 |
| **图表库** | Vico | Compose 原生支持、Material Design 3 兼容、活跃维护 |
| **架构模式** | MVVM + Repository | 与 iOS 端保持架构对称、Jetpack ViewModel + Flow |
| **依赖管理** | Gradle (Kotlin DSL) | Android 标准 |
| **i18n** | strings.xml + Locale | 平台原生方案 |

### Shared Resources

| 资源 | 格式 | 管理方式 |
|------|------|----------|
| Ant Design SVG 图标 | SVG → 各端原生格式 | iOS: Asset Catalog (PDF/SVG), Android: Vector Drawable |
| Design Tokens | JSON 定义文件 | 各端编译为原生常量（Swift enum / Kotlin object） |
| 备份文件格式 | JSON | 统一 schema，双端可互相恢复 |

### Initialization Commands

**iOS:**
```
Xcode → New Project → App → SwiftUI → Swift
添加 GRDB.swift (SPM)
```

**Android:**
```
Android Studio → New Project → Empty Compose Activity → Kotlin
添加 Room + Vico (Gradle)
```

### Selection Rationale

1. **GRDB.swift > SQLite.swift** — GRDB 提供 WAL 模式、FTS5 全文搜索、数据库迁移、响应式查询，完整覆盖 NFR 需求
2. **Room > SQLDelight** — Google 官方方案，与 Jetpack 生态深度集成，编译期校验，文档最全
3. **Swift Charts > DGCharts** — 零第三方依赖、原生 SwiftUI 集成、iOS 16+ 即可使用
4. **Vico > MPAndroidChart** — Compose 原生支持（MPAndroidChart 是 View-based）
5. **MVVM + Repository 双端对称** — 降低认知成本，架构文档可双端复用

**Note:** 项目初始化应作为第一个实现 Story。

## Core Architectural Decisions

### Decision Priority Analysis

**Critical Decisions (Block Implementation):**

| # | 决策 | 方案 | 状态 |
|---|------|------|------|
| 1 | 数据库表结构 | 6 表设计（见下方） | ✅ 已决 |
| 2 | 金额存储 | Int64（分） | ✅ 已决 |
| 3 | 备份文件格式 | JSON + SHA-256 校验 | ✅ 已决 |
| 4 | 密码存储 | Keychain / KeyStore | ✅ 已决 |
| 5 | iOS 状态管理 | @Observable (iOS 17+) | ✅ 已决 |
| 6 | 代码仓库 | 单仓库 monorepo | ✅ 已决 |

**Important Decisions (Shape Architecture):**

| # | 决策 | 方案 | 状态 |
|---|------|------|------|
| 7 | 模块结构 | data/domain/ui 三层，双端对称 | ✅ 已决 |
| 8 | 导航架构 | NavigationStack / Navigation Compose | ✅ 已决 |
| 9 | CI/CD | GitHub Actions + Fastlane | ✅ 已决 |
| 10 | 版本管理 | SemVer，双端同步 | ✅ 已决 |

**Deferred Decisions (Post-MVP):**

| 决策 | 原因 |
|------|------|
| 生物识别解锁 | P2 功能，预留接口即可 |
| 云端同步架构 | P3 功能，待评估 |
| 多账本 | P3 功能 |
| 深色模式 | 主题系统架构已预留，后续扩展 |

### Data Architecture

**数据库表结构（6 表）：**

**transactions — 核心记录表**

| 字段 | 类型 | 说明 |
|------|------|------|
| id | TEXT (UUID) | 主键 |
| amount | INTEGER (Int64) | 金额，单位：分 |
| type | TEXT | "income" / "expense" |
| category_id | TEXT (UUID) | 外键 → categories |
| note | TEXT | 备注（可空） |
| created_at | TEXT (ISO 8601) | 创建时间 |
| updated_at | TEXT (ISO 8601) | 更新时间 |

**categories — 分类表**

| 字段 | 类型 | 说明 |
|------|------|------|
| id | TEXT (UUID) | 主键 |
| name_key | TEXT | i18n key（如 "category_food"） |
| icon_name | TEXT | Ant Design 图标名 |
| color_hex | TEXT | 背景色 |
| type | TEXT | "income" / "expense" |
| sort_order | INTEGER | 手动排序 |
| usage_count | INTEGER | 使用频率（智能排序） |
| is_custom | INTEGER (0/1) | 是否用户自定义 |
| is_active | INTEGER (0/1) | 是否启用 |

**tags — 标签表**

| 字段 | 类型 | 说明 |
|------|------|------|
| id | TEXT (UUID) | 主键 |
| name | TEXT | 标签名称 |
| color_hex | TEXT | 标签颜色 |
| created_at | TEXT (ISO 8601) | 创建时间 |

**transaction_tags — 多对多关联表**

| 字段 | 类型 | 说明 |
|------|------|------|
| transaction_id | TEXT (UUID) | 外键 → transactions |
| tag_id | TEXT (UUID) | 外键 → tags |

**settings — 用户设置 KV 表**

| 字段 | 类型 | 说明 |
|------|------|------|
| key | TEXT | 设置键（如 "currency", "language", "theme"） |
| value | TEXT | 设置值 |

**schema_version — 数据库版本追踪**

| 字段 | 类型 | 说明 |
|------|------|------|
| version | INTEGER | 当前 schema 版本 |
| migrated_at | TEXT (ISO 8601) | 迁移时间 |

**索引策略（支撑 10 万条不卡顿）：**
- `transactions(created_at DESC)` — 流水列表按时间排序
- `transactions(category_id)` — 报表按分类聚合
- `transactions(type, created_at)` — 收入/支出筛选
- `transaction_tags(transaction_id)` + `transaction_tags(tag_id)` — 标签查询
- `categories(type, usage_count DESC)` — 智能分类排序

**迁移策略：** 每个版本升级附带 SQLite ALTER TABLE 脚本，通过 schema_version 表追踪。GRDB.swift 和 Room 均内置迁移支持。

**删除策略：** 硬删除（用户确认后直接 DELETE），纯离线无需回收站复杂度。

### Authentication & Security

| 决策 | 方案 | 理由 |
|------|------|------|
| **密码存储** | iOS Keychain / Android KeyStore，SHA-256 + salt 哈希 | OS 级安全存储，App 卸载后清除 |
| **密码验证** | App 前台时检查，后台→前台重新验证 | NFR-S2，可配置宽限时间 |
| **备份文件** | 不包含密码哈希 | NFR-S4，防止绕过密码 |
| **网络安全** | 无——零网络代码 | 核心架构原则 |
| **未来扩展** | 预留生物识别接口（LocalAuthentication / BiometricPrompt） | P2 |

### Mobile Architecture

**状态管理：**

| 平台 | 方案 | 说明 |
|------|------|------|
| **iOS** | `@Observable` (iOS 17+) | Observation 框架，更简洁的响应式状态 |
| **Android** | ViewModel + StateFlow + Compose State | Jetpack 标准方案 |

**平台最低版本更新：**

| 平台 | 最低版本 | 原因 |
|------|---------|------|
| **iOS** | **17.0+**（原 PRD 为 16+） | 使用 @Observable 需要 iOS 17+ |
| **Android** | 10+ (API 29) | 不变 |

**导航架构：**

| 平台 | 方案 |
|------|------|
| **iOS** | NavigationStack + TabView + .sheet() |
| **Android** | Navigation Compose + NavigationBar + ModalBottomSheet |

**模块/包结构（双端对称）：**

```
app/
├── data/                  # 数据层
│   ├── database/          # SQLite 表定义、DAO、迁移
│   ├── repository/        # Repository 实现
│   └── model/             # 数据模型 (Entity)
├── domain/                # 业务层
│   ├── model/             # 业务模型
│   └── usecase/           # 业务逻辑（可选）
├── ui/                    # 表现层
│   ├── home/              # 首页
│   ├── record/            # 记账界面
│   ├── detail/            # 记录详情页
│   ├── report/            # 报表页
│   ├── tags/              # 标签管理
│   ├── settings/          # 设置页
│   ├── onboarding/        # 新手引导
│   └── components/        # 共享自定义组件
├── theme/                 # Design Tokens + 主题
├── i18n/                  # 国际化资源
├── util/                  # 工具类
└── backup/                # 备份导出/导入逻辑
```

### Backup File Format

```json
{
  "app": "FreeLedger",
  "schema_version": 1,
  "exported_at": "2026-02-14T12:00:00Z",
  "currency": "CNY",
  "data": {
    "transactions": [],
    "categories": [],
    "tags": [],
    "transaction_tags": [],
    "settings": []
  },
  "checksum": "sha256:abc123..."
}
```

- `checksum` 用于完整性校验（FR23）
- `schema_version` 确保跨版本恢复兼容
- 不包含密码信息（NFR-S4）

### Infrastructure & Deployment

| 决策 | 方案 | 理由 |
|------|------|------|
| **代码仓库** | 单仓库 monorepo（iOS + Android 各子目录） | 共享资源集中管理（图标、Design Tokens、备份 schema） |
| **CI/CD** | GitHub Actions | 免费额度足够，双平台构建 |
| **iOS 构建** | Fastlane + Xcode Cloud | 自动化 Archive + TestFlight 分发 |
| **Android 构建** | Gradle + GitHub Actions | 自动化 AAB 构建 + Play Console 上传 |
| **版本管理** | SemVer (major.minor.patch) | 双端保持版本同步 |

**Monorepo 结构：**

```
FreeLedger/
├── ios/                   # iOS Xcode 项目
├── android/               # Android Studio 项目
├── shared/                # 双端共享资源
│   ├── icons/             # Ant Design SVG 图标源文件
│   ├── tokens/            # Design Tokens JSON
│   └── backup-schema/     # 备份文件 JSON Schema
├── docs/                  # 项目文档
├── .github/workflows/     # CI/CD 配置
└── README.md
```

### Decision Impact Analysis

**Implementation Sequence:**
1. Monorepo 初始化 + shared 资源目录
2. Design Tokens JSON 定义 + 双端主题常量生成
3. SQLite 数据库表创建 + 迁移框架
4. Repository 层 + 核心 CRUD
5. UI 组件库（AmountKeypad、CategoryGrid 等）
6. 页面组装 + 导航
7. 备份/导出功能
8. App 密码锁
9. 新手引导

**Cross-Component Dependencies:**
- Design Tokens → 所有 UI 组件（必须先定义）
- Database + Repository → 所有业务功能（必须先实现）
- i18n 资源 → 所有 UI 文本（与 UI 并行开发）
- 备份 schema → 数据库表结构（同步设计）

## Implementation Patterns & Consistency Rules

### Naming Patterns

**数据库命名（双端统一）：**

| 维度 | 规则 | 示例 |
|------|------|------|
| 表名 | snake_case，复数 | `transactions`, `categories`, `transaction_tags` |
| 列名 | snake_case | `category_id`, `created_at`, `usage_count` |
| 索引名 | `idx_{table}_{column}` | `idx_transactions_created_at` |
| 外键 | `{related_table_singular}_id` | `category_id`, `tag_id` |

**代码命名：**

| 维度 | iOS (Swift) | Android (Kotlin) |
|------|------------|------------------|
| 类名 | UpperCamelCase | UpperCamelCase |
| 函数名 | lowerCamelCase | lowerCamelCase |
| 变量名 | lowerCamelCase | lowerCamelCase |
| 常量 | lowerCamelCase (let) | UPPER_SNAKE_CASE (companion) |
| 文件名 | 与类名一致 `TransactionRepository.swift` | 与类名一致 `TransactionRepository.kt` |
| 目录名 | lowercase | lowercase |

**Design Tokens 命名：**

| Token | JSON Key | Swift | Kotlin |
|-------|----------|-------|--------|
| 主色 | `color.primary` | `AppColors.primary` | `AppColors.Primary` |
| 间距 | `spacing.lg` | `AppSpacing.lg` | `AppSpacing.Lg` |
| 圆角 | `radius.md` | `AppRadius.md` | `AppRadius.Md` |

### Structure Patterns

**测试文件位置：** 与源文件同级目录（co-located）

```
# iOS
ui/home/HomeView.swift
ui/home/HomeViewTests.swift

# Android
ui/home/HomeScreen.kt
ui/home/HomeScreenTest.kt
```

**Repository 接口模式（双端对称）：**

```swift
// iOS
protocol TransactionRepository {
    func getAll() -> [Transaction]
    func getById(_ id: UUID) -> Transaction?
    func insert(_ transaction: Transaction) throws
    func update(_ transaction: Transaction) throws
    func delete(_ id: UUID) throws
    func search(keyword: String) -> [Transaction]
    func getByDateRange(from: Date, to: Date) -> [Transaction]
    func getByCategory(_ categoryId: UUID) -> [Transaction]
}
```

```kotlin
// Android
interface TransactionRepository {
    fun getAll(): Flow<List<Transaction>>
    fun getById(id: UUID): Flow<Transaction?>
    suspend fun insert(transaction: Transaction)
    suspend fun update(transaction: Transaction)
    suspend fun delete(id: UUID)
    fun search(keyword: String): Flow<List<Transaction>>
    fun getByDateRange(from: LocalDate, to: LocalDate): Flow<List<Transaction>>
    fun getByCategory(categoryId: UUID): Flow<List<Transaction>>
}
```

### Format Patterns

| 维度 | 规则 | 示例 |
|------|------|------|
| 日期存储 | ISO 8601 字符串 | `"2026-02-14T12:30:00Z"` |
| 日期显示 | 根据 Locale 格式化 | CN: "2026年2月14日" / EN: "Feb 14, 2026" |
| 金额存储 | Int64（分） | `2500` = ¥25.00 |
| 金额显示 | amount / 100 + NumberFormatter | `"¥25.00"` / `"$25.00"` |
| UUID | 标准 UUID v4 字符串 | `"550e8400-e29b-41d4-a716-446655440000"` |
| 布尔值 | SQLite: INTEGER 0/1 | `is_custom = 1` |
| JSON 字段 | snake_case（与数据库一致） | `"schema_version": 1` |
| Null 处理 | 可空字段用 Optional/nullable | Swift `String?` / Kotlin `String?` |

### Error Handling Patterns

**错误类型枚举（双端对称）：**

```swift
// iOS
enum AppError: Error {
    case databaseError(String)
    case backupExportFailed(String)
    case backupImportFailed(String)
    case backupChecksumMismatch
    case invalidInput(String)
    case storageInsufficient
}
```

```kotlin
// Android
sealed class AppError : Exception() {
    data class DatabaseError(override val message: String) : AppError()
    data class BackupExportFailed(override val message: String) : AppError()
    data class BackupImportFailed(override val message: String) : AppError()
    object BackupChecksumMismatch : AppError()
    data class InvalidInput(override val message: String) : AppError()
    object StorageInsufficient : AppError()
}
```

**用户提示语气规则（温暖友好）：**

| 场景 | ✅ 正确 | ❌ 错误 |
|------|---------|----------|
| 删除确认 | "确定删除这条记录吗？删除后无法恢复哦" | "警告：此操作不可撤销" |
| 备份成功 | "备份完成！共 2,156 条记录，一条不少" | "导出成功" |
| 文件校验失败 | "这个文件好像不是 FreeLedger 的备份文件，请重新选择" | "错误：文件格式不正确" |
| 存储不足 | "存储空间不太够了，建议清理后再试" | "Error: Insufficient storage" |

### State Management Patterns

**加载状态（双端统一）：**

```swift
// iOS
enum LoadingState<T> {
    case idle
    case loading
    case loaded(T)
    case error(AppError)
}
```

```kotlin
// Android
sealed class LoadingState<out T> {
    object Idle : LoadingState<Nothing>()
    object Loading : LoadingState<Nothing>()
    data class Loaded<T>(val data: T) : LoadingState<T>()
    data class Error(val error: AppError) : LoadingState<Nothing>()
}
```

### Enforcement Guidelines

**所有 AI Agent 必须遵守：**

1. 金额一律用 Int64（分）存储，显示时除以 100
2. 日期一律用 ISO 8601 字符串存储，显示时用 Locale 格式化
3. 所有数据库写操作必须在事务中执行
4. 所有用户可见文本必须通过 i18n key 引用，禁止硬编码字符串
5. 所有 UI 颜色/间距/圆角必须引用 Design Tokens，禁止硬编码数值
6. 所有可交互元素必须设置 accessibilityLabel
7. 错误提示语气遵循“温暖友好”原则
8. Repository 接口双端保持方法签名对称
9. 文件/类命名遵循上述命名规范表
10. 不引入任何带网络能力的第三方库

## Project Structure & Boundaries

### Complete Project Directory Structure

```
FreeLedger/
├── README.md
├── LICENSE
├── .gitignore
├── .github/
│   └── workflows/
│       ├── ios-ci.yml
│       └── android-ci.yml
│
├── shared/                               # 双端共享资源
│   ├── icons/
│   │   ├── categories/                   # 分类图标 SVG
│   │   └── navigation/                   # 导航图标 SVG
│   ├── tokens/                           # Design Tokens JSON
│   │   ├── colors.json
│   │   ├── spacing.json
│   │   ├── radius.json
│   │   ├── typography.json
│   │   └── animation.json
│   ├── backup-schema/
│   │   └── backup-v1.schema.json
│   └── default-data/
│       ├── categories-expense.json
│       └── categories-income.json
│
├── ios/FreeLedger/
│   ├── FreeLedgerApp.swift
│   ├── ContentView.swift
│   ├── data/
│   │   ├── database/                     # GRDB DAO + 迁移
│   │   │   ├── AppDatabase.swift
│   │   │   ├── TransactionDAO.swift
│   │   │   ├── CategoryDAO.swift
│   │   │   ├── TagDAO.swift
│   │   │   └── SettingsDAO.swift
│   │   ├── repository/
│   │   │   ├── TransactionRepository.swift
│   │   │   ├── CategoryRepository.swift
│   │   │   ├── TagRepository.swift
│   │   │   └── SettingsRepository.swift
│   │   └── model/
│   │       ├── Transaction.swift
│   │       ├── Category.swift
│   │       ├── Tag.swift
│   │       └── TransactionTag.swift
│   ├── domain/model/
│   │   ├── TransactionSummary.swift
│   │   ├── CategoryStats.swift
│   │   └── ReportData.swift
│   ├── ui/
│   │   ├── home/       (HomeView + HomeViewModel + Tests)
│   │   ├── record/     (RecordView + RecordViewModel + Tests)
│   │   ├── detail/     (DetailView + DetailViewModel + Tests)
│   │   ├── report/     (ReportView + ReportViewModel + Tests)
│   │   ├── tags/       (TagsView + TagsViewModel + Tests)
│   │   ├── settings/   (SettingsView + SettingsViewModel + Tests)
│   │   ├── onboarding/ (OnboardingView + OnboardingViewModel)
│   │   └── components/ (AmountKeypad, CategoryGrid, SummaryCard,
│   │                    TransactionCard, FloatingAddButton,
│   │                    FriendlyDialog, TagSelector, OnboardingOverlay)
│   ├── theme/      (AppColors, AppSpacing, AppRadius, AppTypography)
│   ├── i18n/       (Localizable.strings zh-Hans + en)
│   ├── util/       (AmountFormatter, DateFormatter+App, AppError)
│   ├── backup/     (BackupExporter, BackupImporter, BackupValidator)
│   ├── security/   (PasswordManager, LockScreenView)
│   └── Assets.xcassets/
│
├── android/app/src/main/java/com/freeledger/app/
│   ├── FreeLedgerApp.kt
│   ├── MainActivity.kt
│   ├── data/
│   │   ├── database/                     # Room DAO + 迁移
│   │   │   ├── AppDatabase.kt
│   │   │   ├── TransactionDao.kt
│   │   │   ├── CategoryDao.kt
│   │   │   ├── TagDao.kt
│   │   │   └── SettingsDao.kt
│   │   ├── repository/
│   │   │   ├── TransactionRepository.kt
│   │   │   ├── CategoryRepository.kt
│   │   │   ├── TagRepository.kt
│   │   │   └── SettingsRepository.kt
│   │   └── model/
│   │       ├── TransactionEntity.kt
│   │       ├── CategoryEntity.kt
│   │       ├── TagEntity.kt
│   │       └── TransactionTagEntity.kt
│   ├── domain/model/
│   │   ├── TransactionSummary.kt
│   │   ├── CategoryStats.kt
│   │   └── ReportData.kt
│   ├── ui/
│   │   ├── home/       (HomeScreen + HomeViewModel)
│   │   ├── record/     (RecordScreen + RecordViewModel)
│   │   ├── detail/     (DetailScreen + DetailViewModel)
│   │   ├── report/     (ReportScreen + ReportViewModel)
│   │   ├── tags/       (TagsScreen + TagsViewModel)
│   │   ├── settings/   (SettingsScreen + SettingsViewModel)
│   │   ├── onboarding/ (OnboardingScreen + OnboardingViewModel)
│   │   ├── components/ (同 iOS 组件对称)
│   │   └── navigation/ (AppNavigation.kt)
│   ├── theme/      (AppColors, AppSpacing, AppRadius, AppTypography, FreeLedgerTheme)
│   ├── util/       (AmountFormatter, DateFormatterExt, AppError)
│   ├── backup/     (BackupExporter, BackupImporter, BackupValidator)
│   └── security/   (PasswordManager, LockScreen)
│
└── docs/
```

### Architectural Boundaries

**数据层边界：**
- DAO 只暴露给 Repository，不直接被 UI 层访问
- Repository 是数据层的唯一公共接口
- Entity 模型在 Repository 层转换为 Domain 模型

**UI 层边界：**
- ViewModel 只依赖 Repository，不直接访问 DAO
- View/Screen 只依赖 ViewModel
- 自定义组件（components/）是无状态的，通过参数接收数据

**跨模块通信：**
- 无事件总线，通过 ViewModel → Repository → Database 的单向数据流
- iOS: @Observable 模型驱动 SwiftUI 视图自动刷新
- Android: StateFlow 驱动 Compose 重组

### Requirements to Structure Mapping

| FR 域 | iOS 目录 | Android 目录 |
|--------|---------|---------------|
| 记账核心 FR1-6 | ui/record/, ui/home/, ui/detail/ | 同 |
| 分类管理 FR7-9 | data/database/CategoryDAO, ui/components/CategoryGrid | 同 |
| 标签 FR10-13 | ui/tags/, ui/components/TagSelector | 同 |
| 可视化 FR14-17 | ui/report/ | 同 |
| 搜索 FR18-20 | data/repository/TransactionRepository.search() | 同 |
| 备份 FR21-26 | backup/ | 同 |
| 导出 FR27-28 | backup/BackupExporter (CSV 模式) | 同 |
| 安全 FR29-32 | security/ | 同 |
| 引导 FR33-36 | ui/onboarding/ | 同 |
| 国际化 FR37-38 | i18n/ | res/values*/strings.xml |
| 主题 FR39-40 | theme/ | 同 |
| 设置 FR41-45 | ui/settings/, data/repository/SettingsRepository | 同 |

### Data Flow

```
User Action → View/Screen → ViewModel → Repository → DAO → SQLite
                                ↑                          ↓
                          响应式更新 ←←←←←←←←←←←←←←←←←←
```

iOS: GRDB Combine publisher → @Observable → SwiftUI 自动刷新
Android: Room Flow → StateFlow → Compose 自动重组

## Architecture Validation Results

### Coherence Validation ✅

**Decision Compatibility:**
- SwiftUI + GRDB.swift + Swift Charts — Swift 生态全兼容 ✅
- Jetpack Compose + Room + Vico — Kotlin/Jetpack 生态全兼容 ✅
- MVVM + Repository 双端对称 — 架构模式统一 ✅
- @Observable 需要 iOS 17+ — 已更新最低版本 ✅
- 无矛盾决策 ✅

**Pattern Consistency:**
- 命名规范覆盖数据库、代码、文件、Design Tokens ✅
- 错误处理双端对称（AppError enum / sealed class） ✅
- 状态管理双端对称（LoadingState） ✅
- 数据格式统一（ISO 8601、Int64 分、snake_case JSON） ✅

**Structure Alignment:**
- 目录结构与 MVVM + Repository 对齐（data/domain/ui 三层） ✅
- 共享资源在 shared/ 集中管理 ✅
- 测试文件 co-located ✅

### Requirements Coverage Validation ✅

**功能需求覆盖（45 FR）：**

| FR 域 | 覆盖 | 架构支撑 |
|--------|------|----------|
| 记账核心 FR1-6 | ✅ | transactions 表 + TransactionRepository + RecordView |
| 分类管理 FR7-9 | ✅ | categories 表 + usage_count 智能排序 + CategoryGrid |
| 标签 FR10-13 | ✅ | tags + transaction_tags 多对多 + TagSelector |
| 可视化 FR14-17 | ✅ | Swift Charts / Vico + 聚合查询 |
| 搜索 FR18-20 | ✅ | GRDB FTS5 / Room LIKE 查询 |
| 备份 FR21-26 | ✅ | JSON 格式 + SHA-256 校验 + backup/ 模块 |
| 导出 FR27-28 | ✅ | BackupExporter CSV 模式 |
| 安全 FR29-32 | ✅ | Keychain/KeyStore + PasswordManager + 零网络 |
| 引导 FR33-36 | ✅ | OnboardingView + settings KV 存储状态 |
| 国际化 FR37-38 | ✅ | i18n 原生方案 + Locale API |
| 主题 FR39-40 | ✅ | Design Tokens + theme/ 模块 |
| 设置 FR41-45 | ✅ | settings KV 表 + SettingsRepository |

**非功能需求覆盖：**

| NFR | 架构支撑 | 状态 |
|-----|---------|------|
| 冷启动 < 2s | 轻量初始化、延迟加载 | ✅ |
| 记账 < 3s | 预加载分类、键盘即时就绪 | ✅ |
| 10 万条不卡顿 | 5 个索引策略 | ✅ |
| 零网络 | 零网络代码，强制规则 #10 | ✅ |
| 零数据丢失 | WAL 模式、事务写入，强制规则 #3 | ✅ |
| 金额零误差 | Int64（分），强制规则 #1 | ✅ |
| WCAG AA | accessibilityLabel 强制规则 #6 | ✅ |

### Implementation Readiness Validation ✅

| 维度 | 状态 | 说明 |
|------|------|------|
| 决策完备性 | ✅ | 10 个关键决策全部记录 |
| 模式完备性 | ✅ | 10 条强制规则 + 双端代码示例 |
| 结构完备性 | ✅ | 完整目录树 + FR→目录映射 |
| 边界清晰度 | ✅ | 数据层/UI 层边界明确 + 数据流图 |

### Gap Analysis Results

无关键 Gap。

**次要建议（后续可增强）：**
- DI（依赖注入）策略 — 当前项目规模不大，可暂用手动注入
- 日志策略 — 可后续定义统一日志格式
- 性能监控 — MVP 后续可加入本地度量

### Architecture Completeness Checklist

**✅ 需求分析**
- [x] 项目上下文分析完成
- [x] 规模与复杂度评估
- [x] 技术约束识别
- [x] 跨切面关注点映射

**✅ 架构决策**
- [x] 关键决策记录（含版本和理由）
- [x] 技术栈完整指定
- [x] 数据库 schema 设计
- [x] 备份格式设计
- [x] 安全架构设计

**✅ 实现模式**
- [x] 命名规范建立
- [x] 结构模式定义
- [x] 格式模式指定
- [x] 错误处理模式
- [x] 状态管理模式
- [x] 10 条强制规则

**✅ 项目结构**
- [x] 完整目录树定义
- [x] 组件边界建立
- [x] 数据流映射
- [x] FR→目录映射

### Architecture Readiness Assessment

**Overall Status: ✅ READY FOR IMPLEMENTATION**

**Confidence Level: HIGH**

**关键优势：**
1. 技术栈成熟稳定，零创新风险
2. 双端对称架构降低认知成本
3. 10 条强制规则确保 AI Agent 一致性
4. 45 个 FR 100% 架构覆盖

**未来增强方向：**
- DI 框架引入（项目增长后）
- 性能监控埋点
- 深色模式主题扩展
- 云端同步架构（P3）

### Implementation Handoff

**AI Agent Guidelines:**
- 严格遵循本文档所有架构决策
- 一致使用实现模式（10 条强制规则）
- 尊重项目结构和边界
- 架构问题参考本文档

**First Implementation Priority:**
1. Monorepo 初始化 + shared/ 资源目录
2. Design Tokens JSON 定义
3. Xcode / Android Studio 项目创建 + 依赖添加
