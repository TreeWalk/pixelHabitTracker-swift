import SwiftUI

struct DashboardView: View {
    @EnvironmentObject var questStore: SwiftDataQuestStore
    @EnvironmentObject var bookStore: SwiftDataBookStore
    @EnvironmentObject var exerciseStore: SwiftDataExerciseStore
    @EnvironmentObject var financeStore: SwiftDataFinanceStore
    @EnvironmentObject var sleepStore: SwiftDataSleepStore
    @StateObject private var statsService = PlayerStatsService()
    @State private var showSettings = false
    @Binding var hideTabBar: Bool
    
    // Detail sheet states
    @State private var showExerciseDetail = false
    @State private var showBookDetail = false
    @State private var showSleepDetail = false
    @State private var showFinanceDetail = false
    @State private var showQuestLog = false
    
    // Predefined locations for detail views
    private let gymLocation = Location(id: 2, name: "Gym", icon: "gym", banner: "gymLong", type: "Strength", desc: "Train your strength stats.", unlocked: true)
    private let libraryLocation = Location(id: 3, name: "Library", icon: "library", banner: "libraryLongMorning", type: "Intellect", desc: "Ancient knowledge lies here.", unlocked: true)
    private let homeLocation = Location(id: 1, name: "Home Base", icon: "home", banner: "homeLong", type: "Rest", desc: "Safe zone. Recover HP here.", unlocked: true)
    private let companyLocation = Location(id: 4, name: "Company", icon: "company", banner: "companyLong", type: "Wealth", desc: "Earn gold here.", unlocked: true)
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Header
                    headerSection
                    
                    // Five Element Cards
                    VStack(spacing: 12) {
                        FiveElementCard(
                            element: .fire,
                            title: "Strength",
                            value: Double(statsService.strength),
                            maxValue: 100,
                            label: "\(exerciseStore.weekTotalDuration) min",
                            onDetailTap: { showExerciseDetail = true }
                        )
                        
                        FiveElementCard(
                            element: .wood,
                            title: "Intellect",
                            value: Double(statsService.intelligence),
                            maxValue: 100,
                            label: "\(bookStore.readingBooks.count) 本在读",
                            onDetailTap: { showBookDetail = true }
                        )
                        
                        FiveElementCard(
                            element: .water,
                            title: "Health",
                            value: Double(statsService.vitality),
                            maxValue: 100,
                            label: "VIT \(statsService.vitality)",
                            onDetailTap: { showSleepDetail = true }
                        )
                        
                        FiveElementCard(
                            element: .metal,
                            title: "Wealth",
                            value: Double(min(statsService.wealth, 100)),
                            maxValue: 100,
                            label: "¥\(financeStore.netWorth / 100)",
                            onDetailTap: { showFinanceDetail = true }
                        )
                        
                        FiveElementCard(
                            element: .earth,
                            title: "Spirit",
                            value: Double(questStore.completionPercentage),
                            maxValue: 100,
                            label: "\(questStore.completedQuests.count)/\(questStore.quests.count)",
                            onDetailTap: { showQuestLog = true }
                        )
                    }
                    .padding(.horizontal)
                }
                .padding(.bottom, 100)
            }
            .background(Color("PixelBg"))
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
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("dashboard_title".localized)
                        .font(.pixel(28))
                        .foregroundColor(Color("PixelBorder"))

                }
                
                Spacer()
                
                // Pixel avatar - tap to settings
                Button(action: { showSettings = true }) {
                    ZStack {
                        Rectangle()
                            .fill(Color("PixelAccent").opacity(0.2))
                            .frame(width: 56, height: 56)
                        
                        Image(systemName: "person.fill")
                            .font(.system(size: 24))
                            .foregroundColor(Color("PixelAccent"))
                    }
                    .overlay(
                        Rectangle()
                            .stroke(Color("PixelBorder"), lineWidth: 2)
                    )
                }
            }
        }
        .padding()
        .sheet(isPresented: $showSettings) {
            NavigationStack {
                SettingsView()
                    .toolbar {
                        ToolbarItem(placement: .confirmationAction) {
                            Button("done".localized) { showSettings = false }
                                .font(.pixel(16))
                        }
                    }
            }
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
