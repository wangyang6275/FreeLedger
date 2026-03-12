# AppReviewService 使用指南

## 功能概述

`AppReviewService` 是一个智能的应用评分引导服务，在用户完成正向操作后，非侵入式地引导用户为应用评分。

## 触发条件

系统会在以下任一条件满足时自动请求评分：

1. ✅ 用户完成 **5 笔交易记录**
2. ✅ 用户**连续使用 7 天**
3. ✅ 用户成功**导出 1 次 CSV 报表**
4. ✅ 用户**创建 1 个提醒**

## 智能策略

- 🕐 两次请求间隔至少 **30 天**
- 🚫 用户拒绝后 **90 天**内不再显示
- ✓ 用户评分后**永久不再显示**
- 📱 使用 iOS 原生 StoreKit 评分弹窗

## 集成步骤

### 1. 在 RecordView 中记录交易创建

```swift
// 文件: ios/ColorFuLedger/ui/record/RecordView.swift

// 在保存交易成功后调用
private func saveTransaction() {
    // ... 你的保存逻辑 ...

    // 记录交易创建，触发评分检查
    AppReviewService.shared.recordTransactionCreated()
}
```

### 2. 在 CSVExportService 中记录导出

```swift
// 文件: ios/ColorFuLedger/data/service/CSVExportService.swift

func exportToCSV() -> URL? {
    // ... 你的导出逻辑 ...

    // 导出成功后记录
    AppReviewService.shared.recordCSVExported()

    return fileURL
}
```

### 3. 在 RemindersView 中记录提醒创建

```swift
// 文件: ios/ColorFuLedger/ui/reminders/RemindersView.swift

private func saveReminder() {
    // ... 你的保存逻辑 ...

    // 记录提醒创建
    AppReviewService.shared.recordReminderCreated()
}
```

### 4. 在 SettingsView 中添加"给我们评分"选项

```swift
// 文件: ios/ColorFuLedger/ui/settings/SettingsView.swift

Section {
    Button(action: {
        AppReviewService.shared.userRequestedReview()
    }) {
        HStack {
            Image(systemName: "star.fill")
                .foregroundColor(.yellow)
            Text("给我们评分")
            Spacer()
            Image(systemName: "chevron.right")
                .foregroundColor(.gray)
        }
    }
} header: {
    Text("支持我们")
}
```

### 5. 在 App 启动时初始化（可选）

```swift
// 文件: ios/ColorFuLedger/ColorFuLedgerApp.swift

@main
struct ColorFuLedgerApp: App {
    init() {
        // 初始化评分服务（会自动更新每日使用记录）
        _ = AppReviewService.shared
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
```

## 测试方法

### 在 Debug 模式下测试

```swift
#if DEBUG
// 重置所有统计数据
AppReviewService.shared.resetAllStats()

// 查看当前统计
let stats = AppReviewService.shared.getCurrentStats()
print("当前统计:", stats)

// 模拟触发条件
for _ in 0..<5 {
    AppReviewService.shared.recordTransactionCreated()
}
#endif
```

### 注意事项

⚠️ **重要**: iOS 系统对评分请求有限制：
- 每个应用每年最多显示 **3 次**评分弹窗
- 系统可能不会立即显示弹窗（即使调用了 API）
- 在模拟器上可能不会显示弹窗

## 自定义配置

如果需要调整触发条件，修改 `AppReviewService.swift` 中的 `Thresholds` 枚举：

```swift
private enum Thresholds {
    static let transactionCount = 5        // 改为你想要的数字
    static let consecutiveDays = 7         // 改为你想要的天数
    static let csvExportCount = 1          // 改为你想要的次数
    static let reminderCount = 1           // 改为你想要的次数
    static let daysBetweenRequests = 30    // 改为你想要的间隔天数
    static let daysAfterDecline = 90       // 改为你想要的等待天数
}
```

## 数据存储

所有统计数据存储在 `UserDefaults` 中，键名前缀为 `app_review_`：

- `app_review_transaction_count` - 交易次数
- `app_review_consecutive_days` - 连续使用天数
- `appew_last_used_date` - 最后使用日期
- `app_review_last_request_date` - 最后请求评分日期
- `app_review_user_declined` - 用户是否拒绝
- `app_review_user_rated` - 用户是否已评分
- `app_review_csv_export_count` - CSV 导出次数
- `app_review_reminder_count` - 提醒创建次数

## 最佳实践

1. ✅ 在用户完成**有价值的操作**后触发
2. ✅ 不要在用户**刚打开应用**时请求
3. ✅ 不要在用户**遇到错误**时请求
4. ✅ 给用户足够的**使用时间**再请求
5. ✅ 尊重用户的选择，不要**频繁打扰**
