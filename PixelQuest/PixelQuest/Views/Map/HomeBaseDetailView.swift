import SwiftUI

struct HomeBaseDetailView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var sleepStore: SwiftDataSleepStore
    @EnvironmentObject var healthKitManager: HealthKitManager
    @EnvironmentObject var localizationManager: LocalizationManager
    let location: Location
    
    @State private var bedTime = Calendar.current.date(bySettingHour: 22, minute: 30, second: 0, of: Date()) ?? Date()
    @State private var wakeTime = Calendar.current.date(bySettingHour: 7, minute: 0, second: 0, of: Date()) ?? Date()
    @State private var quality: Int = 4
    @State private var isSaving = false
    @State private var isSyncing = false
    @State private var syncedSleepData: SleepData?
    @State private var showSyncError = false
    
    var body: some View {
        GeometryReader { geometry in
            let contentWidth = geometry.size.width - 32
            
            ZStack {
                Color("PixelBg").ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Banner
                        if let banner = location.banner {
                            Image(banner)
                                .resizable()
                                .interpolation(.none)
                                .aspectRatio(contentMode: .fill)
                                .frame(width: contentWidth, height: 180)
                                .clipped()
                                .pixelBorderSmall()
                        }
                        
                        // Sleep Log Section
                        VStack(spacing: 16) {
                            // Section Title
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
                            }
                            .frame(width: contentWidth, alignment: .leading)
                            
                            // HealthKit Sync Button
                            Button(action: syncFromHealthKit) {
                                HStack(spacing: 8) {
                                    if isSyncing {
                                        ProgressView()
                                            .scaleEffect(0.8)
                                    } else {
                                        Image(systemName: "heart.fill")
                                    }
                                    Text(isSyncing ? "sleep_syncing".localized : "sleep_sync_health".localized)
                                        .font(.pixel(14))
                                }
                                .foregroundColor(.white)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                                .background(Color.red.opacity(0.8))
                                .pixelBorderSmall(color: Color.red)
                            }
                            .disabled(isSyncing)
                            .frame(width: contentWidth, alignment: .trailing)
                            
                            // Synced Sleep Score Display
                            if let sleepData = syncedSleepData {
                                SleepScoreCard(sleepData: sleepData)
                                    .frame(width: contentWidth)
                            }
                            
                            // Time Inputs Card
                            VStack(spacing: 16) {
                                // Bed Time
                                HStack {
                                    HStack(spacing: 6) {
                                        Image(systemName: "moon.fill")
                                            .foregroundColor(Color("PixelBlue"))
                                        Text("sleep_bed_time".localized)
                                            .font(.pixel(16))
                                            .foregroundColor(Color("PixelBorder"))
                                    }
                                    Spacer()
                                    PixelDatePicker(title: "", selection: $bedTime, displayedComponents: .hourAndMinute)
                                        .frame(width: 100)
                                }
                                
                                Divider()
                                
                                // Wake Time
                                HStack {
                                    HStack(spacing: 6) {
                                        Image(systemName: "sun.max.fill")
                                            .foregroundColor(Color("PixelAccent"))
                                        Text("sleep_wake_time".localized)
                                            .font(.pixel(16))
                                            .foregroundColor(Color("PixelBorder"))
                                    }
                                    Spacer()
                                    PixelDatePicker(title: "", selection: $wakeTime, displayedComponents: .hourAndMinute)
                                        .frame(width: 100)
                                }
                                
                                Divider()
                                
                                // Duration Display
                                HStack {
                                    HStack(spacing: 6) {
                                        Image(systemName: "timer")
                                            .foregroundColor(Color("PixelGreen"))
                                        Text("sleep_duration".localized)
                                            .font(.pixel(16))
                                            .foregroundColor(Color("PixelBorder"))
                                    }
                                    Spacer()
                                    Text(calculatedDuration)
                                        .font(.pixel(18))
                                        .foregroundColor(Color("PixelBlue"))
                                }
                            }
                            .padding()
                            .frame(width: contentWidth)
                            .background(Color.white)
                            .pixelBorderSmall()
                            
                            // Quality Rating
                            VStack(spacing: 12) {
                                Text("sleep_quality".localized)
                                    .font(.pixel(16))
                                    .foregroundColor(Color("PixelBorder"))
                                
                                // Star Rating
                                HStack(spacing: 12) {
                                    ForEach(1...5, id: \.self) { index in
                                        Button(action: { quality = index }) {
                                            Image(systemName: index <= quality ? "star.fill" : "star")
                                                .font(.system(size: 28))
                                                .foregroundColor(index <= quality ? Color("PixelAccent") : Color.gray.opacity(0.4))
                                                .scaleEffect(index <= quality ? 1.1 : 1.0)
                                        }
                                        .animation(.spring(response: 0.3), value: quality)
                                    }
                                }
                                
                                Text(qualityText)
                                    .font(.pixel(14))
                                    .foregroundColor(Color("PixelAccent"))
                            }
                            .padding()
                            .frame(width: contentWidth)
                            .background(Color.white)
                            .pixelBorderSmall()
                            
                            // Save Button
                            Button(action: saveSleep) {
                                HStack {
                                    if isSaving {
                                        ProgressView()
                                            .scaleEffect(0.8)
                                    }
                                    Text("sleep_record_today".localized)
                                        .font(.pixel(18))
                                }
                                .foregroundColor(Color("PixelBorder"))
                                .frame(width: contentWidth)
                                .padding(.vertical, 14)
                                .background(Color("PixelAccent"))
                                .pixelBorderSmall()
                            }
                            .disabled(isSaving || sleepStore.todayEntry != nil)
                            .opacity(sleepStore.todayEntry != nil ? 0.5 : 1)
                            
                            if sleepStore.todayEntry != nil {
                                HStack(spacing: 4) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(Color("PixelGreen"))
                                    Text("sleep_already_logged".localized)
                                        .font(.pixel(14))
                                        .foregroundColor(Color("PixelGreen"))
                                }
                            }
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
                            
                            // Week Chart
                            WeekSleepChart(entries: sleepStore.weekEntries)
                                .frame(width: contentWidth, height: 160)
                                .background(Color.white)
                                .pixelBorderSmall()
                            
                            // Stats
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
                }
            }
        }
        .navigationTitle(location.name)
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
        .onAppear {
            // Data is loaded automatically on configure
        }
    }
    
    // 计算睡眠时长
    var calculatedDuration: String {
        var duration = wakeTime.timeIntervalSince(bedTime)
        if duration < 0 {
            duration += 24 * 3600
        }
        let hours = Int(duration / 3600)
        let minutes = Int((duration.truncatingRemainder(dividingBy: 3600)) / 60)
        return "\(hours)h \(minutes)m"
    }
    
    // 质量文字
    var qualityText: String {
        switch quality {
        case 1: return "很差 - 辗转难眠"
        case 2: return "较差 - 多次醒来"
        case 3: return "一般 - 还行"
        case 4: return "良好 - 睡得不错"
        case 5: return "极佳 - 一觉到天亮"
        default: return ""
        }
    }
    
    func saveSleep() {
        isSaving = true
        Task { @MainActor in
            // 如果有同步的数据，使用同步的数据
            if let sleepData = syncedSleepData {
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
            } else {
                await sleepStore.addEntry(bedTime: bedTime, wakeTime: wakeTime, quality: quality)
            }
            isSaving = false
        }
    }

    func syncFromHealthKit() {
        isSyncing = true
        Task { @MainActor in
            // 先请求授权
            let authorized = await healthKitManager.requestAuthorization()
            guard authorized else {
                showSyncError = true
                isSyncing = false
                return
            }
            
            // 获取昨晚睡眠数据
            if let sleepData = await healthKitManager.fetchLastNightSleep() {
                syncedSleepData = sleepData
                // 更新表单时间
                bedTime = sleepData.bedTime
                wakeTime = sleepData.wakeTime
            } else {
                showSyncError = true
            }
            
            isSyncing = false
        }
    }
}

