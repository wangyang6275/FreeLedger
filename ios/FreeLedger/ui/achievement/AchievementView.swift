import SwiftUI

struct AchievementView: View {
    @State private var viewModel: AchievementViewModel

    init(achievementService: AchievementService) {
        _viewModel = State(initialValue: AchievementViewModel(achievementService: achievementService))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: AppSpacing.lg) {
                progressHeader

                ForEach(AchievementCategory.allCases, id: \.self) { category in
                    let items = viewModel.achievements.filter { $0.category == category }
                    if !items.isEmpty {
                        categorySection(category: category, items: items)
                    }
                }
            }
            .padding(AppSpacing.md)
        }
        .background(AppColors.background)
        .navigationTitle(L("achievement_title"))
        .onAppear { viewModel.loadData() }
        .alert(L("achievement_congrats"), isPresented: $viewModel.showCongrats) {
            Button(L("error_ok")) { viewModel.dismissCongrats() }
        } message: {
            Text(viewModel.newlyUnlocked.map { L($0.titleKey) }.joined(separator: ", "))
        }
    }

    // MARK: - Progress Header

    private var progressHeader: some View {
        VStack(spacing: AppSpacing.sm) {
            ZStack {
                Circle()
                    .stroke(AppColors.textTertiary.opacity(0.2), lineWidth: 8)
                    .frame(width: 80, height: 80)
                Circle()
                    .trim(from: 0, to: viewModel.progress)
                    .stroke(AppColors.primary, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .frame(width: 80, height: 80)
                    .rotationEffect(.degrees(-90))
                Text("\(viewModel.unlockedCount)/\(viewModel.totalCount)")
                    .font(AppTypography.title2)
                    .foregroundColor(AppColors.textPrimary)
                    .fontWeight(.bold)
            }

            Text(L("achievement_progress"))
                .font(AppTypography.caption)
                .foregroundColor(AppColors.textSecondary)
        }
        .padding(AppSpacing.lg)
        .frame(maxWidth: .infinity)
        .background(AppColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
    }

    // MARK: - Category Section

    private func categorySection(category: AchievementCategory, items: [Achievement]) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text(L(categoryTitleKey(category)))
                .font(AppTypography.title2)
                .foregroundColor(AppColors.textPrimary)

            ForEach(items) { achievement in
                achievementRow(achievement)
            }
        }
        .padding(AppSpacing.md)
        .background(AppColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
    }

    private func achievementRow(_ achievement: Achievement) -> some View {
        HStack(spacing: AppSpacing.md) {
            Image(systemName: achievement.iconName)
                .font(.title2)
                .foregroundColor(achievement.isUnlocked ? AppColors.warning : AppColors.textTertiary)
                .frame(width: 36, height: 36)

            VStack(alignment: .leading, spacing: 2) {
                Text(L(achievement.titleKey))
                    .font(AppTypography.body)
                    .foregroundColor(achievement.isUnlocked ? AppColors.textPrimary : AppColors.textTertiary)
                    .fontWeight(achievement.isUnlocked ? .medium : .regular)
                Text(L(achievement.descriptionKey))
                    .font(AppTypography.caption)
                    .foregroundColor(AppColors.textSecondary)
            }

            Spacer()

            if achievement.isUnlocked {
                Image(systemName: "checkmark.seal.fill")
                    .foregroundColor(AppColors.success)
            } else {
                Image(systemName: "lock.fill")
                    .foregroundColor(AppColors.textTertiary)
                    .font(.caption)
            }
        }
        .opacity(achievement.isUnlocked ? 1.0 : 0.6)
    }

    // MARK: - Helpers

    private func categoryTitleKey(_ category: AchievementCategory) -> String {
        switch category {
        case .recording: return "achievement_cat_recording"
        case .streak: return "achievement_cat_streak"
        case .budget: return "achievement_cat_budget"
        case .exploration: return "achievement_cat_exploration"
        }
    }
}

