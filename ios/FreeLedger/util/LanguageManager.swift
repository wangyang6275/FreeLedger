import Foundation
import Observation

nonisolated(unsafe) private var bundleKey: UInt8 = 0

final class LanguageBundle: Bundle, @unchecked Sendable {
    override func localizedString(forKey key: String, value: String?, table tableName: String?) -> String {
        if let bundle = objc_getAssociatedObject(self, &bundleKey) as? Bundle {
            return bundle.localizedString(forKey: key, value: value, table: tableName)
        }
        return super.localizedString(forKey: key, value: value, table: tableName)
    }
}

@MainActor @Observable
final class LanguageManager {
    static let shared = LanguageManager()

    struct Language: Identifiable, Hashable, Sendable {
        let code: String
        let name: String
        let localName: String
        var id: String { code }
    }

    static let supportedLanguages: [Language] = [
        Language(code: "zh-Hans", name: "Chinese Simplified", localName: "简体中文"),
        Language(code: "zh-Hant", name: "Chinese Traditional", localName: "繁體中文"),
        Language(code: "en", name: "English", localName: "English"),
        Language(code: "ja", name: "Japanese", localName: "日本語"),
        Language(code: "ko", name: "Korean", localName: "한국어"),
    ]

    private static let languageKey = "app_language"

    var currentLanguage: String {
        didSet {
            applyLanguage(currentLanguage)
            UserDefaults.standard.set(currentLanguage, forKey: Self.languageKey)
            refreshId += 1
        }
    }

    var refreshId: Int = 0

    private init() {
        let saved = UserDefaults.standard.string(forKey: Self.languageKey)
        self.currentLanguage = saved ?? "zh-Hans"
        applyLanguage(currentLanguage)
    }

    private func applyLanguage(_ code: String) {
        object_setClass(Bundle.main, LanguageBundle.self)

        if let path = Bundle.main.path(forResource: code, ofType: "lproj"),
           let bundle = Bundle(path: path) {
            objc_setAssociatedObject(Bundle.main, &bundleKey, bundle, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        } else {
            objc_setAssociatedObject(Bundle.main, &bundleKey, nil, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }

    var currentLanguageDisplay: String {
        Self.supportedLanguages.first { $0.code == currentLanguage }?.localName ?? currentLanguage
    }
}
