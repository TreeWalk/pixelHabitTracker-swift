import Foundation
import SwiftUI

class LocalizationManager: ObservableObject {
    static let shared = LocalizationManager()
    
    @Published var currentLanguage: String {
        didSet {
            UserDefaults.standard.set(currentLanguage, forKey: "AppLanguage")
            updateBundle()
        }
    }
    
    private var bundle: Bundle?
    
    init() {
        let defaultLanguage: String
        if #available(iOS 16, *) {
            defaultLanguage = Locale.current.language.languageCode?.identifier ?? "en"
        } else {
            defaultLanguage = Locale.current.languageCode ?? "en"
        }
        let savedLanguage = UserDefaults.standard.string(forKey: "AppLanguage") ?? defaultLanguage
        self.currentLanguage = savedLanguage
        updateBundle()
    }
    
    private func updateBundle() {
        if let path = Bundle.main.path(forResource: currentLanguage, ofType: "lproj"),
           let bundle = Bundle(path: path) {
            self.bundle = bundle
        } else {
            self.bundle = Bundle.main
        }
    }
    
    func localizedString(_ key: String, comment: String = "") -> String {
        return bundle?.localizedString(forKey: key, value: nil, table: nil) ?? key
    }
}

// MARK: - String Extension

extension String {
    var localized: String {
        LocalizationManager.shared.localizedString(self)
    }
    
    func localized(with arguments: CVarArg...) -> String {
        String(format: LocalizationManager.shared.localizedString(self), arguments: arguments)
    }
}
