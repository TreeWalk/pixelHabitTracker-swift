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

    // Loading state
    @State private var isLoading = true
    @State private var loadingProgress: Double = 0.0
    @State private var loadingMessage = "Initializing..."
    
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
            ZStack {
                if isLoading {
                    SplashView(
                        isLoading: $isLoading,
                        loadingProgress: $loadingProgress,
                        loadingMessage: $loadingMessage
                    )
                } else {
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
                }
            }
            .onAppear {
                initializeApp()
            }
        }
        .modelContainer(sharedModelContainer)
    }

    // MARK: - Initialization
    private func initializeApp() {
        Task { @MainActor in
            let context = sharedModelContainer.mainContext
            let totalSteps = 7.0

            // Step 1: Quest Store
            loadingMessage = "Loading quests..."
            loadingProgress = 1.0 / totalSteps
            await questStore.configure(modelContext: context)

            // Step 2: Item Store
            loadingMessage = "Loading items..."
            loadingProgress = 2.0 / totalSteps
            await itemStore.configure(modelContext: context)

            // Step 3: Log Store
            loadingMessage = "Loading logs..."
            loadingProgress = 3.0 / totalSteps
            await logStore.configure(modelContext: context)

            // Step 4: Sleep Store
            loadingMessage = "Loading sleep data..."
            loadingProgress = 4.0 / totalSteps
            await sleepStore.configure(modelContext: context)

            // Step 5: Exercise Store
            loadingMessage = "Loading exercise data..."
            loadingProgress = 5.0 / totalSteps
            await exerciseStore.configure(modelContext: context)

            // Step 6Book Store
            loadingMessage = "Loading books..."
            loadingProgress = 6.0 / totalSteps
            await bookStore.configure(modelContext: context)

            // Step 7: Finance Store
            loadingMessage = "Loading finance data..."
            loadingProgress = 7.0 / totalSteps
            await financeStore.configure(modelContext: context)

            // Complete
            loadingMessage = "Ready!"
            loadingProgress = 1.0

            // Small delay to show completion
            try? await Task.sleep(nanoseconds: 300_000_000) // 0.3 seconds

            withAnimation {
                isLoading = false
            }
        }
    }
}


