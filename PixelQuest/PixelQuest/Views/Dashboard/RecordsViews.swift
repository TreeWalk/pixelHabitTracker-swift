import SwiftUI

// MARK: - Gym Records View (Read-only for Dashboard)
struct GymRecordsView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var exerciseStore: SwiftDataExerciseStore
    @EnvironmentObject var healthKitManager: HealthKitManager
    @State private var isSyncing = false
    @State private var syncedWorkouts: [WorkoutData] = []
    
    var body: some View {
        GeometryReader { geometry in
            let contentWidth = geometry.size.width - 32
            
            ZStack {
                Color("PixelBg").ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Retro Stat Panel
                        RetroStatPanel(
                            title: "exercise_week_stats".localized,
                            items: [
                                RetroStatItem(
                                    icon: "timer",
                                    value: formatDuration(exerciseStore.weekTotalDuration),
                                    label: "exercise_total_duration".localized,
                                    color: ElementType.metal.color
                                ),
                                RetroStatItem(
                                    icon: "flame.fill",
                                    value: "\(exerciseStore.weekTotalCalories)",
                                    label: "exercise_total_calories".localized,
                                    color: Color("PixelRed")
                                )
                            ],
                            accentColor: ElementType.metal.color
                        )
                        .frame(width: contentWidth)
                        
                        // MARK: - HealthKit Sync Section
                        VStack(spacing: 12) {
                            HStack(spacing: 8) {
                                Image(systemName: "heart.fill")
                                    .font(.system(size: 18))
                                    .foregroundColor(.red)
                                Rectangle()
                                    .fill(Color.red)
                                    .frame(width: 4, height: 20)
                                Text("sleep_sync_health".localized)
                                    .font(.pixel(20))
                                    .foregroundColor(Color("PixelBorder"))
                                Spacer()
                                
                                Button(action: syncFromHealthKit) {
                                    HStack(spacing: 6) {
                                        if isSyncing {
                                            ProgressView()
                                                .scaleEffect(0.7)
                                        } else {
                                            Image(systemName: "arrow.triangle.2.circlepath")
                                                .font(.system(size: 14))
                                        }
                                        Text(isSyncing ? "同步中..." : "同步")
                                            .font(.pixel(14))
                                    }
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(Color.red.opacity(0.85))
                                    .pixelBorderSmall(color: .red)
                                }
                                .disabled(isSyncing)
                            }
                            
                            // Synced Workouts
                            if !syncedWorkouts.isEmpty {
                                ForEach(syncedWorkouts) { workout in
                                    HealthKitWorkoutRow(workout: workout) {
                                        saveHealthKitWorkout(workout)
                                    }
                                }
                            } else {
                                Text("点击同步按钮获取最新数据")
                                    .font(.pixel(12))
                                    .foregroundColor(Color("PixelBorder").opacity(0.5))
                                    .padding(.vertical, 8)
                            }
                        }
                        .padding(16)
                        .background(Color.white)
                        .pixelBorderSmall()
                        .frame(width: contentWidth)
                        
                        // Today's Records Section
                        if !exerciseStore.todayEntries.isEmpty {
                            VStack(spacing: 16) {
                                HStack(spacing: 8) {
                                    Image(systemName: "list.bullet")
                                        .font(.system(size: 18))
                                        .foregroundColor(ElementType.metal.color)
                                    Rectangle()
                                        .fill(ElementType.metal.color)
                                        .frame(width: 4, height: 20)
                                    Text("今日记录")
                                        .font(.pixel(20))
                                        .foregroundColor(Color("PixelBorder"))
                                    Spacer()
                                }
                                
                                ForEach(exerciseStore.todayEntries) { entry in
                                    ExerciseEntryRow(entry: entry)
                                }
                            }
                            .padding(16)
                            .background(Color.white)
                            .pixelBorderSmall()
                            .frame(width: contentWidth)
                        }
                    }
                    .frame(width: geometry.size.width)
                    .padding(.vertical, 16)
                    .padding(.bottom, 20)
                }
            }
        }
        .navigationTitle("运动记录")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { dismiss() }) {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.left")
                        Text("back".localized)
                    }
                    .font(.pixel(16))
                    .foregroundColor(Color("PixelBorder"))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color("PixelAccent"))
                    .pixelBorderSmall()
                }
            }
        }
        .toolbar(.hidden, for: .tabBar)
    }
    
    func formatDuration(_ minutes: Int) -> String {
        if minutes >= 60 {
            let hours = minutes / 60
            let mins = minutes % 60
            return mins > 0 ? "\(hours)h\(mins)m" : "\(hours)h"
        }
        return "\(minutes)m"
    }
    
    func syncFromHealthKit() {
        isSyncing = true
        Task {
            let authorized = await healthKitManager.requestAuthorization()
            guard authorized else {
                isSyncing = false
                return
            }
            
            syncedWorkouts = await healthKitManager.fetchTodayWorkouts()
            isSyncing = false
        }
    }
    
    func saveHealthKitWorkout(_ workout: WorkoutData) {
        let exerciseType: ExerciseType
        switch workout.typeName.lowercased() {
        case let name where name.contains("run"):
            exerciseType = .running
        case let name where name.contains("walk"), let name where name.contains("hik"):
            exerciseType = .hiking
        case let name where name.contains("cycle"), let name where name.contains("bike"):
            exerciseType = .cycling
        case let name where name.contains("swim"):
            exerciseType = .swimming
        case let name where name.contains("yoga"):
            exerciseType = .yoga
        default:
            exerciseType = .strength
        }
        
        exerciseStore.addEntry(
            type: exerciseType,
            duration: workout.durationMinutes,
            calories: Int(workout.calories)
        )
    }
}

