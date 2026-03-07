import SwiftUI

struct TagSelector: View {
    let tagRepository: TagRepositoryProtocol
    @Binding var selectedTagIds: Set<String>
    let onDismiss: () -> Void

    @State private var allTags: [Tag] = []
    @State private var showCreateForm: Bool = false
    @State private var newTagName: String = ""
    @State private var newTagColor: String = "#FF6B6B"
    @State private var errorMessage: String?

    private let tagPresetColors = [
        "#FF6B6B", "#FF8E53", "#FFC107", "#4CAF50",
        "#2196F3", "#9C27B0", "#795548", "#607D8B",
    ]

    private let colorColumns = Array(repeating: GridItem(.flexible(), spacing: AppSpacing.sm), count: 8)

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: AppSpacing.lg) {
                tagFlowSection
                if showCreateForm {
                    createFormSection
                }
                Spacer()
            }
            .padding(.horizontal, AppSpacing.lg)
            .padding(.top, AppSpacing.md)
            .background(AppColors.background)
            .navigationTitle(L("tag_selector_title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(L("tag_selector_done")) {
                        onDismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
            .onAppear { loadTags() }
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

    // MARK: - Tag Flow

    private var tagFlowSection: some View {
        FlowLayout(spacing: AppSpacing.sm) {
            ForEach(allTags) { tag in
                tagCapsule(tag)
            }
            addTagButton
        }
    }

    private func tagCapsule(_ tag: Tag) -> some View {
        let isSelected = selectedTagIds.contains(tag.id)
        return Button(action: {
            if isSelected {
                selectedTagIds.remove(tag.id)
            } else {
                selectedTagIds.insert(tag.id)
            }
        }) {
            Text(tag.name)
                .font(AppTypography.caption)
                .foregroundColor(isSelected ? .white : Color(hex: tag.colorHex))
                .padding(.horizontal, AppSpacing.md)
                .padding(.vertical, AppSpacing.xs)
                .background(isSelected ? Color(hex: tag.colorHex) : Color.clear)
                .clipShape(Capsule())
                .overlay(
                    Capsule().stroke(Color(hex: tag.colorHex), lineWidth: 1)
                )
        }
    }

    private var addTagButton: some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.2)) {
                showCreateForm.toggle()
                if !showCreateForm {
                    newTagName = ""
                }
            }
        }) {
            Image(systemName: showCreateForm ? "xmark" : "plus")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(AppColors.textSecondary)
                .frame(width: 32, height: 28)
                .background(AppColors.surface)
                .clipShape(Capsule())
        }
    }

    // MARK: - Create Form

    private var createFormSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            TextField(L("tag_name_placeholder"), text: $newTagName)
                .font(AppTypography.body)
                .padding(AppSpacing.md)
                .background(AppColors.surface)
                .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))

            LazyVGrid(columns: colorColumns, spacing: AppSpacing.sm) {
                ForEach(tagPresetColors, id: \.self) { colorHex in
                    Button(action: { newTagColor = colorHex }) {
                        Circle()
                            .fill(Color(hex: colorHex))
                            .frame(width: 32, height: 32)
                            .overlay(
                                newTagColor == colorHex
                                    ? Image(systemName: "checkmark")
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundColor(.white)
                                    : nil
                            )
                    }
                }
            }

            Button(action: createTag) {
                Text(L("tag_create_button"))
                    .font(AppTypography.body)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 40)
                    .background(
                        newTagName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                            ? AppColors.textTertiary
                            : Color(hex: newTagColor)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
            }
            .disabled(newTagName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
        .padding(AppSpacing.md)
        .background(AppColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
    }

    // MARK: - Actions

    private func loadTags() {
        do {
            allTags = try tagRepository.getAll()
        } catch {
            AppLogger.ui.error("TagSelector loadTags failed: \(error.localizedDescription)")
            errorMessage = L("error_load_failed")
        }
    }

    private func createTag() {
        let trimmed = newTagName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        do {
            let tag = Tag(name: trimmed, colorHex: newTagColor)
            try tagRepository.create(tag)
            selectedTagIds.insert(tag.id)
            newTagName = ""
            withAnimation(.easeInOut(duration: 0.2)) {
                showCreateForm = false
            }
            loadTags()
        } catch {
            AppLogger.ui.error("TagSelector createTag failed: \(error.localizedDescription)")
            errorMessage = L("error_save_failed")
        }
    }
}

// MARK: - FlowLayout

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = computeLayout(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = computeLayout(proposal: proposal, subviews: subviews)
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(
                at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y),
                proposal: ProposedViewSize(result.sizes[index])
            )
        }
    }

    private struct LayoutResult {
        var size: CGSize
        var positions: [CGPoint]
        var sizes: [CGSize]
    }

    private func computeLayout(proposal: ProposedViewSize, subviews: Subviews) -> LayoutResult {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var sizes: [CGSize] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            sizes.append(size)

            if x + size.width > maxWidth && x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }

            positions.append(CGPoint(x: x, y: y))
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
        }

        let totalHeight = y + rowHeight
        return LayoutResult(
            size: CGSize(width: maxWidth, height: totalHeight),
            positions: positions,
            sizes: sizes
        )
    }
}
