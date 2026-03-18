import SwiftUI

struct CalendarView: View {
    @State private var viewModel: CalendarViewModel

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
        _viewModel = State(initialValue: CalendarViewModel(
            transactionRepository: transactionRepository,
            categoryRepository: categoryRepository,
            settingsRepository: settingsRepository
        ))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    monthSelector
                    weekdayHeader
                    calendarGrid
                    if let day = viewModel.selectedDay {
                        dayDetail(day: day)
                    }
                }
                .padding(.bottom, AppSpacing.xxl)
            }
            .background(GlassPageBackground())
            .navigationTitle(L("calendar_title"))
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
        }
    }

    // MARK: - Month Selector

    private var monthSelector: some View {
        HStack {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    viewModel.previousMonth()
                }
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(AppColors.primary)
                    .frame(width: 44, height: 44)
            }

            Spacer()

            Text(viewModel.monthTitle)
                .font(AppTypography.title2)
                .foregroundColor(AppColors.textPrimary)

            Spacer()

            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    viewModel.nextMonth()
                }
            } label: {
                Image(systemName: "chevron.right")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(viewModel.isCurrentMonth ? AppColors.textTertiary : AppColors.primary)
                    .frame(width: 44, height: 44)
            }
            .disabled(viewModel.isCurrentMonth)
        }
        .padding(.horizontal, AppSpacing.lg)
        .padding(.vertical, AppSpacing.sm)
    }

    // MARK: - Weekday Header

    private var weekdayHeader: some View {
        let symbols = Calendar.current.veryShortWeekdaySymbols
        return LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 0) {
            ForEach(symbols, id: \.self) { symbol in
                Text(symbol)
                    .font(AppTypography.caption)
                    .foregroundColor(AppColors.textTertiary)
                    .frame(height: 32)
            }
        }
        .padding(.horizontal, AppSpacing.md)
    }

    // MARK: - Calendar Grid

    private var calendarGrid: some View {
        let offset = viewModel.firstWeekdayOfMonth - 1
        let totalCells = offset + viewModel.daysInMonth

        return LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 4) {
            ForEach(0..<totalCells, id: \.self) { index in
                if index < offset {
                    Color.clear.frame(height: 52)
                } else {
                    let day = index - offset + 1
                    dayCell(day: day)
                }
            }
        }
        .padding(.horizontal, AppSpacing.md)
    }

    private func dayCell(day: Int) -> some View {
        let isToday = viewModel.todayDay == day
        let isSelected = viewModel.selectedDay == day
        let summary = viewModel.dailySummaries[day]
        let hasRecords = summary != nil && summary!.count > 0

        return Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                viewModel.selectDay(day)
            }
        } label: {
            VStack(spacing: 2) {
                ZStack {
                    if isSelected {
                        Circle()
                            .fill(AppColors.primary)
                            .frame(width: 32, height: 32)
                    } else if isToday {
                        Circle()
                            .stroke(AppColors.primary, lineWidth: 2)
                            .frame(width: 32, height: 32)
                    }

                    Text("\(day)")
                        .font(AppTypography.body)
                        .foregroundColor(isSelected ? .white : (isToday ? AppColors.primary : AppColors.textPrimary))
                }

                Circle()
                    .fill(hasRecords ? AppColors.primary : Color.clear)
                    .frame(width: 6, height: 6)
            }
            .frame(height: 52)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Day Detail

    private func dayDetail(day: Int) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            if let summary = viewModel.dailySummaries[day] {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(L("record_expense"))
                            .font(AppTypography.caption)
                            .foregroundColor(AppColors.textTertiary)
                        Text(AmountFormatter.format(summary.expense, currencyCode: viewModel.currencyCode))
                            .font(AppTypography.body)
                            .foregroundColor(AppColors.expense)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(L("record_income"))
                            .font(AppTypography.caption)
                            .foregroundColor(AppColors.textTertiary)
                        Text(AmountFormatter.format(summary.income, currencyCode: viewModel.currencyCode))
                            .font(AppTypography.body)
                            .foregroundColor(AppColors.income)
                    }
                }
                .padding(.horizontal, AppSpacing.lg)
                .padding(.top, AppSpacing.md)
            }

            if viewModel.selectedDayTransactions.isEmpty {
                Text(L("calendar_no_records"))
                    .font(AppTypography.body)
                    .foregroundColor(AppColors.textTertiary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AppSpacing.xl)
            } else {
                ForEach(viewModel.selectedDayTransactions) { transaction in
                    NavigationLink(value: transaction) {
                        TransactionCard(
                            transaction: transaction,
                            category: viewModel.categoryDict[transaction.categoryId],
                            currencyCode: viewModel.currencyCode
                        )
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, AppSpacing.lg)
                }
            }
        }
    }
}
