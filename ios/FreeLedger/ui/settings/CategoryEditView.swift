import SwiftUI

struct CategoryEditView: View {
    @Environment(\.dismiss) private var dismiss

    let category: Category?
    let isExpense: Bool
    let categoryRepository: CategoryRepositoryProtocol
    let onSave: () -> Void

    @State private var name: String = ""
    @State private var selectedIconName: String = "CoffeeOutlined"
    @State private var selectedColorHex: String = "#FFE8E8"
    @State private var errorMessage: String?

    private var isEditing: Bool { category != nil }

    private let availableIcons = [
        "CoffeeOutlined", "ShoppingCartOutlined", "CarOutlined", "HomeOutlined",
        "MobileOutlined", "PlayCircleOutlined", "SkinOutlined", "MedicineBoxOutlined",
        "ReadOutlined", "GlobalOutlined", "SmileOutlined", "WalletOutlined",
        "LaptopOutlined", "RiseOutlined", "GiftOutlined", "EllipsisOutlined",
    ]

    private let presetColors = [
        "#FFE8E8", "#F3E8FF", "#FFF3E0", "#E8F4FD",
        "#E8FFE8", "#FFF0F5", "#F5F5DC", "#E0FFFF",
        "#FFDAB9", "#D8BFD8", "#FFB6C1", "#B0E0E6",
    ]

    private let iconColumns = Array(repeating: GridItem(.flexible(), spacing: AppSpacing.md), count: 4)
    private let colorColumns = Array(repeating: GridItem(.flexible(), spacing: AppSpacing.md), count: 6)

    var body: some View {
        ScrollView {
            VStack(spacing: AppSpacing.xl) {
                previewSection
                nameSection
                iconSection
                colorSection
            }
            .padding(.horizontal, AppSpacing.lg)
            .padding(.top, AppSpacing.xl)
            .padding(.bottom, 100)
        }
        .background(AppColors.background)
        .navigationTitle(isEditing
            ? String(localized: "edit_category_title")
            : String(localized: "add_category_title"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(String(localized: "record_save")) {
                    save()
                }
                .fontWeight(.semibold)
                .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .onAppear {
            if let cat = category {
                name = cat.isCustom ? cat.nameKey : ""
                selectedIconName = cat.iconName
                selectedColorHex = cat.colorHex
            }
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

    // MARK: - Preview

    private var previewSection: some View {
        VStack(spacing: AppSpacing.md) {
            CategoryIconView(
                iconName: selectedIconName,
                colorHex: selectedColorHex,
                size: 72,
                iconSize: 36
            )

            if !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Text(name)
                    .font(AppTypography.title2)
                    .foregroundColor(AppColors.textPrimary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppSpacing.lg)
    }

    // MARK: - Name

    private var nameSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text(String(localized: "edit_category_name"))
                .font(AppTypography.caption)
                .foregroundColor(AppColors.textSecondary)

            TextField(String(localized: "edit_category_name_placeholder"), text: $name)
                .font(AppTypography.body)
                .padding(AppSpacing.md)
                .background(AppColors.surface)
                .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
        }
    }

    // MARK: - Icon

    private var iconSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text(String(localized: "edit_category_icon"))
                .font(AppTypography.caption)
                .foregroundColor(AppColors.textSecondary)

            LazyVGrid(columns: iconColumns, spacing: AppSpacing.md) {
                ForEach(availableIcons, id: \.self) { iconName in
                    Button(action: { selectedIconName = iconName }) {
                        CategoryIconView(
                            iconName: iconName,
                            colorHex: selectedIconName == iconName ? selectedColorHex : "#F0F0F0",
                            size: 48,
                            iconSize: 24
                        )
                        .overlay(
                            Circle()
                                .stroke(selectedIconName == iconName ? AppColors.primary : Color.clear, lineWidth: 2)
                                .frame(width: 52, height: 52)
                        )
                    }
                }
            }
            .padding(AppSpacing.md)
            .background(AppColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
        }
    }

    // MARK: - Color

    private var colorSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text(String(localized: "edit_category_color"))
                .font(AppTypography.caption)
                .foregroundColor(AppColors.textSecondary)

            LazyVGrid(columns: colorColumns, spacing: AppSpacing.md) {
                ForEach(presetColors, id: \.self) { colorHex in
                    Button(action: { selectedColorHex = colorHex }) {
                        Circle()
                            .fill(Color(hex: colorHex))
                            .frame(width: 40, height: 40)
                            .overlay(
                                Circle()
                                    .stroke(selectedColorHex == colorHex ? AppColors.primary : Color.clear, lineWidth: 2)
                                    .frame(width: 44, height: 44)
                            )
                            .overlay(
                                selectedColorHex == colorHex
                                    ? Image(systemName: "checkmark")
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundColor(AppColors.textPrimary)
                                    : nil
                            )
                    }
                }
            }
            .padding(AppSpacing.md)
            .background(AppColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
        }
    }

    // MARK: - Save

    private func save() {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }

        do {
            if var existing = category {
                existing.nameKey = trimmedName
                existing.iconName = selectedIconName
                existing.colorHex = selectedColorHex
                try categoryRepository.update(existing)
            } else {
                let type = isExpense ? TransactionType.expense.rawValue : TransactionType.income.rawValue
                let sortOrder = try categoryRepository.getNextSortOrder(type: type)
                let newCategory = Category(
                    nameKey: trimmedName,
                    iconName: selectedIconName,
                    colorHex: selectedColorHex,
                    type: type,
                    sortOrder: sortOrder,
                    isCustom: true
                )
                try categoryRepository.create(newCategory)
            }
            onSave()
            dismiss()
        } catch {
            errorMessage = String(localized: "error_save_failed")
        }
    }
}
