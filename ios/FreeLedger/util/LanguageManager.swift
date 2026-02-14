import Foundation
import Observation

@MainActor @Observable
final class LanguageManager {
    static let shared = LanguageManager()
    nonisolated(unsafe) static var bundle: Bundle = .main

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
            Self.bundle = Self.loadBundle(currentLanguage)
            Self.updateLocale(currentLanguage)
            UserDefaults.standard.set(currentLanguage, forKey: Self.languageKey)
            refreshId += 1
        }
    }

    var refreshId: Int = 0

    private init() {
        let saved = UserDefaults.standard.string(forKey: Self.languageKey)
        let code = saved ?? "zh-Hans"
        self.currentLanguage = code
        Self.bundle = Self.loadBundle(code)
        Self.updateLocale(code)
    }

    private static func loadBundle(_ code: String) -> Bundle {
        if let path = Bundle.main.path(forResource: code, ofType: "lproj"),
           let bundle = Bundle(path: path) {
            return bundle
        }
        return .main
    }

    var currentLanguageDisplay: String {
        Self.supportedLanguages.first { $0.code == currentLanguage }?.localName ?? currentLanguage
    }

    nonisolated(unsafe) static var locale: Locale = Locale(identifier: "zh-Hans")

    private static func updateLocale(_ code: String) {
        let map: [String: String] = [
            "zh-Hans": "zh_CN", "zh-Hant": "zh_TW",
            "en": "en_US", "ja": "ja_JP", "ko": "ko_KR"
        ]
        locale = Locale(identifier: map[code] ?? code)
    }
}

func L(_ key: String) -> String {
    NSLocalizedString(key, bundle: LanguageManager.bundle, comment: "")
}

func L(_ key: String, _ args: CVarArg...) -> String {
    let format = NSLocalizedString(key, bundle: LanguageManager.bundle, comment: "")
    return String(format: format, arguments: args)
}
