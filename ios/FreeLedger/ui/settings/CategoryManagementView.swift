import SwiftUI

struct CategoryManagementView: View {
    @State private var viewModel: CategoryManagementViewModel
    @State private var showAddCategory = false

    let categoryRepository: CategoryRepositoryProtocol

    init(categoryRepository: CategoryRepositoryProtocol) {
        self.categoryRepository = categoryRepository
        _viewModel = State(initialValue: CategoryManagementViewModel(categoryRepository: categoryRepository))
    }

    var body: some View {
        ZStack {
            mainContent
            deleteDialogOverlay
        }
        .navigationTitle(L("settings_category_management"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { addButton }
        .navigationDestination(for: Category.self) { category in
            CategoryEditView(
                category: category,
                isExpense: category.type == TransactionType.expense.rawValue,
                categoryRepository: categoryRepository,
                onSave: { viewModel.loadData() }
            )
        }
        .navigationDestination(isPresented: $showAddCategory) {
            CategoryEditView(
                category: nil,
                isExpense: viewModel.isExpenseTab,
                categoryRepository: categoryRepository,
                onSave: { viewModel.loadData() }
            )
        }
        .onAppear {
            viewModel.loadData()
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

    // MARK: - Subviews

    private var mainContent: some View {
        VStack(spacing: 0) {
            tabPicker
            categoryList
        }
        .background(GlassPageBackground())
    }

    private var tabPicker: some View {
        Picker("", selection: $viewModel.isExpenseTab) {
            Text(L("record_expense")).tag(true)
            Text(L("record_income")).tag(false)
        }
        .pickerStyle(.segmented)
        .padding(.horizontal, AppSpacing.lg)
        .padding(.vertical, AppSpacing.md)
    }

    private var categoryList: some View {
        List {
            ForEach(viewModel.currentCategories) { category in
                categoryListRowWithSwipe(category)
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }

    @ViewBuilder
    private func categoryListRow(_ category: Category) -> some View {
        if category.isCustom {
            NavigationLink(value: category) {
                categoryRowContent(category)
            }
        } else {
            categoryRowContent(category)
        }
    }

    private func categoryListRowWithSwipe(_ category: Category) -> some View {
        categoryListRow(category)
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            if category.isCustom {
                Button(role: .destructive) {
                    viewModel.deleteTarget = category
                    withAnimation(.easeInOut(duration: 0.25)) {
                        viewModel.showDeleteDialog = true
                    }
                } label: {
                    Label(L("action_delete"), systemImage: "trash")
                }
            }
        }
    }

    private func categoryRowContent(_ category: Category) -> some View {
        HStack(spacing: AppSpacing.md) {
            CategoryIconView(
                iconName: category.iconName,
                colorHex: category.colorHex
            )

            Text(viewModel.categoryDisplayName(category))
                .font(AppTypography.body)
                .foregroundColor(AppColors.textPrimary)

            Spacer()

            Text(category.isCustom
                 ? L("category_custom_label")
                 : L("category_builtin_label"))
                .font(AppTypography.caption)
                .foregroundColor(AppColors.textTertiary)
        }
        .padding(.vertical, AppSpacing.xs)
    }

    @ViewBuilder
    private var deleteDialogOverlay: some View {
        if viewModel.showDeleteDialog {
            FriendlyDialog(
                title: L("delete_category_title"),
                message: L("delete_category_message"),
                style: .destructive,
                confirmTitle: L("action_delete"),
                cancelTitle: L("action_cancel"),
                onConfirm: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        viewModel.showDeleteDialog = false
                    }
                    viewModel.deactivateCategory()
                },
                onCancel: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        viewModel.showDeleteDialog = false
                    }
                    viewModel.deleteTarget = nil
                }
            )
        }
    }

    private var addButton: some ToolbarContent {
        ToolbarItem(placement: .navigationBarTrailing) {
            Button {
                showAddCategory = true
            } label: {
                Image(systemName: "plus")
            }
        }
    }
}
