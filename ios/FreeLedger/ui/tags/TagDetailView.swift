import SwiftUI

struct TagDetailView: View {
    @State private var viewModel: TagDetailViewModel

    let tagRepository: TagRepositoryProtocol
    let transactionRepository: TransactionRepositoryProtocol
    let categoryRepository: CategoryRepositoryProtocol
    let settingsRepository: SettingsRepositoryProtocol

    init(tag: Tag,
         tagRepository: TagRepositoryProtocol,
         transactionRepository: TransactionRepositoryProtocol,
         categoryRepository: CategoryRepositoryProtocol,
         settingsRepository: SettingsRepositoryProtocol) {
        self.tagRepository = tagRepository
        self.transactionRepository = transactionRepository
        self.categoryRepository = categoryRepository
        self.settingsRepository = settingsRepository
        _viewModel = State(initialValue: TagDetailViewModel(
            tag: tag,
            tagRepository: tagRepository,
            categoryRepository: categoryRepository,
            settingsRepository: settingsRepository
        ))
    }

    var body: some View {
        List {
            Section {
                summaryCard
                    .listRowInsets(EdgeInsets(top: AppSpacing.md, leading: AppSpacing.lg, bottom: 0, trailing: AppSpacing.lg))
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
            }

            ForEach(viewModel.groupedTransactions, id: \.0) { group in
                Section {
                    ForEach(group.1) { transaction in
                        NavigationLink(value: transaction) {
                            TransactionCard(
                                transaction: transaction,
                                category: viewModel.categoryDict[transaction.categoryId],
                                currencyCode: viewModel.currencyCode
                            )
                        }
                        .listRowInsets(EdgeInsets(top: 0, leading: AppSpacing.lg, bottom: 0, trailing: AppSpacing.lg))
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                    }
                } header: {
                    Text(group.0)
                        .font(AppTypography.caption)
                        .foregroundColor(AppColors.textTertiary)
                        .textCase(nil)
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(AppColors.background)
        .navigationTitle(viewModel.tag.name)
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(for: Transaction.self) { transaction in
            TransactionDetailView(
                transaction: transaction,
                category: viewModel.categoryDict[transaction.categoryId],
                transactionRepository: transactionRepository,
                categoryRepository: categoryRepository,
                settingsRepository: settingsRepository,
                tagRepository: tagRepository
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

    private var summaryCard: some View {
        HStack(spacing: AppSpacing.xl) {
            VStack(spacing: AppSpacing.xs) {
                Text(L("tag_total_expense"))
                    .font(AppTypography.caption)
                    .foregroundColor(AppColors.textSecondary)
                Text(AmountFormatter.format(viewModel.totalExpense, currencyCode: viewModel.currencyCode))
                    .font(AppTypography.title2)
                    .foregroundColor(AppColors.expense)
                    .fontWeight(.semibold)
            }

            Spacer()

            VStack(spacing: AppSpacing.xs) {
                Text(L("tag_total_income"))
                    .font(AppTypography.caption)
                    .foregroundColor(AppColors.textSecondary)
                Text(AmountFormatter.format(viewModel.totalIncome, currencyCode: viewModel.currencyCode))
                    .font(AppTypography.title2)
                    .foregroundColor(AppColors.income)
                    .fontWeight(.semibold)
            }
        }
        .padding(AppSpacing.lg)
        .background(AppColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
    }
}
