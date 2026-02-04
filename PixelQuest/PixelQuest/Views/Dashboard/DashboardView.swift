import SwiftUI

struct DashboardView: View {
    @EnvironmentObject var questStore: SwiftDataQuestStore
    @EnvironmentObject var bookStore: SwiftDataBookStore
    @EnvironmentObject var exerciseStore: SwiftDataExerciseStore
    @EnvironmentObject var financeStore: SwiftDataFinanceStore
    @EnvironmentObject var sleepStore: SwiftDataSleepStore
    @StateObject private var statsService = PlayerStatsService()
    @Binding var hideTabBar: Bool
    
    // Detail sheet states
    @State private var showExerciseDetail = false
    @State private var showBookDetail = false
    @State private var showSleepDetail = false
    @State private var showFinanceDetail = false
    @State private var showQuestLog = false
    
    var body: some View {
        NavigationStack {
            AsymmetricDashboardView(
                onStrengthTap: { showExerciseDetail = true },
                onIntellectTap: { showBookDetail = true },
                onHealthTap: { showSleepDetail = true },
                onWealthTap: { showFinanceDetail = true },
                onSpiritTap: { showQuestLog = true }
            )
            .background(Color("PixelBg").ignoresSafeArea())
        }
        .onAppear {
            statsService.configure(
                questStore: questStore,
                bookStore: bookStore,
                exerciseStore: exerciseStore,
                financeStore: financeStore
            )
        }
        // Detail Navigation Destinations
        .navigationDestination(isPresented: $showExerciseDetail) {
            GymRecordsView()
                .onAppear { hideTabBar = true }
                .onDisappear { hideTabBar = false }
        }
        .navigationDestination(isPresented: $showBookDetail) {
            ReadingRecordsView()
                .onAppear { hideTabBar = true }
                .onDisappear { hideTabBar = false }
        }
        .navigationDestination(isPresented: $showSleepDetail) {
            SleepRecordsView()
                .onAppear { hideTabBar = true }
                .onDisappear { hideTabBar = false }
        }
        .navigationDestination(isPresented: $showFinanceDetail) {
            CompanyRecordsView()
                .onAppear { hideTabBar = true }
                .onDisappear { hideTabBar = false }
        }
        .navigationDestination(isPresented: $showQuestLog) {
            QuestLogView()
                .onAppear { hideTabBar = true }
                .onDisappear { hideTabBar = false }
        }
    }
}

#Preview {
    DashboardView(hideTabBar: .constant(false))
        .environmentObject(SwiftDataQuestStore())
        .environmentObject(SwiftDataBookStore())
        .environmentObject(SwiftDataExerciseStore())
        .environmentObject(SwiftDataFinanceStore())
        .environmentObject(SwiftDataSleepStore())
}