// MARK: - Sleep Records View (Read-only for Dashboard)
struct SleepRecordsView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var sleepStore: SwiftDataSleepStore
    @EnvironmentObject var healthKitManager: HealthKitManager
    @State private var isSyncing = false
    @State private var syncedSleepData: SleepData?
    @State private var showSyncError = false
    @State private var quality: Int = 4
    @State private var isSaving = false
    
    var body: some View {
        GeometryReader { geometry in
            let contentWidth = geometry.size.width - 32
            
            ZStack {
                Color("PixelBg").ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Unified Sleep Report Panel
                        RetroReportPanel(
                            title: "Weekly Sleep".localized,
                            icon: "chart.bar.fill",
                            accentColor: ElementType.water.color
                        ) {
                            VStack(spacing: 20) {
                                WeekSleepChart(entries: sleepStore.weekEntries)
                                    .frame(height: 160)
                                
                                Divider()
                                    .background(Color("PixelBorder").opacity(0.1))
                                
                                // Integrated Stats
                                HStack(spacing: 0) {
                                    VStack(spacing: 4) {
                                        Text(String(format: "%.1fh", sleepStore.averageDuration))
                                            .font(.pixel(24))
                                            .foregroundColor(ElementType.water.color)
                                        Text("平均时长")
                                            .font(.pixel(12))
                                            .foregroundColor(Color("PixelBorder").opacity(0.6))
                                    }
                                    .frame(maxWidth: .infinity)
                                    
                                    Rectangle()
                                        .fill(Color("PixelBorder").opacity(0.1))
                                        .frame(width: 2, height: 30)
                                    
                                    VStack(spacing: 4) {
                                        Text(String(format: "%.1f", sleepStore.averageQuality))
                                            .font(.pixel(24))
                                            .foregroundColor(Color("PixelAccent"))
                                        Text("平均质量")
                                            .font(.pixel(12))
                                            .foregroundColor(Color("PixelBorder").opacity(0.6))
                                    }
                                    .frame(maxWidth: .infinity)
                                }
                            }
                        }
                        .frame(width: contentWidth)
                    }
                    .frame(width: geometry.size.width)
                    .padding(.vertical, 16)
                    .padding(.bottom, 20)
                }
            }
        }
        .navigationTitle("睡眠记录")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { dismiss() }) {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.left")
                        Text("back".localized)
                    }
                    .font(.pixel(16))
                    .foregroundColor(Color("PixelBorder"))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color("PixelAccent"))
                    .pixelBorderSmall()
                }
            }
        }
        .toolbar(.hidden, for: .tabBar)
    }
    
    func syncFromHealthKit() {
        isSyncing = true
        Task { @MainActor in
            let authorized = await healthKitManager.requestAuthorization()
            guard authorized else {
                showSyncError = true
                isSyncing = false
                return
            }
            
            if let sleepData = await healthKitManager.fetchLastNightSleep() {
                syncedSleepData = sleepData
            } else {
                showSyncError = true
            }
            
            isSyncing = false
        }
    }
    
    func saveSyncedSleep() {
        guard let sleepData = syncedSleepData else { return }
        isSaving = true
        Task { @MainActor in
            await sleepStore.addEntryWithHealthKitData(
                bedTime: sleepData.bedTime,
                wakeTime: sleepData.wakeTime,
                quality: quality,
                deepSleep: sleepData.deepSleep,
                coreSleep: sleepData.coreSleep,
                remSleep: sleepData.remSleep,
                awakeTime: sleepData.awakeTime,
                sleepScore: sleepData.sleepScore
            )
            isSaving = false
            syncedSleepData = nil
        }
    }
}

