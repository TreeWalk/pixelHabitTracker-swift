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
                        // MARK: - Weekly Stats Section
                        VStack(spacing: 16) {
                            // Section Title (matching GymDetailView style)
                            HStack(spacing: 8) {
                                Image(systemName: "chart.bar.fill")
                                    .font(.system(size: 18))
                                    .foregroundColor(ElementType.metal.color)
                                Rectangle()
                                    .fill(ElementType.metal.color)
                                    .frame(width: 4, height: 20)
                                Text("exercise_week_stats".localized)
                                    .font(.pixel(20))
                                    .foregroundColor(Color("PixelBorder"))
                                Spacer()
                            }
                            
                            // Stats Cards
                            HStack(spacing: 12) {
                                ExerciseStatCard(
                                    icon: "timer",
                                    value: formatDuration(exerciseStore.weekTotalDuration),
                                    label: "exercise_total_duration".localized,
                                    color: ElementType.metal.color
                                )
                                .frame(maxWidth: .infinity)
                                
                                ExerciseStatCard(
                                    icon: "flame.fill",
                                    value: "\(exerciseStore.weekTotalCalories)",
                                    label: "exercise_total_calories".localized,
                                    color: Color("PixelRed")
                                )
                                .frame(maxWidth: .infinity)
                            }
                        }
                        .padding(16)
                        .background(Color.white)
                        .pixelBorderSmall()
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
                        // MARK: - Sleep Stats Section
                        VStack(spacing: 16) {
                            // Section Title
                            HStack(spacing: 8) {
                                Image(systemName: "moon.fill")
                                    .font(.system(size: 18))
                                    .foregroundColor(ElementType.water.color)
                                Rectangle()
                                    .fill(ElementType.water.color)
                                    .frame(width: 4, height: 20)
                                Text("sleep_log".localized)
                                    .font(.pixel(20))
                                    .foregroundColor(Color("PixelBorder"))
                                Spacer()
                            }
                            
                            // Stats Cards
                            HStack(spacing: 12) {
                                SleepStatCard(
                                    icon: "clock.fill",
                                    value: String(format: "%.1fh", sleepStore.averageDuration),
                                    label: "平均时长",
                                    color: ElementType.water.color
                                )
                                .frame(maxWidth: .infinity)
                                
                                SleepStatCard(
                                    icon: "star.fill",
                                    value: String(format: "%.1f", sleepStore.averageQuality),
                                    label: "平均质量",
                                    color: Color("PixelAccent")
                                )
                                .frame(maxWidth: .infinity)
                            }
                        }
                        .padding(16)
                        .background(Color.white)
                        .pixelBorderSmall()
                        .frame(width: contentWidth)
                        
                        // HealthKit Sync Button
                        HStack {
                            Spacer()
                            Button(action: syncFromHealthKit) {
                                HStack(spacing: 6) {
                                    if isSyncing {
                                        ProgressView()
                                            .scaleEffect(0.7)
                                    } else {
                                        Image(systemName: "heart.fill")
                                            .font(.system(size: 14))
                                    }
                                    Text(isSyncing ? "同步中..." : "从 Apple Health 同步")
                                        .font(.pixel(14))
                                }
                                .foregroundColor(.white)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .background(Color.red.opacity(0.85))
                                .overlay(
                                    Rectangle()
                                        .stroke(Color.red, lineWidth: 2)
                                )
                                .background(
                                    Rectangle()
                                        .fill(Color.red.opacity(0.3))
                                        .offset(x: 2, y: 2)
                                )
                            }
                            .disabled(isSyncing)
                        }
                        .frame(width: contentWidth)
                        
                        // Synced Sleep Score Display
                        if let sleepData = syncedSleepData {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("来自 Apple Health")
                                    .font(.pixel(14))
                                    .foregroundColor(Color("PixelBlue"))
                                
                                SleepScoreCard(sleepData: sleepData)
                                
                                // Quality Rating for synced data
                                VStack(spacing: 12) {
                                    Text("sleep_quality".localized)
                                        .font(.pixel(16))
                                        .foregroundColor(Color("PixelBorder"))
                                    
                                    HStack(spacing: 12) {
                                        ForEach(1...5, id: \.self) { index in
                                            Button(action: { quality = index }) {
                                                Image(systemName: index <= quality ? "star.fill" : "star")
                                                    .font(.system(size: 28))
                                                    .foregroundColor(index <= quality ? Color("PixelAccent") : Color.gray.opacity(0.4))
                                            }
                                        }
                                    }
                                    
                                    Button(action: saveSyncedSleep) {
                                        HStack {
                                            if isSaving {
                                                ProgressView()
                                                    .scaleEffect(0.8)
                                            }
                                            Text("save_workout".localized)
                                                .font(.pixel(14))
                                        }
                                        .foregroundColor(.white)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 8)
                                        .background(Color("PixelGreen"))
                                        .pixelBorderSmall(color: Color("PixelGreen"))
                                    }
                                    .disabled(isSaving)
                                }
                                .padding()
                                .background(Color.white)
                                .pixelBorderSmall()
                            }
                            .frame(width: contentWidth)
                        }
                        
                        // Weekly Trend Section
                        VStack(spacing: 16) {
                            HStack(spacing: 8) {
                                Image(systemName: "chart.bar.fill")
                                    .font(.system(size: 18))
                                    .foregroundColor(Color("PixelBlue"))
                                Rectangle()
                                    .fill(Color("PixelBlue"))
                                    .frame(width: 4, height: 20)
                                Text("sleep_week_trend".localized)
                                    .font(.pixel(20))
                                    .foregroundColor(Color("PixelBorder"))
                                Spacer()
                            }
                            .frame(width: contentWidth, alignment: .leading)
                            
                            WeekSleepChart(entries: sleepStore.weekEntries)
                                .frame(width: contentWidth, height: 160)
                                .background(Color.white)
                                .pixelBorderSmall()
                            
                            HStack(spacing: 20) {
                                SleepStatBox(
                                    title: "sleep_avg_duration".localized,
                                    value: String(format: "%.1fh", sleepStore.averageDuration),
                                    icon: "bed.double.fill"
                                )
                                .frame(maxWidth: .infinity)
                                
                                SleepStatBox(
                                    title: "sleep_avg_quality".localized,
                                    value: String(format: "%.1f", sleepStore.averageQuality),
                                    icon: "star.fill"
                                )
                                .frame(maxWidth: .infinity)
                            }
                            .frame(width: contentWidth)
                        }
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
                        // MARK: - Reading Stats Section
                        VStack(spacing: 16) {
                            // Section Title
                            HStack(spacing: 8) {
                                Image(systemName: "book.fill")
                                    .font(.system(size: 18))
                                    .foregroundColor(ElementType.wood.color)
                                Rectangle()
                                    .fill(ElementType.wood.color)
                                    .frame(width: 4, height: 20)
                                Text("library_my_books".localized)
                                    .font(.pixel(20))
                                    .foregroundColor(Color("PixelBorder"))
                                Spacer()
                            }
                            
                            // Stats Cards
                            HStack(spacing: 12) {
                                ReadingStatCard(
                                    icon: "book.fill",
                                    value: "\(readingCount)",
                                    label: "在读",
                                    color: ElementType.wood.color
                                )
                                .frame(maxWidth: .infinity)
                                
                                ReadingStatCard(
                                    icon: "checkmark.circle.fill",
                                    value: "\(finishedCount)",
                                    label: "已读",
                                    color: Color("PixelGreen")
                                )
                                .frame(maxWidth: .infinity)
                            }
                        }
                        .padding(16)
                        .background(Color.white)
                        .pixelBorderSmall()
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
                            // MARK: - Finance Stats Section
                            VStack(spacing: 16) {
                                // Section Title
                                HStack(spacing: 8) {
                                    Image(systemName: "yensign.circle.fill")
                                        .font(.system(size: 18))
                                        .foregroundColor(ElementType.earth.color)
                                    Rectangle()
                                        .fill(ElementType.earth.color)
                                        .frame(width: 4, height: 20)
                                    Text("company_finance".localized)
                                        .font(.pixel(20))
                                        .foregroundColor(Color("PixelBorder"))
                                    Spacer()
                                }
                                
                                // Stats Cards
                                HStack(spacing: 12) {
                                    FinanceStatCard(
                                        icon: "building.columns.fill",
                                        value: formatCurrency(financeStore.totalAssets),
                                        label: "总资产",
                                        color: ElementType.earth.color
                                    )
                                    .frame(maxWidth: .infinity)
                                    
                                    FinanceStatCard(
                                        icon: "arrow.down.circle.fill",
                                        value: formatCurrency(financeStore.monthExpense),
                                        label: "本月支出",
                                        color: Color("PixelRed")
                                    )
                                    .frame(maxWidth: .infinity)
                                }
                            }
                            .padding(16)
                            .background(Color.white)
                            .pixelBorderSmall()
                            .padding(.horizontal, 16)
                            
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
