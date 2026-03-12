# ColorFuLedger 应用评分功能集成指南

## 🎯 功能说明

已为 ColorFuLedger 创建智能评分引导系统，在用户完成以下正向操作后自动触发：

1. ✅ 完成 5 笔交易记录
2. ✅ 连续使用 7 天
3. ✅ 导出 1 次 CSV
4. ✅ 创建 1 个提醒

## 📦 已创建的文件

1. **AppReviewService.swift** - 核心服务类
   - 路径: `ios/ColorFuLedger/data/service/AppReviewService.swift`
   - 功能: 跟踪用户行为，智能触发评分请求

2. **AppReviewService_Usage.md** - 使用文档
   - 路径: `ios/ColorFuLedger/data/service/AppReviewService_Usage.md`
   - 内容: 详细的使用说明和最佳实践

## 🔧 需要集成的位置

### 1. RecordViewModel.swift - 记录交易创建

**文件**: `ios/ColorFuLedger/ui/record/RecordViewModel.swift`

**修改位置**: 第 68-87 行的 `saveTransaction` 方法

**修改前**:
```swift
func saveTransaction(categoryId: String, tagIds: [String] = []) {
    guard canSave else { return }
    isSaving = true

    do {
        let type = isExpense ? TransactionType.expense.rawValue : TransactionType.income.rawValue
        let noteText = note.trimmingCharacters(in: .whitespacesAndNewlines)
        try transactionRepository.insert(
            amount: amountInCents,
            type: type,
            categoryId: categoryId,
            note: noteText.isEmpty ? nil : noteText,
            tagIds: tagIds
        )
        didSave = true
    } catch {
        isSaving = false
        errorMessage = L("error_save_failed")
    }
}
```

**修改后**:
```swift
func saveTransaction(categoryId: String, tagIds: [String] = []) {
    guard canSave else { return }
    isSaving = true

    do {
        let type = isExpense ? TransactionType.expense.rawValue : TransactionType.income.rawValue
        let noteText = note.trimmingCharacters(in: .whitespacesAndNewlines)
        try transactionRepository.insert(
            amount: amountInCents,
            type: type,
            categoryId: categoryId,
            note: noteText.isEmpty ? nil : noteText,
            tagIds: tagIds
        )
        didSave = true

        // 🆕 记录交易创建，触发评分检查
        AppReviewService.shared.recordTransactionCreated()
    } catch {
        isSaving = false
        errorMessage = L("error_save_failed")
    }
}
```

---

### 2. CSVExportView.swift - 记录 CSV 导出

**文件**: `ios/ColorFuLedger/ui/settings/CSVExportView.swift`

需要在 CSV 导出成功后添加记录。请找到导出成功的位置（通常在 `exportCSV()` 或类似方法中），添加：

```swift
// 导出成功后
AppReviewService.shared.recordCSVExported()
```

---

### 3. RemindersView.swift - 记录提醒创建

**文件**: `ios/ColorFuLedger/ui/reminders/RemindersView.swift`

需要在提醒创建成功后添加记录。请找到保存提醒的位置，添加：

```swift
// 提醒创建成功后
AppReviewService.shared.recordReminderCreated()
```

---

### 4. SettingsView.swift - 添加"给我们评分"选项

**文件**: `ios/ColorFuLedger/ui/settings/SettingsView.swift`

**修改位置**: 第 136-147 行的"联系我们"部分之后

**添加新的 Section**:
```swift
Section(L("settings_contact_section")) {
    Link(destination: URL(string: "mailto:tomaswell163@gmail.com?sColorFuLedger%20Feedback")!) {
        HStack {
            Label(L("settings_contact_us"), systemImage: "envelope")
                .foregroundColor(AppColors.textPrimary)
            Spacer()
            Image(systemName: "arrow.up.forward")
                .font(.caption)
                .foregroundColor(AppColors.textSecondary)
        }
    }
}

// 🆕 添加这个新的 Section
Section(L("settings_support_section")) {
    Button(action: {
        AppReviewService.shared.userRequestedReview()
    }) {
        HStack {
            Label(L("settings_rate_app"), systemImage: "star.fill")
                .foregroundColor(AppColors.textPrimary)
            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(AppColors.textSecondary)
        }
    }
}
```