// MARK: - Week Sleep Chart

struct WeekSleepChart: View {
    let entries: [SleepEntryData]
    
    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            ForEach(weekDays, id: \.date) { day in
                VStack(spacing: 4) {
                    // Bar
                    RoundedRectangle(cornerRadius: 2)
                        .fill(barColor(for: day.entry))
                        .frame(width: 30, height: barHeight(for: day.entry))
                    
                    // Day Label
                    Text(day.label)
                        .font(.pixel(12))
                        .foregroundColor(day.isToday ? Color("PixelBlue") : Color("PixelBorder"))
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding()
    }
    
    struct DayData: Hashable {
        let date: Date
        let label: String
        let entry: SleepEntryData?
        let isToday: Bool
    }
    
    var weekDays: [DayData] {
        let calendar = Calendar.current
        let today = Date()
        let weekday = calendar.component(.weekday, from: today)
        // 计算本周一
        let mondayOffset = weekday == 1 ? -6 : -(weekday - 2)
        guard let monday = calendar.date(byAdding: .day, value: mondayOffset, to: today) else {
            return []
        }
        
        let labels = ["一", "二", "三", "四", "五", "六", "日"]
        
        return (0..<7).map { offset in
            let date = calendar.date(byAdding: .day, value: offset, to: monday)!
            let entry = entries.first { calendar.isDate($0.date, inSameDayAs: date) }
            let isToday = calendar.isDateInToday(date)
            return DayData(date: date, label: labels[offset], entry: entry, isToday: isToday)
        }
    }
    
    func barHeight(for entry: SleepEntryData?) -> CGFloat {
        guard let entry = entry else { return 10 }
        // 8小时 = 100pt, 最大 120pt
        return min(CGFloat(entry.durationHours) * 12.5, 100)
    }
    
    func barColor(for entry: SleepEntryData?) -> Color {
        guard let entry = entry else { return Color.gray.opacity(0.3) }
        switch entry.quality {
        case 1: return Color.red.opacity(0.7)
        case 2: return Color.orange.opacity(0.7)
        case 3: return Color.yellow.opacity(0.7)
        case 4: return Color("PixelBlue").opacity(0.7)
        case 5: return Color("PixelGreen").opacity(0.7)
        default: return Color.gray.opacity(0.5)
        }
    }
}

// MARK: - Stat Box (Legacy with emoji)

struct StatBox: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        VStack(spacing: 6) {
            Text(icon)
                .font(.system(size: 24))
            Text(value)
                .font(.pixel(20))
                .foregroundColor(Color("PixelBlue"))
            Text(title)
                .font(.pixel(12))
                .foregroundColor(Color("PixelBorder").opacity(0.7))
        }
        .padding()
        .background(Color.white)
        .pixelBorderSmall()
    }
}

