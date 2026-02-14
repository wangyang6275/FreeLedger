# Epic 4 Retrospective: 数据保护

## Summary

Epic 4 包含 4 个 Story，全部在单次开发会话中完成。涵盖备份导出、备份导入恢复、备份提醒、CSV 导出四大功能模块，引入 CryptoKit、FileDocument、fileExporter/fileImporter 等系统框架。

| Story | 描述 | Code Review |
|-------|------|-------------|
| 4.1 | 备份导出 | 0 issues |
| 4.2 | 备份导入与恢复 | 0 issues |
| 4.3 | 备份提醒 | 0 issues |
| 4.4 | CSV 导出 | 0 issues |

## What Went Well

1. **FileDocument + fileExporter/fileImporter 模式成熟** — Story 4.1 确立 BackupDocument 模式后，4.4 CSVDocument 直接复用，零学习成本
2. **CryptoKit SHA-256 一次到位** — BackupData.generateChecksum 在导出/导入两端复用，校验逻辑清晰
3. **事务安全** — Story 4.2 导入恢复使用 dbQueue.write 单事务 DELETE + INSERT，保证原子性
4. **Security-scoped URL** — 正确处理沙盒文件访问（startAccessingSecurityScopedResource / defer stop）
5. **增量式 SettingsView** — 从 Story 4.1 到 4.4 逐步扩展备份 Section，无需重写
6. **Code Review 零缺陷** — 4 个 Story 全部 0 issues，检查清单 13 条严格遵守
7. **设计决策合理** — Story 4.3 使用 App 内 FriendlyDialog 而非系统 Local Notification，避免不必要的权限请求

## What Could Be Improved

1. **依赖注入链继续增长** — SettingsView 现在需要 4 个依赖（categoryRepository, backupService, settingsRepository, csvExportService），ContentView init() 参数列表越来越长。Epic 2/3 retro 都提出的 DI 优化仍未实施
2. **SettingsView body 复杂度增加** — 包含 fileExporter + fileImporter + sheet + 3 个 FriendlyDialog overlay + alert，虽然没触发编译器超时但接近临界点
3. **FriendlyDialogStyle 枚举不完整** — Story 4.1 遇到 .normal 不存在，需改用 .info。说明 FriendlyDialog 组件的样式枚举需要补充或文档化
4. **进度指示器缺失** — Epic 3 retro 建议 Story 4.1/4.2 加进度 UI，但实际数据量小，未实施
5. **BackupData 未包含 settings 表** — 当前备份只包含 transactions/categories/tags/transactionTags，settings 表（如 currency、last_backup_date）未包含在备份中

## Epic 3 Retro Follow-Through

| Action Item | Status |
|-------------|--------|
| ✅ Codable 序列化所有模型 | 完成 — Transaction, Category, Tag, TransactionTag 全部 Codable |
| ✅ SHA-256 校验 via CryptoKit | 完成 — BackupData.generateChecksum |
| ⏳ DocumentPicker (UIViewControllerRepresentable) | 未使用 — 改用原生 .fileExporter/.fileImporter（更简洁） |
| ✅ 大数据事务批量写入 | 完成 — dbQueue.write 单事务 |
| ⏳ DI 优化（Environment 注入） | 未实施 — 依赖链继续增长（第 3 次提出） |
| ⏳ 进度指示器 | 未实施 — 数据量小无需进度 UI |

**Follow-Through Rate: 3/6 (50%)** — 下降原因：3 项被合理跳过或替代方案

## Code Review 经验总结

### Epic 4 新增检查项

| # | 规则 | 来源 |
|---|------|------|
| 14 | FileDocument 协议用于 fileExporter/fileImporter | Story 4.1/4.4 模式 |
| 15 | Security-scoped URL 必须 start/defer stop | Story 4.2 沙盒访问 |
| 16 | 破坏性操作先 FriendlyDialog (.destructive) 确认 | Story 4.2 导入覆盖 |

### 完整检查清单（16 条）

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
14. FileDocument 协议用于 fileExporter/fileImporter
15. Security-scoped URL 必须 start/defer stop
16. 破坏性操作先 FriendlyDialog (.destructive) 确认

## Architecture Notes

### 新增数据层

- **BackupData 模型** — Codable, version + checksum + 4 表数据
- **BackupService** — exportBackup (JSON + SHA-256) + importBackup (校验 + 事务恢复)
- **BackupError enum** — invalidFile / checksumMismatch
- **BackupReminderService** — ReminderType enum + checkReminder 逻辑
- **CSVExportService** — 字段选择 + CSV 生成 + 转义 + 分类解析 + 标签关联
- **CSVExportField** — 字段选择模型
- **settings 表新增** — last_backup_date key

### 新增 UI 层

| 文件 | 类型 | 功能 |
|------|------|------|
| BackupDocument | FileDocument | JSON 备份文件包装 |
| CSVDocument | FileDocument | CSV 文件包装 |
| CSVExportView | View | 字段选择 Toggle + fileExporter |
| SettingsView | View | 扩展 — 备份导出/导入/CSV 三大功能 |

### i18n 增量

- Story 4.1: +4 字符串
- Story 4.2: +6 字符串
- Story 4.3: +5 字符串
- Story 4.4: +10 字符串
- 总计: +25 字符串（zh-Hans + en 各 25）

## Metrics

| 指标 | 值 |
|------|-----|
| Stories 完成 | 4/4 |
| 新增文件 | 5 |
| 修改文件 | ~8 |
| 新增 i18n 字符串 | 25 × 2 = 50 |
| Code Review Issues | 0 (all stories) |
| 编译错误修复 | 1（FriendlyDialogStyle .normal → .info） |
| 数据库迁移 | 0（复用 settings 表） |
| 新增框架 | CryptoKit, UniformTypeIdentifiers |

## Recommendations for Epic 5

1. **Keychain 存储** — Story 5.1 密码哈希需要存储在 Keychain（KeychainAccess 或原生 Security 框架），不要存在 settings 表
2. **SHA-256 + Salt** — 密码哈希用 CryptoKit（Epic 4 已引入），生成随机 salt
3. **DI 优化** — **强烈建议**在 Epic 5 之前重构为 Environment 注入模式，ContentView init() 已有 8+ 个服务实例，再增加 PasswordService 将更难管理
4. **SettingsView 拆分** — 当前 SettingsView 已 200+ 行、3 个 overlay，建议拆分为子视图（BackupSection、SecuritySection）
5. **BiometricAuthentication** — 考虑 Face ID/Touch ID 作为密码解锁的便捷方式（LocalAuthentication 框架）