---

### 5. 添加本地化字符串

需要在所有语言的 `Localizable.strings` 文件中添加以下键值对：

**英文** (`en.lproj/Localizable.strings`):
```
"settings_support_section" = "Support Us";
"settings_rate_app" = "Rate ColorFuLedger";
```

**中文** (`zh-Hans.lproj/Localizable.strings`):
```
"settings_support_section" = "支持我们";
"settings_rate_app" = "给 ColorFuLedger 评分";
```

其他语言类似添加。

---

## 🚀 快速集成步骤

### 步骤 1: 添加文件到 Xcode 项目

1. 打开 Xcode 项目
2. 在项目导航器中找到 `ColorFuLedger/data/service/` 文件夹
3. 右键点击 → Add Files to "ColorFuLedger"
4. 选择 `AppReviewService.swift`
5. 确保 "Copy items if needed" 被勾选
6. Target 选择 "ColorFuLedger"（主应用）

### 步骤 2: 修改代码

按照上面的说明，依次修改以下文件：
1. ✅ RecordViewModel.swift
2. ✅ CSVExportView.swift
3. ✅ RemindersView.swift
4. ✅ SettingsView.swift

### 步骤 3: 添加本地化字符串

在所有 `Localizable.strings` 文件中添加新的键值对。

### 步骤 4: 测试

```swift
#if DEBUG
// 在 Debug 模式下测试
AppReviewService.shared.resetAllStats()

// 模拟 5 次交易
for _ in 0..<5 {
    AppReviewService.shared.recordTransactionCreated()
}

// 查看统计
print(AppReviewService.shared.getCurrentStats())
#endif
```

---

## ⚠️ 重要注意事项

1. **iOS 限制**:
   - 每个应用每年最多显示 3 次评分弹窗
   - 系统可能不会立即显示（即使满足条件）
   - 模拟器上可能不显示

2. **用户体验**:
   - 不要在用户遇到错误时请求评分
   - 不要在应用启动时立即请求
   - 尊重用户的选择

3. **数据存储**:
   - 所有数据存储在 UserDefaults
   - 卸载应用会清除数据
   - 可以通过 `resetAllStats()` 重置（仅 Debug 模式）

---

## 📊 监控和调整

### 查看当前统计（Debug 模式）

```swift
let stats = AppReviewService.shared.getCurrentStats()
print("交易次数: \(stats["transactions")
print("连续使用天数: \(stats["consecutiveDays"] ?? 0)")
print("CSV 导出次数: \(stats["csvExports"] ?? 0)")
print("提醒创建次数: \(stats["reminders"] ?? 0)")
```

### 调整触发阈值

如果发现触发太频繁或太少，可以修改 `AppReviewService.swift` 中的 `Thresholds` 枚举：

```swift
private enum Thresholds {
    static let transactionCount = 5        // 改为 10 会更晚触发
    static let consecutiveDays = 7         // 改为 14 会更晚触发
    static let csvExportCount = 1
    static let reminderCount = 1
    static let daysBetweenRequests = 30    // 改为 60 会减少频率
    static let daysAfterDecline = 90
}
```

---

## ✅ 完成检查清单

- [ ] AppReviewService.swift 已添加到 Xcode 项目
- [ ] RecordViewModel.swift 已修改
- [ ] CSVExportView.swift 已修改
- [ ] RemindersView.swift 已修改
- [ ] SettingsView.swift 已修改
- [ ] 所有语言的 Localizable.strings 已更新
- [ ] 在模拟器上测试过
- [ ] 在真机上测试过

---

## 🎉 预期效果

用户在完成以下任一操作后，可能会看到 iOS 原生的评分弹窗：

- 记录第 5 笔交易后
- 连续使用 7 天后打开应用
- 第一次导出 CSV 后
- 创建第一个提醒后

弹窗样式是 iOS 系统原生的，用户可以：
- 直接给 1-5 星评分
- 点击"不，谢谢"拒绝
- 点击"稍后提醒"延后

系统会自动处理用户的选择，你的应用无需额外处理。