// MARK: - Sleep Stat Box (SF Symbols)

struct SleepStatBox: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(Color("PixelBlue"))
            Text(value)
                .font(.pixel(20))
                .foregroundColor(Color("PixelBlue"))
            Text(title)
                .font(.pixel(12))
                .foregroundColor(Color("PixelBorder").opacity(0.7))
        }
        .padding()
        .background(Color.white)
        .pixelBorderSmall()
    }
}

// MARK: - Sleep Score Card

struct SleepScoreCard: View {
    let sleepData: SleepData
    
    var body: some View {
        VStack(spacing: 16) {
            // Score Circle
            HStack {
                VStack(spacing: 4) {
                    ZStack {
                        Circle()
                            .stroke(Color.gray.opacity(0.2), lineWidth: 8)
                            .frame(width: 80, height: 80)
                        
                        Circle()
                            .trim(from: 0, to: CGFloat(sleepData.sleepScore) / 100)
                            .stroke(scoreColor, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                            .frame(width: 80, height: 80)
                            .rotationEffect(.degrees(-90))
                        
                        VStack(spacing: 2) {
                            Text("\(sleepData.sleepScore)")
                                .font(.pixel(28))
                                .foregroundColor(Color("PixelBorder"))
                            Text("分")
                                .font(.pixel(12))
                                .foregroundColor(Color("PixelBorder").opacity(0.7))
                        }
                    }
                    
                    Text(sleepData.scoreLevel)
                        .font(.pixel(14))
                        .foregroundColor(scoreColor)
                }
                
                Spacer()
                
                // Sleep Times
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 8) {
                        Image(systemName: "moon.fill")
                            .foregroundColor(Color("PixelBlue"))
                        Text("入睡")
                            .font(.pixel(12))
                            .foregroundColor(Color("PixelBorder").opacity(0.7))
                        Text(formatTime(sleepData.bedTime))
                            .font(.pixel(16))
                            .foregroundColor(Color("PixelBorder"))
                    }
                    
                    HStack(spacing: 8) {
                        Image(systemName: "sun.max.fill")
                            .foregroundColor(Color("PixelAccent"))
                        Text("起床")
                            .font(.pixel(12))
                            .foregroundColor(Color("PixelBorder").opacity(0.7))
                        Text(formatTime(sleepData.wakeTime))
                            .font(.pixel(16))
                            .foregroundColor(Color("PixelBorder"))
                    }
                    
                    HStack(spacing: 8) {
                        Image(systemName: "timer")
                            .foregroundColor(Color("PixelGreen"))
                        Text("时长")
                            .font(.pixel(12))
                            .foregroundColor(Color("PixelBorder").opacity(0.7))
                        Text(sleepData.formatDuration(sleepData.totalSleep))
                            .font(.pixel(16))
                            .foregroundColor(Color("PixelBlue"))
                    }
                }
            }
            
            Divider()
            
            // Sleep Stages
            SleepStagesView(sleepData: sleepData)
        }
        .padding()
        .background(Color.white)
        .pixelBorderSmall()
    }
    
    var scoreColor: Color {
        switch sleepData.sleepScore {
        case 85...100: return Color("PixelGreen")
        case 70..<85: return Color("PixelBlue")
        case 55..<70: return Color("PixelAccent")
        default: return Color.red
        }
    }
    
    func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
}

