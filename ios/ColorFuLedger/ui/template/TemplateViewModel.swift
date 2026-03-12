import Foundation
import Observation

struct TemplateDisplayItem: Identifiable {
    let id: String
    let template: TransactionTemplate
    let category: Category?
}

@Observable
final class TemplateViewModel {
    var items: [TemplateDisplayItem] = []
    var errorMessage: String?
    var currencyCode: String = "CNY"

    private let templateRepository: TransactionTemplateRepositoryProtocol
    private let categoryRepository: CategoryRepositoryProtocol
    private let settingsRepository: SettingsRepositoryProtocol

    init(templateRepository: TransactionTemplateRepositoryProtocol,
         categoryRepository: CategoryRepositoryProtocol,
         settingsRepository: SettingsRepositoryProtocol) {
        self.templateRepository = templateRepository
        self.categoryRepository = categoryRepository
        self.settingsRepository = settingsRepository
    }

    func loadData() {
        do {
            currencyCode = try settingsRepository.getCurrency()
            let templates = try templateRepository.getAll()
            let categoryDict = try categoryRepository.getAllAsDict()
            items = templates.map { t in
                TemplateDisplayItem(id: t.id, template: t, category: categoryDict[t.categoryId])
            }
        } catch {
            AppLogger.ui.error("TemplateViewModel loadData failed: \(error.localizedDescription)")
            errorMessage = L("error_load_failed")
        }
    }

    func addTemplate(title: String, amount: Int64, type: String, categoryId: String, note: String?) {
        do {
            let template = TransactionTemplate(
                title: title, amount: amount, type: type,
                categoryId: categoryId, note: note
            )
            try templateRepository.insert(template)
            loadData()
        } catch {
            AppLogger.ui.error("TemplateViewModel addTemplate failed: \(error.localizedDescription)")
            errorMessage = L("error_save_failed")
        }
    }

    func deleteTemplate(id: String) {
        do {
            try templateRepository.delete(id: id)
            loadData()
        } catch {
            AppLogger.ui.error("TemplateViewModel deleteTemplate failed: \(error.localizedDescription)")
            errorMessage = L("error_delete_failed")
        }
    }
}
