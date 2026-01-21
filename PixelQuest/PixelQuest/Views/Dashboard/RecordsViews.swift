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
                        // Header with Sync Button
                        HStack(spacing: 8) {
                            Image(systemName: "dumbbell.fill")
                                .font(.system(size: 18))
                                .foregroundColor(Color("PixelBlue"))
                            Rectangle()
                                .fill(Color("PixelBlue"))
                                .frame(width: 4, height: 20)
                            Text("exercise_log".localized)
                                .font(.pixel(20))
                                .foregroundColor(Color("PixelBorder"))
                            
                            Spacer()
                            
                            // HealthKit Sync Button (compact)
                            Button(action: syncFromHealthKit) {
                                HStack(spacing: 4) {
                                    if isSyncing {
                                        ProgressView()
                                            .scaleEffect(0.7)
                                    } else {
                                        Image(systemName: "heart.fill")
                                            .font(.system(size: 12))
                                    }
                                    Text(isSyncing ? "同步中" : "同步")
                                        .font(.pixel(12))
                                }
                                .foregroundColor(.white)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(Color.red.opacity(0.8))
                                .pixelBorderSmall(color: Color.red)
                            }
                            .disabled(isSyncing)
                        }
                        .frame(width: contentWidth, alignment: .leading)
                        
                        // Synced Workouts from HealthKit
                        if !syncedWorkouts.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("来自 Apple Health")
                                    .font(.pixel(14))
                                    .foregroundColor(Color("PixelBlue"))
                                    .frame(width: contentWidth, alignment: .leading)
                                
                                ForEach(syncedWorkouts) { workout in
                                    HealthKitWorkoutRow(workout: workout) {
                                        saveHealthKitWorkout(workout)
                                    }
                                    .frame(width: contentWidth)
                                }
                            }
                        }
                        
                        // Weekly Stats Section
                        VStack(spacing: 16) {
                            HStack(spacing: 8) {
                                Image(systemName: "chart.bar.fill")
                                    .font(.system(size: 18))
                                    .foregroundColor(Color("PixelBlue"))
                                Rectangle()
                                    .fill(Color("PixelBlue"))
                                    .frame(width: 4, height: 20)
                                Text("exercise_week_stats".localized)
                                    .font(.pixel(20))
                                    .foregroundColor(Color("PixelBorder"))
                                Spacer()
                            }
                            .frame(width: contentWidth, alignment: .leading)
                            
                            // Stats Cards
                            HStack(spacing: 12) {
                                ExerciseStatCard(
                                    icon: "timer",
                                    value: formatDuration(exerciseStore.weekTotalDuration),
                                    label: "exercise_total_duration".localized,
                                    color: Color("PixelBlue")
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
                            .frame(width: contentWidth)
                        }
                        
                        // Today's Records Section
                        if !exerciseStore.todayEntries.isEmpty {
                            VStack(spacing: 16) {
                                HStack(spacing: 8) {
                                    Image(systemName: "list.bullet")
                                        .font(.system(size: 18))
                                        .foregroundColor(Color("PixelBlue"))
                                    Rectangle()
                                        .fill(Color("PixelBlue"))
                                        .frame(width: 4, height: 20)
                                    Text("今日记录")
                                        .font(.pixel(20))
                                        .foregroundColor(Color("PixelBorder"))
                                    Spacer()
                                }
                                .frame(width: contentWidth, alignment: .leading)
                                
                                ForEach(exerciseStore.todayEntries) { entry in
                                    ExerciseEntryRow(entry: entry)
                                        .frame(width: contentWidth)
                                }
                            }
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
                        // Header with Sync Button
                        HStack(spacing: 8) {
                            Image(systemName: "moon.zzz.fill")
                                .font(.system(size: 18))
                                .foregroundColor(Color("PixelBlue"))
                            Rectangle()
                                .fill(Color("PixelBlue"))
                                .frame(width: 4, height: 20)
                            Text("sleep_log".localized)
                                .font(.pixel(20))
                                .foregroundColor(Color("PixelBorder"))
                            
                            Spacer()
                            
                            // HealthKit Sync Button (compact)
                            Button(action: syncFromHealthKit) {
                                HStack(spacing: 4) {
                                    if isSyncing {
                                        ProgressView()
                                            .scaleEffect(0.7)
                                    } else {
                                        Image(systemName: "heart.fill")
                                            .font(.system(size: 12))
                                    }
                                    Text(isSyncing ? "同步中" : "同步")
                                        .font(.pixel(12))
                                }
                                .foregroundColor(.white)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(Color.red.opacity(0.8))
                                .pixelBorderSmall(color: Color.red)
                            }
                            .disabled(isSyncing)
                        }
                        .frame(width: contentWidth, alignment: .leading)
                        
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
    
    var body: some View {
        GeometryReader { geometry in
            let contentWidth = geometry.size.width - 32
            
            ZStack {
                Color("PixelBg").ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Section Title
                        HStack(spacing: 8) {
                            Image(systemName: "books.vertical.fill")
                                .font(.system(size: 18))
                                .foregroundColor(Color("PixelBlue"))
                            Rectangle()
                                .fill(Color("PixelBlue"))
                                .frame(width: 4, height: 20)
                            Text("library_my_books".localized)
                                .font(.pixel(20))
                                .foregroundColor(Color("PixelBorder"))
                            Spacer()
                            
                            Text(String(format: "library_books_count".localized, bookStore.books.count))
                                .font(.pixel(14))
                                .foregroundColor(Color("PixelBorder").opacity(0.7))
                        }
                        .frame(width: contentWidth, alignment: .leading)
                        
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
                            // No Banner - this is the key difference from CompanyDetailView
                            
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
}

