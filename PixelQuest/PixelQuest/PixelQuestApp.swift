import SwiftUI
import SwiftData

@main
struct PixelQuestApp: App {
    // SwiftData-based stores (no Supabase)
    @StateObject private var questStore = SwiftDataQuestStore()
    @StateObject private var itemStore = SwiftDataItemStore()
    @StateObject private var logStore = SwiftDataLogStore()
    @StateObject private var sleepStore = SwiftDataSleepStore()
    @StateObject private var exerciseStore = SwiftDataExerciseStore()
    @StateObject private var bookStore = SwiftDataBookStore()
    @StateObject private var financeStore = SwiftDataFinanceStore()
    
    // Other managers
    @StateObject private var healthKitManager = HealthKitManager()
    @StateObject private var localizationManager = LocalizationManager.shared
    
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            // Quest module
            QuestData.self,
            QuestLogData.self,
            // Item module
            ItemData.self,
            // Finance module
            WalletData.self,
            WalletSnapshotData.self,
            FinanceEntryData.self,
            AssetData.self,
            AssetSnapshotData.self,
            // Book module
            BookEntryData.self,
            // Sleep module
            SleepEntryData.self,
            // Exercise module
            ExerciseEntryData.self,
            // Log module
            LogEntryData.self
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
                    // Configure all SwiftData stores
                    questStore.configure(modelContext: context)
                    itemStore.configure(modelContext: context)
                    logStore.configure(modelContext: context)
                    sleepStore.configure(modelContext: context)
                    exerciseStore.configure(modelContext: context)
                    bookStore.configure(modelContext: context)
                    financeStore.configure(modelContext: context)
                }
        }
        .modelContainer(sharedModelContainer)
    }
}