// MARK: - Reading Records View (Read-only for Dashboard)
struct ReadingRecordsView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var bookStore: SwiftDataBookStore
    @State private var showAddBook = false
    
    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]
    
    private var readingCount: Int {
        bookStore.books.filter { $0.status == "reading" }.count
    }
    
    private var finishedCount: Int {
        bookStore.books.filter { $0.status == "finished" }.count
    }
    
    var body: some View {
        GeometryReader { geometry in
            let contentWidth = geometry.size.width - 32
            
            ZStack {
                Color("PixelBg").ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Retro Stat Panel
                        RetroStatPanel(
                            title: "Library Overview".localized,
                            items: [
                                RetroStatItem(
                                    icon: "book.fill",
                                    value: "\(readingCount)",
                                    label: "在读",
                                    color: ElementType.wood.color
                                ),
                                RetroStatItem(
                                    icon: "checkmark.circle.fill",
                                    value: "\(finishedCount)",
                                    label: "已读",
                                    color: Color("PixelGreen")
                                )
                            ],
                            accentColor: ElementType.wood.color
                        )
                        .frame(width: contentWidth)
                        
                        // Book Grid
                        LazyVGrid(columns: columns, spacing: 12) {
                            // Add Book Card
                            Button(action: { showAddBook = true }) {
                                AddBookCard()
                            }
                            
                            ForEach(bookStore.books) { book in
                                NavigationLink(destination: BookDetailView(book: book)) {
                                    BookCard(book: book)
                                }
                            }
                        }
                        .frame(width: contentWidth)
                    }
                    .frame(width: geometry.size.width)
                    .padding(.vertical, 16)
                    .padding(.bottom, 20)
                }
            }
        }
        .navigationTitle("library_my_books".localized)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { dismiss() }) {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.left")
                        Text("back".localized)
                    }
                    .font(.pixel(16))
                    .foregroundColor(Color("PixelBorder"))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color("PixelAccent"))
                    .pixelBorderSmall()
                }
            }
        }
        .sheet(isPresented: $showAddBook) {
            AddBookView()
        }
        .toolbar(.hidden, for: .tabBar)
    }
}

