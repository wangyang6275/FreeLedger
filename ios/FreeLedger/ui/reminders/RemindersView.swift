import SwiftUI

struct RemindersView: View {
    @State private var viewModel: RemindersViewModel
    @State private var showCreateSheet = false
    @State private var editingReminder: Reminder?
    @State private var deletingReminder: Reminder?
    @State private var showDeleteConfirm = false

    let categoryRepository: CategoryRepositoryProtocol

    init(reminderRepository: ReminderRepositoryProtocol,
         categoryRepository: CategoryRepositoryProtocol,
         settingsRepository: SettingsRepositoryProtocol) {
        self.categoryRepository = categoryRepository
        _viewModel = State(initialValue: RemindersViewModel(
            reminderRepository: reminderRepository,
            categoryRepository: categoryRepository,
            settingsRepository: settingsRepository
        ))
    }

    var body: some View {
        Group {
            if viewModel.isEmpty {
                emptyStateView
            } else {
                reminderListView
            }
        }
        .background(AppColors.background)
        .navigationTitle(L("reminders_title"))
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showCreateSheet = true
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 16, weight: .semibold))
                }
            }
        }
        .onAppear {
            viewModel.loadData()
            NotificationService.requestPermission { _ in }
        }
        .alert(L("error_title"), isPresented: Binding(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )) {
            Button(L("error_ok"), role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
        .sheet(isPresented: $showCreateSheet) {
            ReminderEditSheet(
                categories: viewModel.categories,
                currencyCode: viewModel.currencyCode,
                onSave: { reminder in
                    viewModel.createReminder(reminder)
                }
            )
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
        }
        .sheet(item: $editingReminder) { reminder in
            ReminderEditSheet(
                reminder: reminder,
                categories: viewModel.categories,
                currencyCode: viewModel.currencyCode,
                onSave: { updated in
                    viewModel.updateReminder(updated)
                }
            )
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
        }
        .overlay {
            if showDeleteConfirm, let reminder = deletingReminder {
                FriendlyDialog(
                    title: L("reminders_delete_title"),
                    message: L("reminders_delete_message %@", reminder.title),
                    style: .destructive,
                    confirmTitle: L("action_delete"),
                    cancelTitle: L("action_cancel"),
                    onConfirm: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            showDeleteConfirm = false
                        }
                        viewModel.deleteReminder(id: reminder.id)
                        deletingReminder = nil
                    },
                    onCancel: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            showDeleteConfirm = false
                        }
                        deletingReminder = nil
                    }
                )
            }
        }
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        ScrollView {
            VStack(spacing: AppSpacing.xl) {
                Spacer().frame(height: AppSpacing.xxxl)

                Image(systemName: "bell.badge")
                    .font(.system(size: 52))
                    .foregroundStyle(AppColors.primary.gradient)

                VStack(spacing: AppSpacing.sm) {
                    Text(L("reminders_empty_title"))
                        .font(AppTypography.title2)
                        .foregroundColor(AppColors.textPrimary)

                    Text(L("reminders_empty_desc"))
                        .font(AppTypography.body)
                        .foregroundColor(AppColors.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, AppSpacing.xxl)
                }

                // Example cards
                VStack(spacing: AppSpacing.md) {
                    exampleCard(icon: "house", title: L("reminders_example_rent"), freq: L("reminders_freq_monthly"))
                    exampleCard(icon: "creditcard", title: L("reminders_example_mortgage"), freq: L("reminders_freq_monthly"))
                    exampleCard(icon: "phone", title: L("reminders_example_phone"), freq: L("reminders_freq_monthly"))
                }
                .padding(.horizontal, AppSpacing.lg)

                Button {
                    showCreateSheet = true
                } label: {
                    HStack(spacing: AppSpacing.sm) {
                        Image(systemName: "plus")
                            .font(.system(size: 14, weight: .bold))
                        Text(L("reminders_create_first"))
                            .font(AppTypography.bodyLarge)
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, AppSpacing.xxl)
                    .padding(.vertical, 14)
                    .background(AppColors.primary.gradient)
                    .clipShape(Capsule())
                }
                .padding(.top, AppSpacing.sm)
            }
        }
        .scrollIndicators(.hidden)
    }

    private func exampleCard(icon: String, title: String, freq: String) -> some View {
        HStack(spacing: AppSpacing.md) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(AppColors.primary)
                .frame(width: 36, height: 36)
                .background(AppColors.primaryLight)
                .clipShape(RoundedRectangle(cornerRadius: AppRadius.sm))

            Text(title)
                .font(AppTypography.body)
                .foregroundColor(AppColors.textPrimary)

            Spacer()

            Text(freq)
                .font(AppTypography.caption)
                .foregroundColor(AppColors.textTertiary)
        }
        .padding(AppSpacing.md)
        .background(AppColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
    }

    // MARK: - Reminder List

    private var reminderListView: some View {
        List {
            ForEach(viewModel.reminders) { reminder in
                reminderRow(reminder)
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) {
                            deletingReminder = reminder
                            withAnimation(.easeInOut(duration: 0.2)) {
                                showDeleteConfirm = true
                            }
                        } label: {
                            Label(L("action_delete"), systemImage: "trash")
                        }

                        Button {
                            editingReminder = reminder
                        } label: {
                            Label(L("action_edit"), systemImage: "pencil")
                        }
                        .tint(.orange)
                    }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }

    private func reminderRow(_ reminder: Reminder) -> some View {
        HStack(spacing: AppSpacing.md) {
            // Category icon or bell
            let cat = viewModel.category(for: reminder.categoryId)
            if let cat {
                CategoryIconView(
                    iconName: cat.iconName,
                    colorHex: cat.colorHex,
                    size: 36,
                    iconSize: 18
                )
            } else {
                ZStack {
                    Circle()
                        .fill(AppColors.primaryLight)
                        .frame(width: 36, height: 36)
                    Image(systemName: "bell.fill")
                        .font(.system(size: 16))
                        .foregroundColor(AppColors.primary)
                }
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(reminder.title)
                    .font(AppTypography.body)
                    .foregroundColor(reminder.isEnabled ? AppColors.textPrimary : AppColors.textTertiary)

                HStack(spacing: AppSpacing.sm) {
                    Text(frequencyText(reminder))
                        .font(AppTypography.caption)
                        .foregroundColor(AppColors.textSecondary)

                    Text(timeText(reminder))
                        .font(AppTypography.caption)
                        .foregroundColor(AppColors.textTertiary)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(AmountFormatter.format(reminder.amount, currencyCode: viewModel.currencyCode))
                    .font(AppTypography.body)
                    .fontWeight(.medium)
                    .foregroundColor(reminder.typeEnum == .expense ? AppColors.expense : AppColors.income)

                Toggle("", isOn: Binding(
                    get: { reminder.isEnabled },
                    set: { _ in viewModel.toggleEnabled(reminder) }
                ))
                .labelsHidden()
                .scaleEffect(0.8)
            }
        }
        .padding(.vertical, AppSpacing.xs)
    }

    private func frequencyText(_ reminder: Reminder) -> String {
        switch reminder.frequencyEnum {
        case .daily:
            return L("reminders_freq_daily")
        case .weekly:
            let weekday = reminder.triggerDay ?? 1
            return L("reminders_freq_weekly_day %@", weekdayName(weekday))
        case .monthly:
            let day = reminder.triggerDay ?? 1
            return L("reminders_freq_monthly_day %lld", Int64(day))
        }
    }

    private func timeText(_ reminder: Reminder) -> String {
        String(format: "%02d:%02d", reminder.triggerHour, reminder.triggerMinute)
    }

    private func weekdayName(_ day: Int) -> String {
        let symbols = Calendar.current.shortWeekdaySymbols
        let index = max(0, min(day - 1, symbols.count - 1))
        return symbols[index]
    }
}

