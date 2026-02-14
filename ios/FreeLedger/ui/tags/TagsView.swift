import SwiftUI

struct TagsView: View {
    @State private var viewModel: TagsViewModel
    @State private var showCreateSheet = false
    @State private var editingTag: Tag?
    @State private var deletingTag: Tag?
    @State private var showDeleteConfirm = false

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
            .sheet(isPresented: $showCreateSheet) {
                TagEditSheet(mode: .create) { name, color in
                    viewModel.createTag(name: name, colorHex: color)
                }
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
            }
            .sheet(item: $editingTag) { tag in
                TagEditSheet(mode: .edit(tag)) { name, color in
                    viewModel.updateTag(tag, name: name, colorHex: color)
                }
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
            }
            .overlay {
                if showDeleteConfirm, let tag = deletingTag {
                    FriendlyDialog(
                        title: String(localized: "tags_delete_title"),
                        message: String(localized: "tags_delete_message \(tag.name)"),
                        style: .destructive,
                        confirmTitle: String(localized: "action_delete"),
                        cancelTitle: String(localized: "action_cancel"),
                        onConfirm: {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                showDeleteConfirm = false
                            }
                            viewModel.deleteTag(id: tag.id)
                            deletingTag = nil
                        },
                        onCancel: {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                showDeleteConfirm = false
                            }
                            deletingTag = nil
                        }
                    )
                }
            }
        }
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: AppSpacing.xl) {
            Spacer()

            Image(systemName: "tag")
                .font(.system(size: 56))
                .foregroundColor(AppColors.textTertiary.opacity(0.5))

            VStack(spacing: AppSpacing.sm) {
                Text(String(localized: "tags_empty_title"))
                    .font(AppTypography.title2)
                    .foregroundColor(AppColors.textPrimary)

                Text(String(localized: "tags_empty_desc"))
                    .font(AppTypography.body)
                    .foregroundColor(AppColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, AppSpacing.xxl)
            }

            Button {
                showCreateSheet = true
            } label: {
                HStack(spacing: AppSpacing.sm) {
                    Image(systemName: "plus")
                        .font(.system(size: 14, weight: .bold))
                    Text(String(localized: "tags_create_first"))
                        .font(AppTypography.bodyLarge)
                        .fontWeight(.semibold)
                }
                .foregroundColor(.white)
                .padding(.horizontal, AppSpacing.xxl)
                .padding(.vertical, 14)
                .background(AppColors.primary.gradient)
                .clipShape(Capsule())
            }
            .padding(.top, AppSpacing.md)

            Spacer()
            Spacer()
        }
    }

    // MARK: - Tag List

    private var tagListView: some View {
        List {
            ForEach(viewModel.tags) { tag in
                NavigationLink(value: tag) {
                    tagRow(tag)
                }
                .swipeActions(edge: .trailing) {
                    Button(role: .destructive) {
                        deletingTag = tag
                        withAnimation(.easeInOut(duration: 0.2)) {
                            showDeleteConfirm = true
                        }
                    } label: {
                        Label(String(localized: "action_delete"), systemImage: "trash")
                    }

                    Button {
                        editingTag = tag
                    } label: {
                        Label(String(localized: "action_edit"), systemImage: "pencil")
                    }
                    .tint(.orange)
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
                .frame(width: 10, height: 10)
                .padding(6)
                .background(Color(hex: tag.colorHex).opacity(0.15))
                .clipShape(Circle())

            Text(tag.name)
                .font(AppTypography.body)
                .foregroundColor(AppColors.textPrimary)

            Spacer()

            let count = viewModel.transactionCount(for: tag)
            if count > 0 {
                Text(String(localized: "tag_count \(count)"))
                    .font(AppTypography.caption)
                    .foregroundColor(AppColors.textTertiary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(AppColors.surface)
                    .clipShape(Capsule())
            }
        }
        .padding(.vertical, AppSpacing.xs)
    }
}

// MARK: - Tag Edit Sheet

struct TagEditSheet: View {
    enum Mode {
        case create
        case edit(Tag)
    }

    let mode: Mode
    let onSave: (String, String) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var tagName: String = ""
    @State private var tagColor: String = "#FF6B6B"

    private let presetColors = [
        "#FF6B6B", "#FF8E53", "#FFC107", "#4CAF50",
        "#2196F3", "#9C27B0", "#795548", "#607D8B",
        "#E91E63", "#00BCD4", "#8BC34A", "#FF5722",
    ]

    private let colorColumns = Array(repeating: GridItem(.flexible(), spacing: AppSpacing.md), count: 6)

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: AppSpacing.xl) {
                // Preview
                HStack {
                    Spacer()
                    Text(tagName.isEmpty ? String(localized: "tags_preview") : tagName)
                        .font(AppTypography.bodyLarge)
                        .foregroundColor(tagName.isEmpty ? AppColors.textTertiary : .white)
                        .padding(.horizontal, AppSpacing.xl)
                        .padding(.vertical, 10)
                        .background(
                            tagName.isEmpty ? AppColors.surface : Color(hex: tagColor)
                        )
                        .clipShape(Capsule())
                    Spacer()
                }
                .padding(.top, AppSpacing.md)

                // Name field
                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    Text(String(localized: "tags_name_label"))
                        .font(AppTypography.caption)
                        .foregroundColor(AppColors.textSecondary)

                    TextField(String(localized: "tag_name_placeholder"), text: $tagName)
                        .font(AppTypography.body)
                        .padding(AppSpacing.md)
                        .background(AppColors.surface)
                        .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
                }

                // Color picker
                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    Text(String(localized: "tags_color_label"))
                        .font(AppTypography.caption)
                        .foregroundColor(AppColors.textSecondary)

                    LazyVGrid(columns: colorColumns, spacing: AppSpacing.md) {
                        ForEach(presetColors, id: \.self) { hex in
                            Button {
                                tagColor = hex
                            } label: {
                                Circle()
                                    .fill(Color(hex: hex))
                                    .frame(width: 36, height: 36)
                                    .overlay(
                                        tagColor == hex
                                            ? Image(systemName: "checkmark")
                                                .font(.system(size: 14, weight: .bold))
                                                .foregroundColor(.white)
                                            : nil
                                    )
                                    .scaleEffect(tagColor == hex ? 1.15 : 1.0)
                                    .animation(.easeInOut(duration: 0.15), value: tagColor)
                            }
                        }
                    }
                }

                Spacer()

                // Save button
                Button {
                    onSave(tagName, tagColor)
                    dismiss()
                } label: {
                    Text(isEditing ? String(localized: "tags_save") : String(localized: "tag_create_button"))
                        .font(AppTypography.bodyLarge)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(
                            canSave
                                ? AnyShapeStyle(Color(hex: tagColor).gradient)
                                : AnyShapeStyle(AppColors.divider)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: AppRadius.lg))
                }
                .disabled(!canSave)
            }
            .padding(.horizontal, AppSpacing.xl)
            .padding(.bottom, AppSpacing.lg)
            .background(AppColors.background)
            .navigationTitle(isEditing ? String(localized: "tags_edit_title") : String(localized: "tags_create_title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(String(localized: "action_cancel")) {
                        dismiss()
                    }
                }
            }
            .onAppear {
                if case .edit(let tag) = mode {
                    tagName = tag.name
                    tagColor = tag.colorHex
                }
            }
        }
    }

    private var isEditing: Bool {
        if case .edit = mode { return true }
        return false
    }

    private var canSave: Bool {
        !tagName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}
