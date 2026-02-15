import SwiftUI
import UniformTypeIdentifiers

struct SettingsView: View {
    let categoryRepository: CategoryRepositoryProtocol
    let backupService: BackupService
    let settingsRepository: SettingsRepositoryProtocol
    let csvExportService: CSVExportService
    let passwordService: PasswordService

    @State private var showExporter = false
    @State private var backupDocument: BackupDocument?
    @State private var showBackupSuccess = false
    @State private var backupRecordCount = 0
    @State private var errorMessage: String?
    @State private var showImportWarning = false
    @State private var showImporter = false
    @State private var showRestoreSuccess = false
    @State private var restoreRecordCount = 0
    @State private var showCSVExport = false
    @State private var isPasswordEnabled = false
    @State private var showSetPassword = false
    @State private var showVerifyToDisable = false
    @State private var showPasswordSetSuccess = false
    @State private var showChangePasswordVerify = false
    @State private var showChangePasswordSet = false
    @State private var selectedCurrency = "CNY"

    var onDataRestored: (() -> Void)?
    var onShowOnboarding: (() -> Void)?

    var body: some View {
        NavigationStack {
            List {
                Section(L("settings_general")) {
                    NavigationLink {
                        CurrencyPickerView(selectedCurrency: $selectedCurrency, settingsRepository: settingsRepository)
                    } label: {
                        HStack {
                            Label(L("settings_currency"), systemImage: "dollarsign.circle")
                            Spacer()
                            Text(selectedCurrency)
                                .foregroundColor(AppColors.textSecondary)
                        }
                    }

                    NavigationLink {
                        LanguagePickerView()
                    } label: {
                        HStack {
                            Label(L("settings_language"), systemImage: "globe")
                            Spacer()
                            Text(LanguageManager.shared.currentLanguageDisplay)
                                .foregroundColor(AppColors.textSecondary)
                        }
                    }

                    NavigationLink {
                        ThemePickerView()
                    } label: {
                        HStack {
                            Label(L("settings_theme"), systemImage: "paintpalette")
                            Spacer()
                            Circle()
                                .fill(AppColors.primary)
                                .frame(width: 20, height: 20)
                        }
                    }
                }

                Section(L("settings_password_section")) {
                    Toggle(L("settings_password_lock"), isOn: Binding(
                        get: { isPasswordEnabled },
                        set: { newValue in
                            if newValue {
                                showSetPassword = true
                            } else {
                                showVerifyToDisable = true
                            }
                        }
                    ))

                    if isPasswordEnabled {
                        Button {
                            showChangePasswordVerify = true
                        } label: {
                            Label(L("settings_change_password"), systemImage: "key.horizontal")
                        }
                    }
                }

                Section(L("settings_data_section")) {
                    NavigationLink {
                        CategoryManagementView(categoryRepository: categoryRepository)
                    } label: {
                        Label(L("settings_category_management"), systemImage: "square.grid.2x2")
                    }

                    Button {
                        exportBackup()
                    } label: {
                        Label(L("settings_export_backup"), systemImage: "square.and.arrow.up")
                    }

                    Button {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            showImportWarning = true
                        }
                    } label: {
                        Label(L("settings_import_restore"), systemImage: "square.and.arrow.down")
                    }

                    Button {
                        showCSVExport = true
                    } label: {
                        Label(L("settings_export_csv"), systemImage: "doc.text")
                    }
                }

                Section(L("settings_about_section")) {
                    Button {
                        onShowOnboarding?()
                    } label: {
                        Label(L("settings_replay_onboarding"), systemImage: "arrow.counterclockwise")
                            .foregroundColor(AppColors.textPrimary)
                    }

                    HStack {
                        Label(L("settings_version"), systemImage: "info.circle")
                        Spacer()
                        Text(appVersion)
                            .foregroundColor(AppColors.textSecondary)
                    }
                }

                Section(L("settings_contact_section")) {
                    Link(destination: URL(string: "mailto:tomaswell163@gmail.com?subject=FreeLedger%20Feedback")!) {
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
            }
            .navigationTitle(L("tab_settings"))
            .fileExporter(
                isPresented: $showExporter,
                document: backupDocument,
                contentType: .json,
                defaultFilename: "FreeLedger-Backup-\(backupDateString).json"
            ) { result in
                switch result {
                case .success:
                    try? settingsRepository.set(key: "last_backup_date", value: ISO8601DateFormatter().string(from: Date()))
                    withAnimation(.easeInOut(duration: 0.25)) {
                        showBackupSuccess = true
                    }
                case .failure:
                    errorMessage = L("error_save_failed")
                }
                backupDocument = nil
            }
            .alert(L("error_title"), isPresented: Binding(
                get: { errorMessage != nil },
                set: { if !$0 { errorMessage = nil } }
            )) {
                Button(L("error_ok"), role: .cancel) {}
            } message: {
                Text(errorMessage ?? "")
            }
            .fileImporter(
                isPresented: $showImporter,
                allowedContentTypes: [.json],
                allowsMultipleSelection: false
            ) { result in
                handleImportResult(result)
            }
            .sheet(isPresented: $showCSVExport) {
                CSVExportView(csvExportService: csvExportService)
            }
            .sheet(isPresented: $showSetPassword) {
                SetPasswordView(passwordService: passwordService) {
                    isPasswordEnabled = true
                    withAnimation(.easeInOut(duration: 0.25)) {
                        showPasswordSetSuccess = true
                    }
                }
            }
            .sheet(isPresented: $showVerifyToDisable) {
                VerifyPasswordView(
                    passwordService: passwordService,
                    title: L("password_enter_to_disable")
                ) {
                    _ = passwordService.removePassword()
                    isPasswordEnabled = false
                }
            }
            .onAppear {
                isPasswordEnabled = passwordService.isPasswordSet()
                if let currency = try? settingsRepository.get(key: "currency") {
                    selectedCurrency = currency
                }
            }
            .sheet(isPresented: $showChangePasswordVerify) {
                VerifyPasswordView(
                    passwordService: passwordService,
                    title: L("password_enter_current")
                ) {
                    showChangePasswordSet = true
                }
            }
            .sheet(isPresented: $showChangePasswordSet) {
                SetPasswordView(passwordService: passwordService) {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        showPasswordSetSuccess = true
                    }
                }
            }
        }
        .overlay {
            if showBackupSuccess {
                FriendlyDialog(
                    title: L("backup_success_title"),
                    message: L("backup_success_message %lld", backupRecordCount),
                    style: .info,
                    confirmTitle: L("error_ok"),
                    cancelTitle: nil,
                    onConfirm: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            showBackupSuccess = false
                        }
                    },
                    onCancel: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            showBackupSuccess = false
                        }
                    }
                )
            }
            if showImportWarning {
                FriendlyDialog(
                    title: L("restore_warning_title"),
                    message: L("restore_warning_message"),
                    style: .destructive,
                    confirmTitle: L("restore_warning_confirm"),
                    cancelTitle: L("action_cancel"),
                    onConfirm: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            showImportWarning = false
                        }
                        showImporter = true
                    },
                    onCancel: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            showImportWarning = false
                        }
                    }
                )
            }
            if showPasswordSetSuccess {
                FriendlyDialog(
                    title: L("password_set_success_title"),
                    message: L("password_set_success_message"),
                    style: .info,
                    confirmTitle: L("error_ok"),
                    cancelTitle: nil,
                    onConfirm: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            showPasswordSetSuccess = false
                        }
                    },
                    onCancel: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            showPasswordSetSuccess = false
                        }
                    }
                )
            }
            if showRestoreSuccess {
                FriendlyDialog(
                    title: L("restore_success_title"),
                    message: L("restore_success_message %lld", restoreRecordCount),
                    style: .info,
                    confirmTitle: L("error_ok"),
                    cancelTitle: nil,
                    onConfirm: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            showRestoreSuccess = false
                        }
                        onDataRestored?()
                    },
                    onCancel: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            showRestoreSuccess = false
                        }
                        onDataRestored?()
                    }
                )
            }
        }
    }

    private var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (\(build))"
    }

    private var backupDateString: String {
        let f = DateFormatter()
        f.dateFormat = "yyyyMMdd"
        return f.string(from: Date())
    }

    private func exportBackup() {
        do {
            let data = try backupService.exportBackup()
            backupRecordCount = backupService.transactionCount
            backupDocument = BackupDocument(data: data)
            showExporter = true
        } catch {
            errorMessage = L("error_save_failed")
        }
    }

    private func handleImportResult(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            guard url.startAccessingSecurityScopedResource() else {
                errorMessage = L("error_load_failed")
                return
            }
            defer { url.stopAccessingSecurityScopedResource() }
            do {
                let data = try Data(contentsOf: url)
                let count = try backupService.importBackup(data: data)
                restoreRecordCount = count
                withAnimation(.easeInOut(duration: 0.25)) {
                    showRestoreSuccess = true
                }
            } catch BackupError.checksumMismatch {
                errorMessage = L("error_checksum_mismatch")
            } catch BackupError.invalidFile {
                errorMessage = L("error_checksum_mismatch")
            } catch {
                errorMessage = L("error_load_failed")
            }
        case .failure:
            errorMessage = L("error_load_failed")
        }
    }
}

struct BackupDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.json] }

    let data: Data

    init(data: Data) {
        self.data = data
    }

    init(configuration: ReadConfiguration) throws {
        self.data = configuration.file.regularFileContents ?? Data()
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: data)
    }
}
