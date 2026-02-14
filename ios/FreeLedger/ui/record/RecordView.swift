import SwiftUI

struct RecordView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: RecordViewModel
    @State private var selectedCategory: Category?
    @State private var selectedTagIds: Set<String> = []
    @State private var showTagSelector: Bool = false

    let tagRepository: TagRepositoryProtocol

    init(transactionRepository: TransactionRepositoryProtocol,
         categoryRepository: CategoryRepositoryProtocol,
         settingsRepository: SettingsRepositoryProtocol,
         tagRepository: TagRepositoryProtocol) {
        self.tagRepository = tagRepository
        _viewModel = State(initialValue: RecordViewModel(
            transactionRepository: transactionRepository,
            categoryRepository: categoryRepository,
            settingsRepository: settingsRepository
        ))
    }

    private var canSave: Bool {
        viewModel.canSave && selectedCategory != nil
    }

    var body: some View {
        VStack(spacing: 0) {
            headerSection
            Divider().background(AppColors.divider)
            categorySection
            Divider().background(AppColors.divider)
            keypadAndSaveSection
        }
        .background(AppColors.background)
        .onAppear {
            viewModel.loadCurrency()
            viewModel.loadCategories()
        }
        .onChange(of: viewModel.didSave) { _, didSave in
            if didSave {
                dismiss()
            }
        }
        .alert(String(localized: "error_title"), isPresented: Binding(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )) {
            Button(String(localized: "error_ok"), role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
        .sheet(isPresented: $showTagSelector) {
            TagSelector(
                tagRepository: tagRepository,
                selectedTagIds: $selectedTagIds,
                onDismiss: { showTagSelector = false }
            )
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
        }
    }

    private var headerSection: some View {
        VStack(spacing: AppSpacing.md) {
            HStack {
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(AppColors.textSecondary)
                }
                .accessibilityLabel(String(localized: "a11y_close"))

                Spacer()

                Text(String(localized: "record_title"))
                    .font(AppTypography.title2)
                    .foregroundColor(AppColors.textPrimary)

                Spacer()

                Color.clear.frame(width: 18, height: 18)
            }
            .padding(.horizontal, AppSpacing.xl)
            .padding(.top, AppSpacing.lg)

            Text(viewModel.displayAmount)
                .font(AppTypography.display)
                .foregroundColor(AppColors.textPrimary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, AppSpacing.sm)

            typeToggle

            noteSection
        }
        .padding(.bottom, AppSpacing.md)
    }

    private var typeToggle: some View {
        HStack(spacing: AppSpacing.xl) {
            Button(action: {
                if !viewModel.isExpense { viewModel.toggleType() }
            }) {
                Text(String(localized: "record_expense"))
                    .font(AppTypography.bodyLarge)
                    .foregroundColor(viewModel.isExpense ? AppColors.primary : AppColors.textTertiary)
                    .fontWeight(viewModel.isExpense ? .semibold : .regular)
            }
            .accessibilityLabel(String(localized: "a11y_expense_tab"))

            Button(action: {
                if viewModel.isExpense { viewModel.toggleType() }
            }) {
                Text(String(localized: "record_income"))
                    .font(AppTypography.bodyLarge)
                    .foregroundColor(!viewModel.isExpense ? AppColors.secondary : AppColors.textTertiary)
                    .fontWeight(!viewModel.isExpense ? .semibold : .regular)
            }
            .accessibilityLabel(String(localized: "a11y_income_tab"))
        }
    }

    private var noteSection: some View {
        Group {
            if viewModel.isNoteExpanded {
                TextField(String(localized: "record_note_placeholder"), text: $viewModel.note)
                    .font(AppTypography.body)
                    .foregroundColor(AppColors.textPrimary)
                    .padding(.horizontal, AppSpacing.xl)
                    .padding(.vertical, AppSpacing.sm)
                    .accessibilityLabel(String(localized: "a11y_note_input"))
            } else {
                Button(action: {
                    withAnimation(.easeOut(duration: 0.2)) {
                        viewModel.isNoteExpanded = true
                    }
                }) {
                    Text(String(localized: "record_add_note"))
                        .font(AppTypography.body)
                        .foregroundColor(AppColors.textTertiary)
                }
                .padding(.horizontal, AppSpacing.xl)
                .accessibilityLabel(String(localized: "a11y_add_note"))
            }
        }
    }

    private var categorySection: some View {
        CategoryGrid(
            categories: viewModel.categories,
            selectedId: selectedCategory?.id
        ) { category in
            selectedCategory = category
        }
        .frame(height: 200)
        .padding(.vertical, AppSpacing.md)
    }

    private var keypadAndSaveSection: some View {
        VStack(spacing: 0) {
            AmountKeypad(amountString: $viewModel.amountString, onTagTap: {
                showTagSelector = true
            })

            Button(action: {
                guard let cat = selectedCategory else { return }
                viewModel.saveTransaction(categoryId: cat.id, tagIds: Array(selectedTagIds))
            }) {
                Text(String(localized: "record_save"))
                    .font(AppTypography.bodyLarge)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(canSave ? AppColors.primary : AppColors.textTertiary)
                    .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
            }
            .disabled(!canSave)
            .padding(.horizontal, AppSpacing.lg)
            .padding(.bottom, AppSpacing.lg)
            .accessibilityLabel(String(localized: "a11y_save_transaction"))
        }
    }
}
