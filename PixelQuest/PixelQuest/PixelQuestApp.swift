import SwiftUI
import SwiftData

@main
struct PixelQuestApp: App {
    @StateObject private var questStore = QuestStore()
    @StateObject private var itemStore = SwiftDataItemStore()
    @StateObject private var logStore = LogStore()
    @StateObject private var sleepStore = SleepStore()
    @StateObject private var exerciseStore = ExerciseStore()
    @StateObject private var healthKitManager = HealthKitManager()
    @StateObject private var bookStore = BookStore()
    @StateObject private var financeStore = SwiftDataFinanceStore()
    @StateObject private var localizationManager = LocalizationManager.shared
    
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            QuestData.self,
            QuestLogData.self,
            ItemData.self,
            WalletData.self,
            WalletSnapshotData.self,
            FinanceEntryData.self,
            BookEntryData.self,
            AssetData.self,
            AssetSnapshotData.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        
        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(questStore)
                .environmentObject(itemStore)
                .environmentObject(logStore)
                .environmentObject(sleepStore)
                .environmentObject(exerciseStore)
                .environmentObject(healthKitManager)
                .environmentObject(bookStore)
                .environmentObject(financeStore)
                .environmentObject(localizationManager)
                .onAppear {
                    let context = sharedModelContainer.mainContext
                    financeStore.configure(modelContext: context)
                    itemStore.configure(modelContext: context)
                }
        }
        .modelContainer(sharedModelContainer)
    }
}

