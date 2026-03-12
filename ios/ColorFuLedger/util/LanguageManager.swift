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
        Language(code: "fr", name: "French", localName: "Français"),
        Language(code: "de", name: "German", localName: "Deutsch"),
        Language(code: "es", name: "Spanish", localName: "Español"),
        Language(code: "pt-BR", name: "Portuguese", localName: "Português"),
        Language(code: "ru", name: "Russian", localName: "Русский"),
        Language(code: "ar", name: "Arabic", localName: "العربية"),
        Language(code: "it", name: "Italian", localName: "Italiano"),
        Language(code: "nl", name: "Dutch", localName: "Nederlands"),
        Language(code: "tr", name: "Turkish", localName: "Türkçe"),
        Language(code: "th", name: "Thai", localName: "ไทย"),
        Language(code: "vi", name: "Vietnamese", localName: "Tiếng Việt"),
        Language(code: "id", name: "Indonesian", localName: "Bahasa Indonesia"),
        Language(code: "hi", name: "Hindi", localName: "हिन्दी"),
        Language(code: "ms", name: "Malay", localName: "Bahasa Melayu"),
        Language(code: "pl", name: "Polish", localName: "Polski"),
        Language(code: "sv", name: "Swedish", localName: "Svenska"),
        Language(code: "uk", name: "Ukrainian", localName: "Українська"),
        Language(code: "he", name: "Hebrew", localName: "עברית"),
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
            "en": "en_US", "ja": "ja_JP", "ko": "ko_KR",
            "fr": "fr_FR", "de": "de_DE", "es": "es_ES",
            "pt-BR": "pt_BR", "ru": "ru_RU", "ar": "ar_SA",
            "it": "it_IT", "nl": "nl_NL", "tr": "tr_TR",
            "th": "th_TH", "vi": "vi_VN", "id": "id_ID",
            "hi": "hi_IN", "ms": "ms_MY", "pl": "pl_PL",
            "sv": "sv_SE", "uk": "uk_UA", "he": "he_IL"
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
