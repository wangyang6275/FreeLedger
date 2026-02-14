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
            errorMessage = String(localized: "error_load_failed")
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
            errorMessage = String(localized: "error_save_failed")
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
            errorMessage = String(localized: "error_save_failed")
        }
    }

    func deleteTag(id: String) {
        do {
            try tagRepository.delete(id: id)
            loadData()
        } catch {
            errorMessage = String(localized: "error_save_failed")
        }
    }
}
