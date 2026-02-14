import SwiftUI

struct TransactionDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: TransactionDetailViewModel
    @State private var showCategorySheet: Bool = false
    @State private var showTagSheet: Bool = false

    init(transaction: Transaction,
         category: Category?,
         transactionRepository: TransactionRepositoryProtocol,
         categoryRepository: CategoryRepositoryProtocol,
         settingsRepository: SettingsRepositoryProtocol,
         tagRepository: TagRepositoryProtocol) {
        _viewModel = State(initialValue: TransactionDetailViewModel(
            transaction: transaction,
            category: category,
            transactionRepository: transactionRepository,
            categoryRepository: categoryRepository,
            settingsRepository: settingsRepository,
            tagRepository: tagRepository
        ))
    }

    var body: some View {
        ZStack {
            ScrollView {
                VStack(spacing: AppSpacing.xl) {
                    headerSection
                    infoSection
                    tagSection

                    if !viewModel.isEditing {
                        deleteButton
                    }
                }
                .padding(.horizontal, AppSpacing.lg)
                .padding(.top, AppSpacing.xl)
                .padding(.bottom, 100)
            }
            .background(AppColors.background)

            if viewModel.showDeleteDialog {
                FriendlyDialog(
                    title: String(localized: "delete_confirm_title"),
                    message: String(localized: "delete_confirm_message"),
                    style: .destructive,
                    confirmTitle: String(localized: "action_delete"),
                    cancelTitle: String(localized: "action_cancel"),
                    onConfirm: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            viewModel.showDeleteDialog = false
                        }
                        viewModel.deleteTransaction()
                    },
                    onCancel: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            viewModel.showDeleteDialog = false
                        }
                    }
                )
            }
        }
        .navigationTitle(String(localized: "detail_title"))
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(viewModel.isEditing)
        .toolbar {
            if viewModel.isEditing {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(String(localized: "action_cancel")) {
                        viewModel.cancelEditing()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(String(localized: "record_save")) {
                        viewModel.saveEdit()
                    }
                    .fontWeight(.semibold)
                }
            } else {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(String(localized: "action_edit")) {
                        viewModel.startEditing()
                    }
                }
            }
        }
        .onAppear {
            viewModel.loadData()
        }
        .onChange(of: viewModel.didDelete) { _, deleted in
            if deleted { dismiss() }
        }
        .alert(String(localized: "error_title"), isPresented: Binding(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )) {
            Button(String(localized: "error_ok"), role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
        .sheet(isPresented: $showCategorySheet) {
            categoryPickerSheet
        }
        .sheet(isPresented: $showTagSheet) {
            TagSelector(
                tagRepository: viewModel.tagRepository,
                selectedTagIds: $viewModel.editTagIds,
                onDismiss: { showTagSheet = false }
            )
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
        }
    }

    // MARK: - Header

    private var editCategory: Category? {
        viewModel.allCategories.first(where: { $0.id == viewModel.editCategoryId })
    }

    private var headerSection: some View {
        VStack(spacing: AppSpacing.md) {
            CategoryIconView(
                iconName: (viewModel.isEditing ? editCategory?.iconName : viewModel.category?.iconName) ?? "",
                colorHex: (viewModel.isEditing ? editCategory?.colorHex : viewModel.category?.colorHex) ?? "#E0E0E0",
                size: 80,
                iconSize: 40
            )

            if viewModel.isEditing {
                editAmountSection
            } else {
                Text(viewModel.formattedAmount)
                    .font(AppTypography.display)
                    .foregroundColor(AppColors.textPrimary)
                    .fontWeight(.bold)
            }

            Text(viewModel.isEditing ? editCategoryName : viewModel.categoryName)
                .font(AppTypography.title2)
                .foregroundColor(AppColors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppSpacing.lg)
        .accessibilityElement(children: .combine)
    }

    // MARK: - Edit Amount

    private var editAmountSection: some View {
        VStack(spacing: AppSpacing.sm) {
            HStack(spacing: AppSpacing.xl) {
                Button(action: {
                    if !viewModel.editIsExpense { viewModel.toggleEditType() }
                }) {
                    Text(String(localized: "record_expense"))
                        .font(AppTypography.bodyLarge)
                        .foregroundColor(viewModel.editIsExpense ? AppColors.primary : AppColors.textTertiary)
                        .fontWeight(viewModel.editIsExpense ? .semibold : .regular)
                }
                Button(action: {
                    if viewModel.editIsExpense { viewModel.toggleEditType() }
                }) {
                    Text(String(localized: "record_income"))
                        .font(AppTypography.bodyLarge)
                        .foregroundColor(!viewModel.editIsExpense ? AppColors.secondary : AppColors.textTertiary)
                        .fontWeight(!viewModel.editIsExpense ? .semibold : .regular)
                }
            }

            TextField(String(localized: "edit_amount_placeholder"), text: $viewModel.editAmountString)
                .font(AppTypography.display)
                .foregroundColor(AppColors.textPrimary)
                .multilineTextAlignment(.center)
                .keyboardType(.decimalPad)
                .accessibilityLabel(String(localized: "a11y_edit_amount"))
        }
    }

    // MARK: - Info Section

    private var infoSection: some View {
        VStack(spacing: 0) {
            if viewModel.isEditing {
                editInfoRows
            } else {
                viewInfoRows
            }
        }
        .background(AppColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
    }

    private var viewInfoRows: some View {
        VStack(spacing: 0) {
            infoRow(
                label: String(localized: "detail_note"),
                value: viewModel.transaction.note ?? String(localized: "detail_no_note")
            )
            Divider().padding(.leading, AppSpacing.lg)
            infoRow(
                label: String(localized: "detail_date"),
                value: viewModel.formattedDate
            )
            Divider().padding(.leading, AppSpacing.lg)
            infoRow(
                label: String(localized: "detail_type"),
                value: viewModel.isExpense
                    ? String(localized: "record_expense")
                    : String(localized: "record_income")
            )
        }
    }

    private var editInfoRows: some View {
        VStack(spacing: 0) {
            // Category (tappable)
            Button(action: { showCategorySheet = true }) {
                HStack {
                    Text(String(localized: "detail_category"))
                        .font(AppTypography.body)
                        .foregroundColor(AppColors.textSecondary)
                    Spacer()
                    Text(editCategoryName)
                        .font(AppTypography.body)
                        .foregroundColor(AppColors.textPrimary)
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12))
                        .foregroundColor(AppColors.textTertiary)
                }
                .padding(.horizontal, AppSpacing.lg)
                .padding(.vertical, AppSpacing.md)
            }

            Divider().padding(.leading, AppSpacing.lg)

            // Note (editable)
            HStack {
                Text(String(localized: "detail_note"))
                    .font(AppTypography.body)
                    .foregroundColor(AppColors.textSecondary)
                Spacer()
                TextField(String(localized: "record_note_placeholder"), text: $viewModel.editNote)
                    .font(AppTypography.body)
                    .foregroundColor(AppColors.textPrimary)
                    .multilineTextAlignment(.trailing)
            }
            .padding(.horizontal, AppSpacing.lg)
            .padding(.vertical, AppSpacing.md)

            Divider().padding(.leading, AppSpacing.lg)

            infoRow(
                label: String(localized: "detail_date"),
                value: viewModel.formattedDate
            )
        }
    }

    private var editCategoryName: String {
        guard let cat = viewModel.allCategories.first(where: { $0.id == viewModel.editCategoryId }) else {
            return viewModel.categoryName
        }
        return String(localized: String.LocalizationValue(cat.nameKey))
    }

    private func infoRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(AppTypography.body)
                .foregroundColor(AppColors.textSecondary)
            Spacer()
            Text(value)
                .font(AppTypography.body)
                .foregroundColor(AppColors.textPrimary)
        }
        .padding(.horizontal, AppSpacing.lg)
        .padding(.vertical, AppSpacing.md)
        .accessibilityElement(children: .combine)
    }

    // MARK: - Tags

    @ViewBuilder
    private var tagSection: some View {
        if viewModel.isEditing {
            editTagSection
        } else if !viewModel.tags.isEmpty {
            viewTagSection
        }
    }

    private var viewTagSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text(String(localized: "detail_tags"))
                .font(AppTypography.caption)
                .foregroundColor(AppColors.textSecondary)

            FlowLayout(spacing: AppSpacing.xs) {
                ForEach(viewModel.tags) { tag in
                    Text(tag.name)
                        .font(AppTypography.caption)
                        .foregroundColor(.white)
                        .padding(.horizontal, AppSpacing.md)
                        .padding(.vertical, AppSpacing.xs)
                        .background(Color(hex: tag.colorHex))
                        .clipShape(Capsule())
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AppSpacing.lg)
        .background(AppColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
    }

    private var editTagSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Button(action: { showTagSheet = true }) {
                HStack {
                    Text(String(localized: "detail_tags"))
                        .font(AppTypography.body)
                        .foregroundColor(AppColors.textSecondary)
                    Spacer()
                    if viewModel.editTagIds.isEmpty {
                        Text(String(localized: "tag_add_hint"))
                            .font(AppTypography.body)
                            .foregroundColor(AppColors.textTertiary)
                    } else {
                        Text("\(viewModel.editTagIds.count)")
                            .font(AppTypography.body)
                            .foregroundColor(AppColors.textPrimary)
                    }
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12))
                        .foregroundColor(AppColors.textTertiary)
                }
            }
        }
        .padding(.horizontal, AppSpacing.lg)
        .padding(.vertical, AppSpacing.md)
        .background(AppColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
    }

    // MARK: - Delete

    private var deleteButton: some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.25)) {
                viewModel.showDeleteDialog = true
            }
        }) {
            Text(String(localized: "action_delete_record"))
                .font(AppTypography.body)
                .foregroundColor(AppColors.expense)
        }
        .padding(.top, AppSpacing.xl)
        .accessibilityLabel(String(localized: "a11y_delete_record"))
    }

    // MARK: - Category Picker Sheet

    private var categoryPickerSheet: some View {
        NavigationStack {
            CategoryGrid(
                categories: viewModel.allCategories,
                selectedId: viewModel.editCategoryId
            ) { category in
                viewModel.editCategoryId = category.id
                showCategorySheet = false
            }
            .padding(.top, AppSpacing.lg)
            .navigationTitle(String(localized: "edit_select_category"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(String(localized: "action_cancel")) {
                        showCategorySheet = false
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }
}
