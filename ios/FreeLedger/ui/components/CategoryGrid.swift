import SwiftUI

struct CategoryGrid: View {
    let categories: [Category]
    var selectedId: String? = nil
    let onSelect: (Category) -> Void

    private let columns = Array(repeating: GridItem(.flexible(), spacing: AppSpacing.md), count: 4)

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: AppSpacing.lg) {
                ForEach(categories) { category in
                    CategoryGridItem(
                        category: category,
                        isSelected: selectedId == category.id
                    ) {
                        onSelect(category)
                    }
                }
            }
            .padding(.horizontal, AppSpacing.lg)
        }
    }
}

struct CategoryGridItem: View {
    let category: Category
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: AppSpacing.xs) {
                ZStack {
                    CategoryIconView(
                        iconName: category.iconName,
                        colorHex: category.colorHex
                    )

                    if isSelected {
                        Circle()
                            .fill(AppColors.primary.opacity(0.8))
                            .frame(width: 48, height: 48)

                        Image(systemName: "checkmark")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                            .transition(.scale.combined(with: .opacity))
                    }
                }
                .scaleEffect(isSelected ? 1.1 : 1.0)

                Text(String(localized: String.LocalizationValue(category.nameKey)))
                    .font(AppTypography.caption)
                    .foregroundColor(AppColors.textSecondary)
                    .lineLimit(1)
            }
        }
        .accessibilityLabel(
            isSelected
                ? String(localized: "a11y_category_selected \(String(localized: String.LocalizationValue(category.nameKey)))")
                : String(localized: "a11y_category \(String(localized: String.LocalizationValue(category.nameKey)))")
        )
    }
}

#Preview {
    CategoryGrid(
        categories: [
            Category(nameKey: "category_food", iconName: "CoffeeOutlined", colorHex: "#FFE8E8", type: "expense", sortOrder: 1),
            Category(nameKey: "category_shopping", iconName: "ShoppingCartOutlined", colorHex: "#F3E8FF", type: "expense", sortOrder: 2),
            Category(nameKey: "category_transport", iconName: "CarOutlined", colorHex: "#FFF3E0", type: "expense", sortOrder: 3),
            Category(nameKey: "category_housing", iconName: "HomeOutlined", colorHex: "#E8F4FD", type: "expense", sortOrder: 4),
        ],
        onSelect: { _ in }
    )
}