// MARK: - Sleep Stages View

struct SleepStagesView: View {
    let sleepData: SleepData
    
    var body: some View {
        VStack(spacing: 12) {
            Text("睡眠阶段")
                .font(.pixel(14))
                .foregroundColor(Color("PixelBorder"))
            
            // Stacked Bar Chart
            GeometryReader { geometry in
                let width = max(0, geometry.size.width)
                HStack(spacing: 0) {
                    // Deep Sleep
                    Rectangle()
                        .fill(Color.purple.opacity(0.7))
                        .frame(width: max(0, width * CGFloat(sleepData.deepPercent / 100)))
                    
                    // Core Sleep
                    Rectangle()
                        .fill(Color("PixelBlue").opacity(0.7))
                        .frame(width: max(0, width * CGFloat(sleepData.corePercent / 100)))
                    
                    // REM Sleep
                    Rectangle()
                        .fill(Color.cyan.opacity(0.7))
                        .frame(width: max(0, width * CGFloat(sleepData.remPercent / 100)))
                    
                    // Awake
                    if sleepData.awakePercent > 0 {
                        Rectangle()
                            .fill(Color.orange.opacity(0.7))
                            .frame(width: max(0, width * CGFloat(sleepData.awakePercent / 100)))
                    }
                }
                .cornerRadius(4)
            }
            .frame(height: 16)
            
            // Legend
            HStack(spacing: 16) {
                StageLegendItem(color: .purple.opacity(0.7), label: "深睡", value: sleepData.formatDuration(sleepData.deepSleep), percent: max(0, sleepData.deepPercent))
                StageLegendItem(color: Color("PixelBlue").opacity(0.7), label: "核心", value: sleepData.formatDuration(sleepData.coreSleep), percent: max(0, sleepData.corePercent))
                StageLegendItem(color: .cyan.opacity(0.7), label: "REM", value: sleepData.formatDuration(sleepData.remSleep), percent: max(0, sleepData.remPercent))
                if sleepData.awakeTime > 0 {
                    StageLegendItem(color: .orange.opacity(0.7), label: "清醒", value: sleepData.formatDuration(sleepData.awakeTime), percent: max(0, sleepData.awakePercent))
                }
            }
        }
    }
}

struct StageLegendItem: View {
    let color: Color
    let label: String
    let value: String
    let percent: Double
    
    var body: some View {
        VStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 10, height: 10)
            Text(label)
                .font(.pixel(10))
                .foregroundColor(Color("PixelBorder"))
            Text(value)
                .font(.pixel(12))
                .foregroundColor(Color("PixelBorder"))
            Text(String(format: "%.0f%%", percent))
                .font(.pixel(10))
                .foregroundColor(Color("PixelBorder").opacity(0.7))
        }
    }
}
