import SwiftUI

struct BudgetView: View {
    @State private var viewModel: BudgetViewModel
    @State private var showSetOverall = false
    @State private var showAddCategory = false
    @State private var editingAmount = ""
    @State private var selectedCategoryId: String?
    @State private var showDeleteOverall = false
    @State private var deleteCategoryBudgetId: String?

    let categoryRepository: CategoryRepositoryProtocol

    init(budgetRepository: BudgetRepositoryProtocol,
         transactionRepository: TransactionRepositoryProtocol,
         categoryRepository: CategoryRepositoryProtocol,
         settingsRepository: SettingsRepositoryProtocol) {
        _viewModel = State(initialValue: BudgetViewModel(
            budgetRepository: budgetRepository,
            transactionRepository: transactionRepository,
            categoryRepository: categoryRepository,
            settingsRepository: settingsRepository
        ))
        self.categoryRepository = categoryRepository
    }

    var body: some View {
        List {
            // MARK: - 总预算
            Section {
                if let budget = viewModel.overallBudget {
                    overallBudgetCard(budget)
                } else {
                    Button {
                        editingAmount = ""
                        showSetOverall = true
                    } label: {
                        Label(L("budget_set_overall"), systemImage: "plus.circle")
                            .foregroundColor(AppColors.primary)
                    }
                }
            } header: {
                Text(L("budget_overall_section"))
            }

            // MARK: - 分类预算
            Section {
                if viewModel.categoryBudgetItems.isEmpty {
                    Text(L("budget_category_empty"))
                        .font(AppTypography.caption)
                        .foregroundColor(AppColors.textTertiary)
                } else {
                    ForEach(viewModel.categoryBudgetItems) { item in
                        categoryBudgetRow(item)
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button(role: .destructive) {
                                    deleteCategoryBudgetId = item.id
                                } label: {
                                    Label(L("action_delete"), systemImage: "trash")
                                }
                            }
                    }
                }

                Button {
                    editingAmount = ""
                    selectedCategoryId = nil
                    showAddCategory = true
                } label: {
                    Label(L("budget_add_category"), systemImage: "plus.circle")
                        .foregroundColor(AppColors.primary)
                }
            } header: {
                Text(L("budget_category_section"))
            }
        }
        .navigationTitle(L("budget_title"))
        .onAppear { viewModel.loadData() }
        .alert(L("budget_set_overall"), isPresented: $showSetOverall) {
            TextField(L("budget_amount_placeholder"), text: $editingAmount)
                .keyboardType(.decimalPad)
            Button(L("action_cancel"), role: .cancel) {}
            Button(L("budget_save")) {
                if let cents = parseCents(editingAmount) {
                    viewModel.setOverallBudget(amount: cents)
                }
            }
        } message: {
            Text(L("budget_set_overall_message"))
        }
        .alert(L("budget_delete_title"), isPresented: $showDeleteOverall) {
            Button(L("action_cancel"), role: .cancel) {}
            Button(L("action_delete"), role: .destructive) {
                viewModel.deleteOverallBudget()
            }
        } message: {
            Text(L("budget_delete_overall_message"))
        }
        .sheet(isPresented: $showAddCategory) {
            AddCategoryBudgetSheet(
                categories: viewModel.availableCategories(),
                currencyCode: viewModel.currencyCode,
                onSave: { categoryId, amount in
                    viewModel.setCategoryBudget(categoryId: categoryId, amount: amount)
                    showAddCategory = false
                },
                onCancel: { showAddCategory = false }
            )
            .presentationDetents([.medium])
        }
        .alert(L("budget_delete_title"), isPresented: Binding(
            get: { deleteCategoryBudgetId != nil },
            set: { if !$0 { deleteCategoryBudgetId = nil } }
        )) {
            Button(L("action_cancel"), role: .cancel) { deleteCategoryBudgetId = nil }
            Button(L("action_delete"), role: .destructive) {
                if let id = deleteCategoryBudgetId {
                    viewModel.deleteCategoryBudget(id: id)
                }
                deleteCategoryBudgetId = nil
            }
        } message: {
            Text(L("budget_delete_category_message"))
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

    // MARK: - 总预算卡片
    @ViewBuilder
    private func overallBudgetCard(_ budget: Budget) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            HStack {
                Text(L("budget_monthly_limit"))
                    .font(AppTypography.body)
                    .foregroundColor(AppColors.textPrimary)
                Spacer()
                Button {
                    editingAmount = String(format: "%.2f", Double(budget.amount) / 100.0)
                    showSetOverall = true
                } label: {
                    Image(systemName: "pencil")
                        .foregroundColor(AppColors.textSecondary)
                }
                Button {
                    showDeleteOverall = true
                } label: {
                    Image(systemName: "trash")
                        .foregroundColor(AppColors.error)
                }
            }

            Text(AmountFormatter.format(budget.amount, currencyCode: viewModel.currencyCode))
                .font(AppTypography.title1)
                .foregroundColor(AppColors.textPrimary)
                .fontWeight(.bold)

            BudgetProgressBar(
                spent: viewModel.overallSpent,
                total: budget.amount,
                currencyCode: viewModel.currencyCode
            )
        }
        .padding(.vertical, AppSpacing.xs)
    }

    // MARK: - 分类预算行
    @ViewBuilder
    private func categoryBudgetRow(_ item: CategoryBudgetItem) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            HStack(spacing: AppSpacing.sm) {
                CategoryIconView(iconName: item.category.iconName, colorHex: item.category.colorHex, size: 32)

                VStack(alignment: .leading, spacing: 2) {
                    Text(item.category.isCustom ? item.category.nameKey : L(item.category.nameKey))
                        .font(AppTypography.body)
                        .foregroundColor(AppColors.textPrimary)
                    Text(AmountFormatter.format(item.budget.amount, currencyCode: viewModel.currencyCode))
                        .font(AppTypography.caption)
                        .foregroundColor(AppColors.textSecondary)
                }

                Spacer()

                Text(AmountFormatter.format(item.spent, currencyCode: viewModel.currencyCode))
                    .font(AppTypography.body)
                    .foregroundColor(item.isOverBudget ? AppColors.error : AppColors.textPrimary)
                    .fontWeight(.medium)
            }

            BudgetProgressBar(
                spent: item.spent,
                total: item.budget.amount,
                currencyCode: viewModel.currencyCode
            )
        }
        .padding(.vertical, AppSpacing.xs)
    }

    private func parseCents(_ text: String) -> Int64? {
        guard let value = Double(text), value > 0 else { return nil }
        return Int64(round(value * 100))
    }
}

