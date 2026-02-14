import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 0
    @State private var showRecord = false
    @State private var deepLinkRecord = false
    @State private var reminderPrefill: ReminderPrefill?
    @State private var showBackupReminder = false
    @State private var backupReminderMessage = ""
    @State private var isLocked = false
    @State private var showOnboarding = false
    @Environment(\.scenePhase) private var scenePhase

    private let db = AppDatabase.shared
    private let categoryDAO: CategoryDAO
    private let transactionDAO: TransactionDAO
    private let settingsDAO: SettingsDAO
    private let tagDAO: TagDAO
    private let transactionRepository: TransactionRepository
    private let categoryRepository: CategoryRepository
    private let settingsRepository: SettingsRepository
    private let tagRepository: TagRepository
    private let backupService: BackupService
    private let backupReminderService: BackupReminderService
    private let csvExportService: CSVExportService
    private let reminderDAO: ReminderDAO
    private let reminderRepository: ReminderRepository
    private let passwordService: PasswordService
    private let homeViewModel: HomeViewModel

    init() {
        let db = AppDatabase.shared
        let catDAO = CategoryDAO(dbQueue: db.dbQueue)
        let txDAO = TransactionDAO(dbQueue: db.dbQueue)
        let setDAO = SettingsDAO(dbQueue: db.dbQueue)
        let tagDAO = TagDAO(dbQueue: db.dbQueue)
        self.categoryDAO = catDAO
        self.transactionDAO = txDAO
        self.settingsDAO = setDAO
        self.tagDAO = tagDAO
        let remDAO = ReminderDAO(dbQueue: db.dbQueue)
        self.reminderDAO = remDAO
        self.transactionRepository = TransactionRepository(dbQueue: db.dbQueue, transactionDAO: txDAO, categoryDAO: catDAO, tagDAO: tagDAO)
        self.categoryRepository = CategoryRepository(dao: catDAO)
        self.settingsRepository = SettingsRepository(dao: setDAO)
        self.tagRepository = TagRepository(dao: tagDAO)
        self.reminderRepository = ReminderRepository(dao: remDAO)
        self.backupService = BackupService(dbQueue: db.dbQueue)
        self.backupReminderService = BackupReminderService(dbQueue: db.dbQueue, settingsDAO: setDAO)
        self.csvExportService = CSVExportService(dbQueue: db.dbQueue)
        self.passwordService = PasswordService()
        self.homeViewModel = HomeViewModel(
            transactionRepository: self.transactionRepository,
            categoryRepository: self.categoryRepository,
            settingsRepository: self.settingsRepository
        )
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $selectedTab) {
                HomeView(
                        viewModel: homeViewModel,
                        transactionRepository: transactionRepository,
                        categoryRepository: categoryRepository,
                        settingsRepository: settingsRepository,
                        tagRepository: tagRepository,
                        reminderRepository: reminderRepository
                    )
                    .tabItem {
                        Image(systemName: "list.bullet")
                        Text(String(localized: "tab_transactions"))
                    }
                    .tag(0)

                ReportView(
                        transactionRepository: transactionRepository,
                        settingsRepository: settingsRepository,
                        tagRepository: tagRepository
                    )
                    .tabItem {
                        Image(systemName: "chart.pie")
                        Text(String(localized: "tab_reports"))
                    }
                    .tag(1)

                Color.clear
                    .tabItem { Text("") }
                    .tag(2)

                TagsView(
                        tagRepository: tagRepository,
                        transactionRepository: transactionRepository,
                        categoryRepository: categoryRepository,
                        settingsRepository: settingsRepository
                    )
                    .tabItem {
                        Image(systemName: "tag")
                        Text(String(localized: "tab_tags"))
                    }
                    .tag(3)

                SettingsView(categoryRepository: categoryRepository, backupService: backupService, settingsRepository: settingsRepository, csvExportService: csvExportService, passwordService: passwordService, onDataRestored: {
                        homeViewModel.loadData()
                    }, onShowOnboarding: {
                        showOnboarding = true
                    })
                    .tabItem {
                        Image(systemName: "gearshape")
                        Text(String(localized: "tab_settings"))
                    }
                    .tag(4)
            }
            .tint(AppColors.primary)

            FloatingAddButton {
                showRecord = true
            }
            .offset(y: -20)
        }
        .sheet(isPresented: $showRecord) {
            RecordView(
                transactionRepository: transactionRepository,
                categoryRepository: categoryRepository,
                settingsRepository: settingsRepository,
                tagRepository: tagRepository,
                prefill: reminderPrefill
            )
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
        }
        .onChange(of: showRecord) { _, isShowing in
            if !isShowing {
                homeViewModel.loadData()
                reminderPrefill = nil
            }
        }
        .onAppear {
            if passwordService.isPasswordSet() {
                isLocked = true
            }
            let completed = try? settingsRepository.get(key: "onboarding_completed")
            if completed == nil {
                showOnboarding = true
            }
            checkBackupReminder()
            checkPendingReminder()
        }
        .fullScreenCover(isPresented: $showOnboarding) {
            OnboardingView(settingsRepository: settingsRepository) {
                showOnboarding = false
                homeViewModel.loadData()
            }
        }
        .onOpenURL { url in
            if url.scheme == "freeledger" && url.host == "record" {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    showRecord = true
                }
            }
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .background && passwordService.isPasswordSet() {
                isLocked = true
            }
            if newPhase == .active {
                checkPendingReminder()
            }
        }
        .overlay {
            if showBackupReminder {
                FriendlyDialog(
                    title: String(localized: "backup_reminder_title"),
                    message: backupReminderMessage,
                    style: .info,
                    confirmTitle: String(localized: "backup_reminder_go"),
                    cancelTitle: String(localized: "backup_reminder_later"),
                    onConfirm: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            showBackupReminder = false
                        }
                        selectedTab = 4
                    },
                    onCancel: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            showBackupReminder = false
                        }
                    }
                )
            }
        }
        .overlay {
            if isLocked {
                LockScreenView(passwordService: passwordService) {
                    isLocked = false
                }
                .transition(.opacity)
            }
        }
    }
    private func checkPendingReminder() {
        guard !isLocked, !showOnboarding else { return }
        guard let reminderId = UserDefaults.standard.string(forKey: AppDelegate.pendingReminderKey) else { return }
        UserDefaults.standard.removeObject(forKey: AppDelegate.pendingReminderKey)
        guard let reminder = try? reminderRepository.getById(reminderId) else { return }
        reminderPrefill = ReminderPrefill(
            amount: reminder.amount,
            type: reminder.type,
            categoryId: reminder.categoryId,
            note: reminder.note
        )
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            showRecord = true
        }
    }

    private func checkBackupReminder() {
        switch backupReminderService.checkReminder() {
        case .firstBackup(let count):
            backupReminderMessage = String(localized: "backup_reminder_first \(count)")
            withAnimation(.easeInOut(duration: 0.25)) {
                showBackupReminder = true
            }
        case .periodicBackup:
            backupReminderMessage = String(localized: "backup_reminder_periodic")
            withAnimation(.easeInOut(duration: 0.25)) {
                showBackupReminder = true
            }
        case .none:
            break
        }
    }
}

#Preview {
    ContentView()
}
