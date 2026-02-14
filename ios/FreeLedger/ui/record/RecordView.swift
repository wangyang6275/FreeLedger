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

    private var typeColor: Color {
        viewModel.isExpense ? AppColors.expense : AppColors.income
    }

    var body: some View {
        VStack(spacing: 0) {
            headerSection
            categorySection
                .frame(maxHeight: .infinity)
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

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: AppSpacing.lg) {
            // Top bar
            HStack {
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 28))
                        .symbolRenderingMode(.hierarchical)
                        .foregroundColor(AppColors.textTertiary)
                }
                .accessibilityLabel(String(localized: "a11y_close"))

                Spacer()

                typeToggle

                Spacer()

                Button(action: { showTagSelector = true }) {
                    Image(systemName: "tag")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(selectedTagIds.isEmpty ? AppColors.textTertiary : AppColors.primary)
                        .padding(8)
                        .background(
                            Circle()
                                .fill(selectedTagIds.isEmpty ? AppColors.surface : AppColors.primaryLight)
                        )
                }
                .accessibilityLabel(String(localized: "a11y_tag_button"))
            }
            .padding(.horizontal, AppSpacing.xl)
            .padding(.top, AppSpacing.md)

            // Amount display
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(viewModel.currencySymbol)
                    .font(.system(size: 24, weight: .medium, design: .rounded))
                    .foregroundColor(typeColor.opacity(0.6))

                Text(viewModel.amountString.isEmpty ? "0" : viewModel.amountString)
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundColor(viewModel.amountString.isEmpty ? AppColors.textTertiary : typeColor)
                    .contentTransition(.numericText())
                    .animation(.snappy(duration: 0.15), value: viewModel.amountString)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, AppSpacing.xs)

            // Note field
            noteField
        }
        .padding(.bottom, AppSpacing.md)
    }

    // MARK: - Type Toggle

    private var typeToggle: some View {
        HStack(spacing: 0) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    if !viewModel.isExpense { viewModel.toggleType(); selectedCategory = nil }
                }
            } label: {
                Text(String(localized: "record_expense"))
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(viewModel.isExpense ? .white : AppColors.textSecondary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 7)
                    .background(
                        Capsule()
                            .fill(viewModel.isExpense ? AppColors.expense : Color.clear)
                    )
            }
            .accessibilityLabel(String(localized: "a11y_expense_tab"))

            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    if viewModel.isExpense { viewModel.toggleType(); selectedCategory = nil }
                }
            } label: {
                Text(String(localized: "record_income"))
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(!viewModel.isExpense ? .white : AppColors.textSecondary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 7)
                    .background(
                        Capsule()
                            .fill(!viewModel.isExpense ? AppColors.income : Color.clear)
                    )
            }
            .accessibilityLabel(String(localized: "a11y_income_tab"))
        }
        .padding(3)
        .background(
            Capsule().fill(AppColors.surface)
        )
    }

    // MARK: - Note

    private var noteField: some View {
        HStack(spacing: AppSpacing.sm) {
            Image(systemName: "pencil.line")
                .font(.system(size: 14))
                .foregroundColor(AppColors.textTertiary)

            TextField(String(localized: "record_note_placeholder"), text: $viewModel.note)
                .font(AppTypography.body)
                .foregroundColor(AppColors.textPrimary)
                .accessibilityLabel(String(localized: "a11y_note_input"))
        }
        .padding(.horizontal, AppSpacing.lg)
        .padding(.vertical, 10)
        .background(AppColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
        .padding(.horizontal, AppSpacing.xl)
    }

    // MARK: - Category

    private var categorySection: some View {
        CategoryGrid(
            categories: viewModel.categories,
            selectedId: selectedCategory?.id
        ) { category in
            withAnimation(.easeInOut(duration: 0.15)) {
                selectedCategory = category
            }
        }
        .padding(.vertical, AppSpacing.xs)
    }

    // MARK: - Keypad + Save

    private var keypadAndSaveSection: some View {
        VStack(spacing: AppSpacing.sm) {
            AmountKeypad(amountString: $viewModel.amountString, onTagTap: {
                showTagSelector = true
            })

            Button(action: {
                let impact = UIImpactFeedbackGenerator(style: .medium)
                impact.impactOccurred()
                guard let cat = selectedCategory else { return }
                viewModel.saveTransaction(categoryId: cat.id, tagIds: Array(selectedTagIds))
            }) {
                HStack(spacing: AppSpacing.sm) {
                    Image(systemName: "checkmark")
                        .font(.system(size: 16, weight: .bold))
                    Text(String(localized: "record_save"))
                        .font(AppTypography.bodyLarge)
                        .fontWeight(.semibold)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 46)
                .background(
                    canSave
                        ? AnyShapeStyle(typeColor.gradient)
                        : AnyShapeStyle(AppColors.divider)
                )
                .clipShape(RoundedRectangle(cornerRadius: AppRadius.lg))
                .shadow(color: canSave ? typeColor.opacity(0.3) : .clear, radius: 8, y: 4)
            }
            .disabled(!canSave)
            .padding(.horizontal, AppSpacing.md)
            .padding(.bottom, AppSpacing.md)
            .animation(.easeInOut(duration: 0.2), value: canSave)
            .accessibilityLabel(String(localized: "a11y_save_transaction"))
        }
    }
}
