import SwiftUI

struct SearchView: View {
    @State private var viewModel: SearchViewModel
    @State private var showDatePicker = false
    @FocusState private var isSearchFocused: Bool

    let transactionRepository: TransactionRepositoryProtocol
    let categoryRepository: CategoryRepositoryProtocol
    let settingsRepository: SettingsRepositoryProtocol
    let tagRepository: TagRepositoryProtocol

    init(transactionRepository: TransactionRepositoryProtocol,
         categoryRepository: CategoryRepositoryProtocol,
         settingsRepository: SettingsRepositoryProtocol,
         tagRepository: TagRepositoryProtocol) {
        self.transactionRepository = transactionRepository
        self.categoryRepository = categoryRepository
        self.settingsRepository = settingsRepository
        self.tagRepository = tagRepository
        _viewModel = State(initialValue: SearchViewModel(
            transactionRepository: transactionRepository,
            categoryRepository: categoryRepository,
            settingsRepository: settingsRepository
        ))
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                searchBar
                filterBar
                resultsList
            }
            .background(AppColors.background)
            .navigationTitle(L("search_title"))
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
                viewModel.loadInitialData()
                isSearchFocused = true
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
    }

    // MARK: - Search Bar

    private var searchBar: some View {
        HStack(spacing: AppSpacing.sm) {
            HStack(spacing: AppSpacing.sm) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(AppColors.textTertiary)
                TextField(L("search_placeholder"), text: $viewModel.searchText)
                    .focused($isSearchFocused)
                    .submitLabel(.search)
                    .onSubmit { viewModel.performSearch() }
                if !viewModel.searchText.isEmpty {
                    Button { viewModel.searchText = "" } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(AppColors.textTertiary)
                    }
                }
            }
            .padding(AppSpacing.sm)
            .background(AppColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.sm))
        }
        .padding(.horizontal, AppSpacing.lg)
        .padding(.vertical, AppSpacing.sm)
    }

    // MARK: - Filter Bar

    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: AppSpacing.sm) {
                dateFilterChip
                categoryFilterChip
                if viewModel.hasActiveFilters {
                    clearButton
                }
            }
            .padding(.horizontal, AppSpacing.lg)
            .padding(.vertical, AppSpacing.xs)
        }
    }

    private var dateFilterChip: some View {
        Menu {
            dateMenuContent
        } label: {
            filterChipLabel(
                icon: "calendar",
                text: dateFilterText,
                isActive: viewModel.startDate != nil || viewModel.endDate != nil
            )
        }
    }

    @ViewBuilder
    private var dateMenuContent: some View {
        Button(L("search_date_today")) {
            let today = Calendar.current.startOfDay(for: Date())
            viewModel.startDate = today
            viewModel.endDate = today
            viewModel.performSearch()
        }
        Button(L("search_date_this_week")) {
            let now = Date()
            let cal = Calendar.current
            let weekday = cal.component(.weekday, from: now)
            let startOfWeek = cal.date(byAdding: .day, value: -(weekday - cal.firstWeekday), to: cal.startOfDay(for: now))
            viewModel.startDate = startOfWeek
            viewModel.endDate = now
            viewModel.performSearch()
        }
        Button(L("search_date_this_month")) {
            let now = Date()
            let cal = Calendar.current
            let comps = cal.dateComponents([.year, .month], from: now)
            viewModel.startDate = cal.date(from: comps)
            viewModel.endDate = now
            viewModel.performSearch()
        }
        Button(L("search_date_clear")) {
            viewModel.startDate = nil
            viewModel.endDate = nil
            viewModel.performSearch()
        }
    }

    private var dateFilterText: String {
        if viewModel.startDate != nil {
            return L("search_date_selected")
        }
        return L("search_date_label")
    }

    private var categoryFilterChip: some View {
        Menu {
            categoryMenuContent
        } label: {
            filterChipLabel(
                icon: "square.grid.2x2",
                text: categoryFilterText,
                isActive: viewModel.selectedCategoryId != nil
            )
        }
    }

    @ViewBuilder
    private var categoryMenuContent: some View {
        ForEach(viewModel.categories) { cat in
            Button {
                viewModel.selectedCategoryId = cat.id
                viewModel.performSearch()
            } label: {
                Label(viewModel.categoryName(for: cat.id), systemImage: cat.iconName)
            }
        }
        Divider()
        Button(L("search_category_all")) {
            viewModel.selectedCategoryId = nil
            viewModel.performSearch()
        }
    }

    private var categoryFilterText: String {
        if let catId = viewModel.selectedCategoryId {
            return viewModel.categoryName(for: catId)
        }
        return L("search_category_label")
    }

    private var clearButton: some View {
        Button {
            viewModel.clearFilters()
        } label: {
            Text(L("search_clear_all"))
                .font(AppTypography.caption)
                .foregroundColor(AppColors.expense)
        }
    }

    private func filterChipLabel(icon: String, text: String, isActive: Bool) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 12))
            Text(text)
                .font(AppTypography.caption)
        }
        .padding(.horizontal, AppSpacing.md)
        .padding(.vertical, AppSpacing.xs)
        .background(isActive ? AppColors.primary.opacity(0.1) : AppColors.surface)
        .foregroundColor(isActive ? AppColors.primary : AppColors.textSecondary)
        .clipShape(Capsule())
    }

    // MARK: - Results

    private var resultsList: some View {
        Group {
            if viewModel.isEmpty {
                emptyResultView
            } else if viewModel.hasSearched {
                searchResultsView
            } else {
                initialStateView
            }
        }
    }

    private var searchResultsView: some View {
        List(viewModel.results) { transaction in
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
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }

    private var emptyResultView: some View {
        VStack(spacing: AppSpacing.lg) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 48))
                .foregroundColor(AppColors.textTertiary)
            Text(L("search_no_results"))
                .font(AppTypography.body)
                .foregroundColor(AppColors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.top, AppSpacing.xxl)
    }

    private var initialStateView: some View {
        VStack(spacing: AppSpacing.lg) {
            Image(systemName: "text.magnifyingglass")
                .font(.system(size: 48))
                .foregroundColor(AppColors.textTertiary)
            Text(L("search_hint"))
                .font(AppTypography.body)
                .foregroundColor(AppColors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.top, AppSpacing.xxl)
    }
}