// MARK: - 预算进度条
struct BudgetProgressBar: View {
    let spent: Int64
    let total: Int64
    let currencyCode: String

    private var percentage: Double {
        total > 0 ? Double(spent) / Double(total) : 0
    }

    private var isOver: Bool { spent > total }

    var body: some View {
        VStack(spacing: 4) {
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(AppColors.divider)
                        .frame(height: 8)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(progressColor)
                        .frame(width: geo.size.width * min(percentage, 1.0), height: 8)
                }
            }
            .frame(height: 8)

            HStack {
                Text(L("budget_spent"))
                    .font(AppTypography.caption)
                    .foregroundColor(AppColors.textTertiary)
                Spacer()
                if isOver {
                    Text(L("budget_over %@", AmountFormatter.format(spent - total, currencyCode: currencyCode)))
                        .font(AppTypography.caption)
                        .foregroundColor(AppColors.error)
                } else {
                    Text(L("budget_remaining %@", AmountFormatter.format(total - spent, currencyCode: currencyCode)))
                        .font(AppTypography.caption)
                        .foregroundColor(AppColors.success)
                }
            }
        }
    }

    private var progressColor: Color {
        if percentage > 1.0 { return AppColors.error }
        if percentage > 0.8 { return AppColors.warning }
        return AppColors.primary
    }
}

// MARK: - 添加分类预算 Sheet
struct AddCategoryBudgetSheet: View {
    let categories: [Category]
    let currencyCode: String
    let onSave: (String, Int64) -> Void
    let onCancel: () -> Void

    @State private var selectedCategoryId: String?
    @State private var amountText = ""

    var body: some View {
        NavigationStack {
            Form {
                Section(L("budget_select_category")) {
                    if categories.isEmpty {
                        Text(L("budget_all_categories_set"))
                            .font(AppTypography.caption)
                            .foregroundColor(AppColors.textTertiary)
                    } else {
                        ForEach(categories) { category in
                            Button {
                                selectedCategoryId = category.id
                            } label: {
                                HStack(spacing: AppSpacing.sm) {
                                    CategoryIconView(iconName: category.iconName, colorHex: category.colorHex, size: 32)
                                    Text(category.isCustom ? category.nameKey : L(category.nameKey))
                                        .foregroundColor(AppColors.textPrimary)
                                    Spacer()
                                    if selectedCategoryId == category.id {
                                        Image(systemName: "checkmark")
                                            .foregroundColor(AppColors.primary)
                                    }
                                }
                            }
                        }
                    }
                }

                Section(L("budget_amount_section")) {
                    TextField(L("budget_amount_placeholder"), text: $amountText)
                        .keyboardType(.decimalPad)
                }
            }
            .navigationTitle(L("budget_add_category"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L("action_cancel")) { onCancel() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(L("budget_save")) {
                        guard let catId = selectedCategoryId,
                              let value = Double(amountText), value > 0 else { return }
                        onSave(catId, Int64(round(value * 100)))
                    }
                    .disabled(selectedCategoryId == nil || Double(amountText) == nil)
                }
            }
        }
    }
}
