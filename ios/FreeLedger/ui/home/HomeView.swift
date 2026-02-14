import SwiftUI

struct HomeView: View {
    @State private var viewModel: HomeViewModel
    @State private var deleteTarget: Transaction?
    @State private var showDeleteDialog: Bool = false
    @State private var showSearch: Bool = false
    @State private var errorMessage: String?

    let transactionRepository: TransactionRepositoryProtocol
    let categoryRepository: CategoryRepositoryProtocol
    let settingsRepository: SettingsRepositoryProtocol
    let tagRepository: TagRepositoryProtocol

    init(viewModel: HomeViewModel,
         transactionRepository: TransactionRepositoryProtocol,
         categoryRepository: CategoryRepositoryProtocol,
         settingsRepository: SettingsRepositoryProtocol,
         tagRepository: TagRepositoryProtocol) {
        _viewModel = State(initialValue: viewModel)
        self.transactionRepository = transactionRepository
        self.categoryRepository = categoryRepository
        self.settingsRepository = settingsRepository
        self.tagRepository = tagRepository
    }

    var body: some View {
        NavigationStack {
            ZStack {
                List {
                    Section {
                        SummaryCard(
                            summary: viewModel.summary,
                            currencyCode: viewModel.currencyCode,
                            monthTitle: viewModel.monthTitle
                        )
                        .listRowInsets(EdgeInsets(top: AppSpacing.lg, leading: AppSpacing.lg, bottom: 0, trailing: AppSpacing.lg))
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                    }

                    if viewModel.isEmpty {
                        Section {
                            emptyStateView
                                .listRowSeparator(.hidden)
                                .listRowBackground(Color.clear)
                        }
                    } else {
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
                                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                        Button(role: .destructive) {
                                            deleteTarget = transaction
                                            withAnimation(.easeInOut(duration: 0.25)) {
                                                showDeleteDialog = true
                                            }
                                        } label: {
                                            Label(String(localized: "action_delete"), systemImage: "trash")
                                        }
                                    }
                                }
                            } header: {
                                Text(group.0)
                                    .font(AppTypography.caption)
                                    .foregroundColor(AppColors.textTertiary)
                                    .textCase(nil)
                            }
                        }
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .background(AppColors.background)
                .contentMargins(.bottom, 100, for: .scrollContent)
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

                if showDeleteDialog {
                    FriendlyDialog(
                        title: String(localized: "delete_confirm_title"),
                        message: String(localized: "delete_confirm_message"),
                        style: .destructive,
                        confirmTitle: String(localized: "action_delete"),
                        cancelTitle: String(localized: "action_cancel"),
                        onConfirm: {
                            if let tx = deleteTarget {
                                do {
                                    try transactionRepository.delete(id: tx.id)
                                    viewModel.loadData()
                                } catch {
                                    errorMessage = String(localized: "error_delete_failed")
                                }
                            }
                            withAnimation(.easeInOut(duration: 0.2)) {
                                showDeleteDialog = false
                            }
                            deleteTarget = nil
                        },
                        onCancel: {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                showDeleteDialog = false
                            }
                            deleteTarget = nil
                        }
                    )
                }
            }
            .navigationTitle(String(localized: "tab_transactions"))
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showSearch = true
                    } label: {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(AppColors.textPrimary)
                    }
                    .accessibilityLabel(String(localized: "search_title"))
                }
            }
            .sheet(isPresented: $showSearch) {
                SearchView(
                    transactionRepository: transactionRepository,
                    categoryRepository: categoryRepository,
                    settingsRepository: settingsRepository,
                    tagRepository: tagRepository
                )
            }
            .onAppear {
                viewModel.loadData()
            }
            .alert(String(localized: "error_title"), isPresented: Binding(
                get: { errorMessage != nil },
                set: { if !$0 { errorMessage = nil } }
            )) {
                Button(String(localized: "error_ok"), role: .cancel) {}
            } message: {
                Text(errorMessage ?? "")
            }
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: AppSpacing.lg) {
            Image(systemName: "tray")
                .font(.system(size: 48))
                .foregroundColor(AppColors.textTertiary)

            Text(String(localized: "home_empty_state"))
                .font(AppTypography.body)
                .foregroundColor(AppColors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, minHeight: 200)
        .padding(.top, AppSpacing.xxl)
    }
}