// MARK: - Company Records View (Read-only for Dashboard, no banner)
struct CompanyRecordsView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var financeStore: SwiftDataFinanceStore
    @EnvironmentObject var localizationManager: LocalizationManager
    @State private var selectedTab: Int = 0
    @State private var showQuickEntry = false
    @State private var showAssetUpdate = false
    @State private var showStats = false
    
    var body: some View {
        GeometryReader { geometry in
            let contentWidth = max(0, geometry.size.width - 32)
            
            ZStack {
                Color("PixelBg").ignoresSafeArea()
                
                if financeStore.wallets.isEmpty {
                    VStack {
                        ProgressView()
                        Text("Loading...")
                            .font(.pixel(16))
                            .foregroundColor(.secondary)
                            .padding(.top, 8)
                    }
                } else {
                    ScrollView {
                        VStack(spacing: 20) {
                                // Retro Stat Panel
                                RetroStatPanel(
                                    title: "company_finance".localized,
                                    items: [
                                        RetroStatItem(
                                            icon: "building.columns.fill",
                                            value: formatCurrency(financeStore.totalAssets),
                                            label: "总资产",
                                            color: ElementType.earth.color
                                        ),
                                        RetroStatItem(
                                            icon: "arrow.down.circle.fill",
                                            value: formatCurrency(financeStore.monthExpense),
                                            label: "本月支出",
                                            color: Color("PixelRed")
                                        )
                                    ],
                                    accentColor: ElementType.earth.color
                                )
                                .frame(width: contentWidth)
                            
                            VStack(spacing: 0) {
                                // Custom Tab Bar
                                HStack(spacing: 0) {
                                    TabButton(
                                        title: "finance_transactions".localized,
                                        icon: "list.bullet.rectangle.fill",
                                        isSelected: selectedTab == 0,
                                        action: { selectedTab = 0 }
                                    )
                                    
                                    TabButton(
                                        title: "finance_assets".localized,
                                        icon: "chart.pie.fill",
                                        isSelected: selectedTab == 1,
                                        action: { selectedTab = 1 }
                                    )
                                }
                                .background(Color.white)
                                .pixelBorderSmall()
                                .padding(.horizontal, 16)
                                
                                // Tab Content
                                Group {
                                    if selectedTab == 0 {
                                        TransactionsTab(
                                            financeStore: financeStore,
                                            contentWidth: contentWidth,
                                            onQuickEntry: { showQuickEntry = true },
                                            onShowStats: { showStats = true }
                                        )
                                    } else {
                                        AssetTab(
                                            financeStore: financeStore,
                                            contentWidth: contentWidth,
                                            onAssetUpdate: { showAssetUpdate = true }
                                        )
                                    }
                                }
                            }
                        }
                        .frame(width: geometry.size.width)
                        .padding(.vertical, 16)
                    }
                }
            }
        }
        .navigationTitle("company_finance".localized)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { dismiss() }) {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.left")
                        Text("back".localized)
                    }
                    .font(.pixel(16))
                    .foregroundColor(Color("PixelBorder"))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color("PixelAccent"))
                    .pixelBorderSmall()
                }
            }
        }
        .pixelWindow(
            isPresented: $showQuickEntry,
            title: "finance_quick_entry".localized
        ) {
            QuickEntrySheet()
        }
        .pixelWindow(
            isPresented: $showAssetUpdate,
            title: "finance_update_assets".localized
        ) {
            AssetUpdateSheet()
        }
        .pixelWindow(
            isPresented: $showStats,
            title: "finance_stats".localized
        ) {
            TransactionStatsSheet()
        }
        .toolbar(.hidden, for: .tabBar)
    }
    
    private func formatCurrency(_ value: Int) -> String {
        if value >= 10000 {
            return String(format: "¥%.1fW", Double(value) / 10000)
        } else {
            return "¥\(value)"
        }
    }
}

// MARK: - Reusable Stat Card Components

struct SleepStatCard: View {
    let icon: String
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(color)
            Text(value)
                .font(.pixel(22))
                .foregroundColor(color)
            Text(label)
                .font(.pixel(12))
                .foregroundColor(Color("PixelBorder").opacity(0.7))
        }
        .padding()
        .background(Color.white)
        .pixelBorderSmall()
    }
}

struct ReadingStatCard: View {
    let icon: String
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(color)
            Text(value)
                .font(.pixel(22))
                .foregroundColor(color)
            Text(label)
                .font(.pixel(12))
                .foregroundColor(Color("PixelBorder").opacity(0.7))
        }
        .padding()
        .background(Color.white)
        .pixelBorderSmall()
    }
}

struct FinanceStatCard: View {
    let icon: String
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(color)
            Text(value)
                .font(.pixel(22))
                .foregroundColor(color)
            Text(label)
                .font(.pixel(12))
                .foregroundColor(Color("PixelBorder").opacity(0.7))
        }
        .padding()
        .background(Color.white)
        .pixelBorderSmall()
    }
}