// MARK: - Reminder Edit Sheet

struct ReminderEditSheet: View {
    let reminder: Reminder?
    let categories: [Category]
    let currencyCode: String
    let onSave: (Reminder) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var title: String = ""
    @State private var amountString: String = ""
    @State private var isExpense: Bool = true
    @State private var selectedCategoryId: String?
    @State private var note: String = ""
    @State private var frequency: ReminderFrequency = .monthly
    @State private var triggerDay: Int = 1
    @State private var triggerHour: Int = 9
    @State private var triggerMinute: Int = 0
    @State private var isEnabled: Bool = true

    init(reminder: Reminder? = nil,
         categories: [Category],
         currencyCode: String,
         onSave: @escaping (Reminder) -> Void) {
        self.reminder = reminder
        self.categories = categories
        self.currencyCode = currencyCode
        self.onSave = onSave
    }

    private var isEditing: Bool { reminder != nil }

    private var filteredCategories: [Category] {
        let type = isExpense ? "expense" : "income"
        return categories.filter { $0.type == type }
    }

    private var canSave: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        AmountFormatter.toCents(amountString) > 0
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: AppSpacing.xl) {
                    // Title
                    fieldSection(label: L("reminders_field_title")) {
                        TextField(L("reminders_title_placeholder"), text: $title)
                            .font(AppTypography.body)
                            .padding(AppSpacing.md)
                            .background(AppColors.surface)
                            .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
                    }

                    // Type toggle + Amount
                    fieldSection(label: L("reminders_field_amount")) {
                        VStack(spacing: AppSpacing.md) {
                            typeToggle

                            HStack {
                                Text(currencySymbol)
                                    .font(AppTypography.title2)
                                    .foregroundColor(AppColors.textSecondary)
                                TextField("0.00", text: $amountString)
                                    .font(.system(size: 28, weight: .bold, design: .rounded))
                                    .keyboardType(.decimalPad)
                                    .foregroundColor(isExpense ? AppColors.expense : AppColors.income)
                            }
                            .padding(AppSpacing.md)
                            .background(AppColors.surface)
                            .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
                        }
                    }

                    // Category
                    fieldSection(label: L("reminders_field_category")) {
                        categoryPicker
                    }

                    // Frequency
                    fieldSection(label: L("reminders_field_frequency")) {
                        VStack(spacing: AppSpacing.md) {
                            Picker("", selection: $frequency) {
                                Text(L("reminders_freq_daily")).tag(ReminderFrequency.daily)
                                Text(L("reminders_freq_weekly")).tag(ReminderFrequency.weekly)
                                Text(L("reminders_freq_monthly")).tag(ReminderFrequency.monthly)
                            }
                            .pickerStyle(.segmented)

                            if frequency == .weekly {
                                weekdayPicker
                            }
                            if frequency == .monthly {
                                dayOfMonthPicker
                            }
                        }
                    }

                    // Time
                    fieldSection(label: L("reminders_field_time")) {
                        DatePicker("", selection: Binding(
                            get: {
                                Calendar.current.date(from: DateComponents(hour: triggerHour, minute: triggerMinute)) ?? Date()
                            },
                            set: { date in
                                let comps = Calendar.current.dateComponents([.hour, .minute], from: date)
                                triggerHour = comps.hour ?? 9
                                triggerMinute = comps.minute ?? 0
                            }
                        ), displayedComponents: .hourAndMinute)
                        .datePickerStyle(.wheel)
                        .frame(height: 100)
                        .clipped()
                    }

                    // Note
                    fieldSection(label: L("reminders_field_note")) {
                        TextField(L("record_note_placeholder"), text: $note)
                            .font(AppTypography.body)
                            .padding(AppSpacing.md)
                            .background(AppColors.surface)
                            .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
                    }

                    // Save button
                    Button {
                        save()
                    } label: {
                        Text(isEditing ? L("tags_save") : L("reminders_create"))
                            .font(AppTypography.bodyLarge)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(
                                canSave
                                    ? AnyShapeStyle(AppColors.primary.gradient)
                                    : AnyShapeStyle(AppColors.divider)
                            )
                            .clipShape(RoundedRectangle(cornerRadius: AppRadius.lg))
                    }
                    .disabled(!canSave)
                    .padding(.top, AppSpacing.sm)
                }
                .padding(.horizontal, AppSpacing.xl)
                .padding(.vertical, AppSpacing.lg)
            }
            .scrollIndicators(.hidden)
            .background(AppColors.background)
            .navigationTitle(isEditing ? L("reminders_edit_title") : L("reminders_new_title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(L("action_cancel")) { dismiss() }
                }
            }
            .onAppear { loadReminder() }
        }
    }

    // MARK: - Sub Views

    private func fieldSection<Content: View>(label: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text(label)
                .font(AppTypography.caption)
                .foregroundColor(AppColors.textSecondary)
            content()
        }
    }

    private var typeToggle: some View {
        HStack(spacing: 0) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isExpense = true
                    selectedCategoryId = nil
                }
            } label: {
                Text(L("record_expense"))
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(isExpense ? .white : AppColors.textSecondary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 7)
                    .background(Capsule().fill(isExpense ? AppColors.expense : Color.clear))
            }

            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isExpense = false
                    selectedCategoryId = nil
                }
            } label: {
                Text(L("record_income"))
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(!isExpense ? .white : AppColors.textSecondary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 7)
                    .background(Capsule().fill(!isExpense ? AppColors.income : Color.clear))
            }
        }
        .frame(maxWidth: .infinity)
        .padding(3)
        .background(Capsule().fill(AppColors.surface))
    }

    private var categoryPicker: some View {
        let cols = Array(repeating: GridItem(.flexible(), spacing: AppSpacing.sm), count: 5)
        return LazyVGrid(columns: cols, spacing: AppSpacing.sm) {
            ForEach(filteredCategories) { cat in
                let isSelected = selectedCategoryId == cat.id
                Button {
                    selectedCategoryId = cat.id
                } label: {
                    VStack(spacing: 4) {
                        CategoryIconView(
                            iconName: cat.iconName,
                            colorHex: isSelected ? cat.colorHex : "#F0F0F0",
                            size: 40,
                            iconSize: 20
                        )
                        .overlay(
                            Circle()
                                .stroke(isSelected ? Color(hex: cat.colorHex) : Color.clear, lineWidth: 2)
                                .frame(width: 44, height: 44)
                        )

                        Text(L(cat.nameKey))
                            .font(AppTypography.small)
                            .foregroundColor(isSelected ? Color(hex: cat.colorHex) : AppColors.textSecondary)
                            .lineLimit(1)
                    }
                }
            }
        }
    }

    private var weekdayPicker: some View {
        let symbols = Calendar.current.shortWeekdaySymbols
        return HStack(spacing: AppSpacing.sm) {
            ForEach(1...7, id: \.self) { day in
                let index = day - 1
                Button {
                    triggerDay = day
                } label: {
                    Text(symbols[index])
                        .font(AppTypography.caption)
                        .fontWeight(triggerDay == day ? .bold : .regular)
                        .foregroundColor(triggerDay == day ? .white : AppColors.textSecondary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 36)
                        .background(triggerDay == day ? AppColors.primary : AppColors.surface)
                        .clipShape(RoundedRectangle(cornerRadius: AppRadius.sm))
                }
            }
        }
    }

    private var dayOfMonthPicker: some View {
        let cols = Array(repeating: GridItem(.flexible(), spacing: 4), count: 7)
        return LazyVGrid(columns: cols, spacing: 4) {
            ForEach(1...28, id: \.self) { day in
                Button {
                    triggerDay = day
                } label: {
                    Text("\(day)")
                        .font(AppTypography.caption)
                        .fontWeight(triggerDay == day ? .bold : .regular)
                        .foregroundColor(triggerDay == day ? .white : AppColors.textPrimary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 32)
                        .background(triggerDay == day ? AppColors.primary : AppColors.surface)
                        .clipShape(RoundedRectangle(cornerRadius: AppRadius.sm))
                }
            }
        }
    }

    private var currencySymbol: String {
        let locale = Locale(identifier: Locale.identifier(fromComponents: [NSLocale.Key.currencyCode.rawValue: currencyCode]))
        return locale.currencySymbol ?? "¥"
    }

    // MARK: - Actions

    private func loadReminder() {
        guard let r = reminder else { return }
        title = r.title
        amountString = String(format: "%.2f", Double(r.amount) / 100.0)
        isExpense = r.typeEnum == .expense
        selectedCategoryId = r.categoryId
        note = r.note ?? ""
        frequency = r.frequencyEnum
        triggerDay = r.triggerDay ?? 1
        triggerHour = r.triggerHour
        triggerMinute = r.triggerMinute
        isEnabled = r.isEnabled
    }

    private func save() {
        let cents = AmountFormatter.toCents(amountString)
        guard cents > 0 else { return }
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else { return }
        let trimmedNote = note.trimmingCharacters(in: .whitespacesAndNewlines)

        let result = Reminder(
            id: reminder?.id ?? UUID().uuidString,
            title: trimmedTitle,
            amount: cents,
            type: isExpense ? TransactionType.expense.rawValue : TransactionType.income.rawValue,
            categoryId: selectedCategoryId,
            note: trimmedNote.isEmpty ? nil : trimmedNote,
            frequency: frequency.rawValue,
            triggerDay: frequency == .daily ? nil : triggerDay,
            triggerHour: triggerHour,
            triggerMinute: triggerMinute,
            isEnabled: isEnabled,
            createdAt: reminder?.createdAt
        )

        onSave(result)
        dismiss()
    }
}
