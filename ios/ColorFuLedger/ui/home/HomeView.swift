import SwiftUI

struct HomeView: View {
    @State private var viewModel: HomeViewModel
    @State private var deleteTarget: Transaction?
    @State private var showDeleteDialog: Bool = false
    @State private var showSearch: Bool = false
    @State private var showReminders: Bool = false
    @State private var errorMessage: String?

    let transactionRepository: TransactionRepositoryProtocol
    let categoryRepository: CategoryRepositoryProtocol
    let settingsRepository: SettingsRepositoryProtocol
    let tagRepository: TagRepositoryProtocol
    let reminderRepository: ReminderRepositoryProtocol

    init(viewModel: HomeViewModel,
         transactionRepository: TransactionRepositoryProtocol,
         categoryRepository: CategoryRepositoryProtocol,
         settingsRepository: SettingsRepositoryProtocol,
         tagRepository: TagRepositoryProtocol,
         reminderRepository: ReminderRepositoryProtocol) {
        _viewModel = State(initialValue: viewModel)
        self.transactionRepository = transactionRepository
        self.categoryRepository = categoryRepository
        self.settingsRepository = settingsRepository
        self.tagRepository = tagRepository
        self.reminderRepository = reminderRepository
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

                        if viewModel.overallBudget != nil {
                            BudgetProgressCard(
                                overallBudget: viewModel.overallBudget,
                                spent: viewModel.summary.totalExpense,
                                currencyCode: viewModel.currencyCode
                            )
                            .listRowInsets(EdgeInsets(top: AppSpacing.sm, leading: AppSpacing.lg, bottom: 0, trailing: AppSpacing.lg))
                            .listRowSeparator(.hidden)
                            .listRowBackground(Color.clear)
                        }
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
                                    ZStack {
                                        NavigationLink(value: transaction) {
                                            EmptyView()
                                        }
                                        .opacity(0)
                                        
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
                                            Label(L("action_delete"), systemImage: "trash")
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
                .background(GlassPageBackground())
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
                        title: L("delete_confirm_title"),
                        message: L("delete_confirm_message"),
                        style: .destructive,
                        confirmTitle: L("action_delete"),
                        cancelTitle: L("action_cancel"),
                        onConfirm: {
                            if let tx = deleteTarget {
                                do {
                                    try transactionRepository.delete(id: tx.id)
                                    viewModel.loadData()
                                } catch {
                                    AppLogger.ui.error("HomeView deleteTransaction failed: \(error.localizedDescription)")
                                    errorMessage = L("error_delete_failed")
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
            .navigationTitle(L("tab_transactions"))
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        showReminders = true
                    } label: {
                        Image(systemName: "bell")
                            .foregroundColor(AppColors.textPrimary)
                    }
                    .accessibilityLabel(L("reminders_title"))
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showSearch = true
                    } label: {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(AppColors.textPrimary)
                    }
                    .accessibilityLabel(L("search_title"))
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
            .navigationDestination(isPresented: $showReminders) {
                RemindersView(
                    reminderRepository: reminderRepository,
                    categoryRepository: categoryRepository,
                    settingsRepository: settingsRepository
                )
            }
            .onAppear {
                viewModel.loadData()
            }
            .alert(L("error_title"), isPresented: Binding(
                get: { errorMessage != nil },
                set: { if !$0 { errorMessage = nil } }
            )) {
                Button(L("error_ok"), role: .cancel) {}
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

            Text(L("home_empty_state"))
                .font(AppTypography.body)
                .foregroundColor(AppColors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, minHeight: 200)
        .padding(.top, AppSpacing.xxl)
    }
}
