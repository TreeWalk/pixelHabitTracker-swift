import SwiftUI
import SwiftData

@main
struct PixelQuestApp: App {
    // SwiftData-based stores (no Supabase)
    @StateObject private var itemStore = SwiftDataItemStore()
    @StateObject private var financeStore = SwiftDataFinanceStore()

    // Other managers
    @StateObject private var localizationManager = LocalizationManager.shared

    // Loading state
    @State private var isLoading = true
    @State private var loadingProgress: Double = 0.0
    @State private var loadingMessage = "Initializing..."

    // Scene phase for foreground refresh
    @Environment(\.scenePhase) private var scenePhase
    
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            // Item module
            ItemData.self,
            // Finance module
            WalletData.self,
            WalletSnapshotData.self,
            FinanceEntryData.self,
            AssetData.self,
            AssetSnapshotData.self
        ])

        // 首先尝试使用持久化存储
        let persistentConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(for: schema, configurations: [persistentConfiguration])
        } catch {
            print("⚠️ 无法创建持久化存储，尝试使用内存存储: \(error)")

            // 降级方案：使用内存存储
            let inMemoryConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
            do {
                return try ModelContainer(for: schema, configurations: [inMemoryConfiguration])
            } catch {
                print("❌ 内存存储也失败: \(error)")
                fatalError("无法初始化任何数据存储: \(error)")
            }
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
                        .environmentObject(itemStore)
                        .environmentObject(financeStore)
                        .environmentObject(localizationManager)
                }
            }
            .onAppear {
                initializeApp()
            }
            .onChange(of: scenePhase) { oldPhase, newPhase in
                if newPhase == .active && !isLoading {
                    // 从后台/快捷指令返回时刷新财务数据
                    financeStore.reloadData()
                }
            }
        }
        .modelContainer(sharedModelContainer)
    }

    // MARK: - Initialization
    private func initializeApp() {
        Task { @MainActor in
            let context = sharedModelContainer.mainContext
            let totalSteps = 2.0

            // Step 1: Item Store
            loadingMessage = "Loading items..."
            loadingProgress = 1.0 / totalSteps
            await itemStore.configure(modelContext: context)

            // Step 2: Finance Store
            loadingMessage = "Loading finance data..."
            loadingProgress = 2.0 / totalSteps
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

