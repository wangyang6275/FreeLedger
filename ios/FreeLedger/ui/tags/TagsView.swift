import SwiftUI

struct TagsView: View {
    @State private var viewModel: TagsViewModel

    let tagRepository: TagRepositoryProtocol
    let transactionRepository: TransactionRepositoryProtocol
    let categoryRepository: CategoryRepositoryProtocol
    let settingsRepository: SettingsRepositoryProtocol

    init(tagRepository: TagRepositoryProtocol,
         transactionRepository: TransactionRepositoryProtocol,
         categoryRepository: CategoryRepositoryProtocol,
         settingsRepository: SettingsRepositoryProtocol) {
        self.tagRepository = tagRepository
        self.transactionRepository = transactionRepository
        self.categoryRepository = categoryRepository
        self.settingsRepository = settingsRepository
        _viewModel = State(initialValue: TagsViewModel(tagRepository: tagRepository))
    }

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isEmpty {
                    emptyStateView
                } else {
                    tagListView
                }
            }
            .background(AppColors.background)
            .navigationTitle(String(localized: "tab_tags"))
            .navigationDestination(for: Tag.self) { tag in
                TagDetailView(
                    tag: tag,
                    tagRepository: tagRepository,
                    transactionRepository: transactionRepository,
                    categoryRepository: categoryRepository,
                    settingsRepository: settingsRepository
                )
            }
            .onAppear {
                viewModel.loadData()
            }
            .alert(String(localized: "error_title"), isPresented: Binding(
                get: { viewModel.errorMessage != nil },
                set: { if !$0 { viewModel.errorMessage = nil } }
            )) {
                Button(String(localized: "error_ok"), role: .cancel) {}
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: AppSpacing.lg) {
            Image(systemName: "tag")
                .font(.system(size: 48))
                .foregroundColor(AppColors.textTertiary)

            Text(String(localized: "tags_empty_state"))
                .font(AppTypography.body)
                .foregroundColor(AppColors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.top, AppSpacing.xxl)
    }

    private var tagListView: some View {
        List {
            ForEach(viewModel.tags) { tag in
                NavigationLink(value: tag) {
                    tagRow(tag)
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }

    private func tagRow(_ tag: Tag) -> some View {
        HStack(spacing: AppSpacing.md) {
            Circle()
                .fill(Color(hex: tag.colorHex))
                .frame(width: 12, height: 12)

            Text(tag.name)
                .font(AppTypography.body)
                .foregroundColor(AppColors.textPrimary)

            Spacer()

            Text(String(localized: "tag_count \(viewModel.transactionCount(for: tag))"))
                .font(AppTypography.caption)
                .foregroundColor(AppColors.textTertiary)
        }
        .padding(.vertical, AppSpacing.xs)
    }
}
