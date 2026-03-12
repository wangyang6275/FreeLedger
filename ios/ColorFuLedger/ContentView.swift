import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 0
    @State private var showRecord = false
    @State private var deepLinkRecord = false
    @State private var reminderPrefill: ReminderPrefill?
    @State private var languageManager = LanguageManager.shared
    @State private var showBackupReminder = false
    @State private var backupReminderMessage = ""
    @State private var isLocked = false
    @State private var showOnboarding = false
    @Environment(\.scenePhase) private var scenePhase

    private let container: DependencyContainer
    private let homeViewModel: HomeViewModel

    init() {
        let container = DependencyContainer()
        self.container = container
        self.homeViewModel = HomeViewModel(
            transactionRepository: container.transactionRepository,
            categoryRepository: container.categoryRepository,
            settingsRepository: container.settingsRepository,
            budgetRepository: container.budgetRepository
        )
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $selectedTab) {
                HomeView(
                        viewModel: homeViewModel,
                        transactionRepository: container.transactionRepository,
                        categoryRepository: container.categoryRepository,
                        settingsRepository: container.settingsRepository,
                        tagRepository: container.tagRepository,
                        reminderRepository: container.reminderRepository
                    )
                    .tabItem {
                        Image(systemName: "list.bullet")
                        Text(L("tab_transactions"))
                    }
                    .tag(0)

                ReportView(
                        transactionRepository: container.transactionRepository,
                        settingsRepository: container.settingsRepository,
                        tagRepository: container.tagRepository
                    )
                    .tabItem {
                        Image(systemName: "chart.pie")
                        Text(L("tab_reports"))
                    }
                    .tag(1)

                Color.clear
                    .tabItem { Text("") }
                    .tag(2)

                TagsView(
                        tagRepository: container.tagRepository,
                        transactionRepository: container.transactionRepository,
                        categoryRepository: container.categoryRepository,
                        settingsRepository: container.settingsRepository
                    )
                    .tabItem {
                        Image(systemName: "tag")
                        Text(L("tab_tags"))
                    }
                    .tag(3)

                SettingsView(categoryRepository: container.categoryRepository, backupService: container.backupService, settingsRepository: container.settingsRepository, csvExportService: container.csvExportService, passwordService: container.passwordService, budgetRepository: container.budgetRepository, transactionRepository: container.transactionRepository, templateRepository: container.templateRepository, tagRepository: container.tagRepository, dbQueue: container.db.dbQueue, achievementService: container.achievementService, onDataRestored: {
                        homeViewModel.loadData()
                    }, onShowOnboarding: {
                        showOnboarding = true
                    })
                    .tabItem {
                        Image(systemName: "gearshape")
                        Text(L("tab_settings"))
                    }
                    .tag(4)
            }
            .tint(AppColors.primary)

            FloatingAddButton {
                showRecord = true
            }
            .offset(y: -20)
        }
        .id(languageManager.refreshId)
        .sheet(isPresented: $showRecord) {
            RecordView(
                transactionRepository: container.transactionRepository,
                categoryRepository: container.categoryRepository,
                settingsRepository: container.settingsRepository,
                tagRepository: container.tagRepository,
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
            if container.passwordService.isPasswordSet() {
                isLocked = true
            }
            let completed = try? container.settingsRepository.get(key: "onboarding_completed")
            if completed == nil {
                showOnboarding = true
            }
            checkBackupReminder()
            checkPendingReminder()
        }
        .fullScreenCover(isPresented: $showOnboarding) {
            OnboardingView(settingsRepository: container.settingsRepository) {
                showOnboarding = false
                homeViewModel.loadData()
            }
        }
        .onOpenURL { url in
            if url.scheme == "colorfuledger" && url.host == "record" {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    showRecord = true
                }
            }
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .background && container.passwordService.isPasswordSet() {
                isLocked = true
            }
            if newPhase == .active {
                checkPendingReminder()
            }
        }
        .overlay {
            if showBackupReminder {
                FriendlyDialog(
                    title: L("backup_reminder_title"),
                    message: backupReminderMessage,
                    style: .info,
                    confirmTitle: L("backup_reminder_go"),
                    cancelTitle: L("backup_reminder_later"),
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
                LockScreenView(passwordService: container.passwordService) {
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
        guard let reminder = try? container.reminderRepository.getById(reminderId) else { return }
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
        switch container.backupReminderService.checkReminder() {
        case .firstBackup(let count):
            backupReminderMessage = L("backup_reminder_first %lld", count)
            withAnimation(.easeInOut(duration: 0.25)) {
                showBackupReminder = true
            }
        case .periodicBackup:
            backupReminderMessage = L("backup_reminder_periodic")
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
