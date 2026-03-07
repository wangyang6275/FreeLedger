import Foundation
import Observation

@Observable
final class TagsViewModel {
    var tags: [Tag] = []
    var transactionCounts: [String: Int] = [:]
    var errorMessage: String?

    private let tagRepository: TagRepositoryProtocol

    var isEmpty: Bool { tags.isEmpty }

    init(tagRepository: TagRepositoryProtocol) {
        self.tagRepository = tagRepository
    }

    func loadData() {
        do {
            tags = try tagRepository.getAll()
            transactionCounts = try tagRepository.getTransactionCountPerTag()
        } catch {
            AppLogger.ui.error("TagsViewModel loadData failed: \(error.localizedDescription)")
            errorMessage = L("error_load_failed")
        }
    }

    func transactionCount(for tag: Tag) -> Int {
        transactionCounts[tag.id] ?? 0
    }

    func createTag(name: String, colorHex: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        do {
            let tag = Tag(name: trimmed, colorHex: colorHex)
            try tagRepository.create(tag)
            loadData()
        } catch {
            AppLogger.ui.error("TagsViewModel createTag failed: \(error.localizedDescription)")
            errorMessage = L("error_save_failed")
        }
    }

    func updateTag(_ tag: Tag, name: String, colorHex: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        var updated = tag
        updated.name = trimmed
        updated.colorHex = colorHex
        do {
            try tagRepository.update(updated)
            loadData()
        } catch {
            AppLogger.ui.error("TagsViewModel updateTag failed: \(error.localizedDescription)")
            errorMessage = L("error_save_failed")
        }
    }

    func deleteTag(id: String) {
        do {
            try tagRepository.delete(id: id)
            loadData()
        } catch {
            AppLogger.ui.error("TagsViewModel deleteTag failed: \(error.localizedDescription)")
            errorMessage = L("error_save_failed")
        }
    }
}
