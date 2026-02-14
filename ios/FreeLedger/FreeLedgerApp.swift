import SwiftUI

@main
struct FreeLedgerApp: App {
    init() {
        do {
            try AppDatabase.shared.seedDefaultCategories()
            try AppDatabase.shared.seedDefaultSettings()
        } catch {
            print("Seed data error: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
