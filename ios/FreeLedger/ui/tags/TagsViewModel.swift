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
}
