import SwiftUI

struct TemplateListView: View {
    @State private var viewModel: TemplateViewModel
    @State private var showAddTemplate = false
    @State private var deleteTemplateId: String?

    let transactionRepository: TransactionRepositoryProtocol
    let categoryRepository: CategoryRepositoryProtocol
    let settingsRepository: SettingsRepositoryProtocol
    let tagRepository: TagRepositoryProtocol
    let onUseTemplate: (ReminderPrefill) -> Void

    init(templateRepository: TransactionTemplateRepositoryProtocol,
         transactionRepository: TransactionRepositoryProtocol,
         categoryRepository: CategoryRepositoryProtocol,
         settingsRepository: SettingsRepositoryProtocol,
         tagRepository: TagRepositoryProtocol,
         onUseTemplate: @escaping (ReminderPrefill) -> Void) {
        self.transactionRepository = transactionRepository
        self.categoryRepository = categoryRepository
        self.settingsRepository = settingsRepository
        self.tagRepository = tagRepository
        self.onUseTemplate = onUseTemplate
        _viewModel = State(initialValue: TemplateViewModel(
            templateRepository: templateRepository,
            categoryRepository: categoryRepository,
            settingsRepository: settingsRepository
        ))
    }

    var body: some View {
        List {
            if viewModel.items.isEmpty {
                Section {
                    VStack(spacing: AppSpacing.md) {
                        Image(systemName: "doc.on.doc")
                            .font(.system(size: 40))
                            .foregroundColor(AppColors.textTertiary)
                        Text(L("template_empty"))
                            .font(AppTypography.body)
                            .foregroundColor(AppColors.textSecondary)
                        Text(L("template_empty_hint"))
                            .font(AppTypography.caption)
                            .foregroundColor(AppColors.textTertiary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AppSpacing.xl)
                }
            } else {
                Section {
                    ForEach(viewModel.items) { item in
                        templateRow(item)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                useTemplate(item.template)
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button(role: .destructive) {
                                    deleteTemplateId = item.id
                                } label: {
                                    Label(L("action_delete"), systemImage: "trash")
                                }
                            }
                    }
                } header: {
                    Text(L("template_list_section"))
                }
            }
        }
        .navigationTitle(L("template_title"))
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showAddTemplate = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .onAppear { viewModel.loadData() }
        .sheet(isPresented: $showAddTemplate) {
            AddTemplateSheet(
                categoryRepository: categoryRepository,
                settingsRepository: settingsRepository,
                onSave: { title, amount, type, categoryId, note in
                    viewModel.addTemplate(title: title, amount: amount, type: type, categoryId: categoryId, note: note)
                    showAddTemplate = false
                },
                onCancel: { showAddTemplate = false }
            )
            .presentationDetents([.large])
        }
        .alert(L("template_delete_title"), isPresented: Binding(
            get: { deleteTemplateId != nil },
            set: { if !$0 { deleteTemplateId = nil } }
        )) {
            Button(L("action_cancel"), role: .cancel) { deleteTemplateId = nil }
            Button(L("action_delete"), role: .destructive) {
                if let id = deleteTemplateId {
                    viewModel.deleteTemplate(id: id)
                }
                deleteTemplateId = nil
            }
        } message: {
            Text(L("template_delete_message"))
        }
        .alert(L("error_title"), isPresented: Binding(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )) {
            Button(L("error_ok"), role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }

    @ViewBuilder
    private func templateRow(_ item: TemplateDisplayItem) -> some View {
        HStack(spacing: AppSpacing.sm) {
            if let category = item.category {
                CategoryIconView(iconName: category.iconName, colorHex: category.colorHex, size: 36, iconSize: 18)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(item.template.title)
                    .font(AppTypography.body)
                    .foregroundColor(AppColors.textPrimary)
                if let note = item.template.note, !note.isEmpty {
                    Text(note)
                        .font(AppTypography.caption)
                        .foregroundColor(AppColors.textTertiary)
                        .lineLimit(1)
                }
            }

            Spacer()

            Text(AmountFormatter.format(item.template.amount, currencyCode: viewModel.currencyCode))
                .font(AppTypography.body)
                .foregroundColor(item.template.type == TransactionType.expense.rawValue ? AppColors.expense : AppColors.income)
                .fontWeight(.medium)

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(AppColors.textTertiary)
        }
        .padding(.vertical, AppSpacing.xs)
    }

    private func useTemplate(_ template: TransactionTemplate) {
        let prefill = ReminderPrefill(
            amount: template.amount,
            type: template.type,
            categoryId: template.categoryId,
            note: template.note
        )
        onUseTemplate(prefill)
    }
}

// MARK: - 添加模板 Sheet
struct AddTemplateSheet: View {
    let categoryRepository: CategoryRepositoryProtocol
    let settingsRepository: SettingsRepositoryProtocol
    let onSave: (String, Int64, String, String, String?) -> Void
    let onCancel: () -> Void

    @State private var title = ""
    @State private var amountText = ""
    @State private var isExpense = true
    @State private var selectedCategory: Category?
    @State private var note = ""
    @State private var categories: [Category] = []
    @State private var currencySymbol = "¥"

    var body: some View {
        NavigationStack {
            Form {
                Section(L("template_name_section")) {
                    TextField(L("template_name_placeholder"), text: $title)
                }

                Section(L("template_type_section")) {
                    Picker(L("template_type"), selection: $isExpense) {
                        Text(L("type_expense")).tag(true)
                        Text(L("type_income")).tag(false)
                    }
                    .pickerStyle(.segmented)
                    .onChange(of: isExpense) { _, _ in
                        selectedCategory = nil
                        loadCategories()
                    }
                }

                Section(L("template_amount_section")) {
                    TextField(L("budget_amount_placeholder"), text: $amountText)
                        .keyboardType(.decimalPad)
                }

                Section(L("budget_select_category")) {
                    if categories.isEmpty {
                        Text(L("template_no_categories"))
                            .font(AppTypography.caption)
                            .foregroundColor(AppColors.textTertiary)
                    } else {
                        ForEach(categories) { category in
                            Button {
                                selectedCategory = category
                            } label: {
                                HStack(spacing: AppSpacing.sm) {
                                    CategoryIconView(iconName: category.iconName, colorHex: category.colorHex, size: 32)
                                    Text(category.isCustom ? category.nameKey : L(category.nameKey))
                                        .foregroundColor(AppColors.textPrimary)
                                    Spacer()
                                    if selectedCategory?.id == category.id {
                                        Image(systemName: "checkmark")
                                            .foregroundColor(AppColors.primary)
                                    }
                                }
                            }
                        }
                    }
                }

                Section(L("template_note_section")) {
                    TextField(L("record_note_placeholder"), text: $note)
                }
            }
            .navigationTitle(L("template_add"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L("action_cancel")) { onCancel() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(L("budget_save")) {
                        guard let cat = selectedCategory,
                              let value = Double(amountText), value > 0 else { return }
                        let type = isExpense ? TransactionType.expense.rawValue : TransactionType.income.rawValue
                        let noteText = note.trimmingCharacters(in: .whitespacesAndNewlines)
                        onSave(title, Int64(round(value * 100)), type, cat.id, noteText.isEmpty ? nil : noteText)
                    }
                    .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty || selectedCategory == nil || Double(amountText) == nil)
                }
            }
            .onAppear {
                loadCategories()
                loadCurrency()
            }
        }
    }

    private func loadCategories() {
        do {
            if isExpense {
                categories = try categoryRepository.getExpenseCategories(sortedByUsage: true)
            } else {
                categories = try categoryRepository.getIncomeCategories(sortedByUsage: true)
            }
        } catch {
            categories = []
        }
    }

    private func loadCurrency() {
        do {
            let code = try settingsRepository.getCurrency()
            let locale = Locale(identifier: Locale.identifier(fromComponents: [NSLocale.Key.currencyCode.rawValue: code]))
            currencySymbol = locale.currencySymbol ?? "¥"
        } catch {
            currencySymbol = "¥"
        }
    }
}
