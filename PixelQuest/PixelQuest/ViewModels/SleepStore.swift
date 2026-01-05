import Foundation
import Supabase

@MainActor
class SleepStore: ObservableObject {
    @Published var entries: [SleepEntry] = []
    @Published var isLoading = false
    @Published var error: String?
    
    // MARK: - 本周数据
    var weekEntries: [SleepEntry] {
        let calendar = Calendar.current
        let now = Date()
        let weekAgo = calendar.date(byAdding: .day, value: -6, to: now)!
        return entries.filter { $0.date >= weekAgo }
            .sorted { $0.date < $1.date }
    }
    
    // 平均睡眠时长
    var averageDuration: Double {
        guard !weekEntries.isEmpty else { return 0 }
        return weekEntries.map { $0.durationHours }.reduce(0, +) / Double(weekEntries.count)
    }
    
    // 平均睡眠质量
    var averageQuality: Double {
        guard !weekEntries.isEmpty else { return 0 }
        return Double(weekEntries.map { $0.quality }.reduce(0, +)) / Double(weekEntries.count)
    }
    
    // 今日是否已记录
    var todayEntry: SleepEntry? {
        let calendar = Calendar.current
        return entries.first { calendar.isDateInToday($0.date) }
    }
    
    // MARK: - Supabase 操作
    
    func fetchEntries() async {
        isLoading = true
        error = nil
        
        do {
            let response: [SleepEntry] = try await supabase
                .from("sleep_entries")
                .select()
                .order("date", ascending: false)
                .limit(30)
                .execute()
                .value
            entries = response
        } catch {
            self.error = "获取睡眠记录失败: \(error.localizedDescription)"
            print("Fetch sleep entries error: \(error)")
        }
        
        isLoading = false
    }
    
    func addEntry(bedTime: Date, wakeTime: Date, quality: Int) async {
        let newEntry = SleepEntry(
            id: UUID(),
            bedTime: bedTime,
            wakeTime: wakeTime,
            quality: quality,
            date: Date(),
            userId: supabase.auth.currentUser?.id
        )
        
        // 先添加到本地
        entries.insert(newEntry, at: 0)
        
        // 同步到 Supabase
        let insertEntry = InsertSleepEntry(
            bedTime: bedTime,
            wakeTime: wakeTime,
            quality: quality,
            date: Date(),
            userId: supabase.auth.currentUser?.id
        )
        
        do {
            try await supabase.from("sleep_entries").insert(insertEntry).execute()
        } catch {
            self.error = "保存睡眠记录失败: \(error.localizedDescription)"
            print("Insert sleep entry error: \(error)")
        }
    }
    
    // 本地添加（离线模式）
    func addEntryLocally(bedTime: Date, wakeTime: Date, quality: Int) {
        let entry = SleepEntry(
            id: UUID(),
            bedTime: bedTime,
            wakeTime: wakeTime,
            quality: quality,
            date: Date(),
            userId: nil
        )
        entries.insert(entry, at: 0)
    }
    
    // 添加带 HealthKit 数据的睡眠记录
    func addEntryWithHealthKitData(
        bedTime: Date,
        wakeTime: Date,
        quality: Int,
        deepSleep: TimeInterval,
        coreSleep: TimeInterval,
        remSleep: TimeInterval,
        awakeTime: TimeInterval,
        sleepScore: Int
    ) async {
        let newEntry = SleepEntry(
            id: UUID(),
            bedTime: bedTime,
            wakeTime: wakeTime,
            quality: quality,
            date: Date(),
            userId: supabase.auth.currentUser?.id,
            deepSleep: deepSleep,
            coreSleep: coreSleep,
            remSleep: remSleep,
            awakeTime: awakeTime,
            sleepScore: sleepScore,
            isFromHealthKit: true
        )
        
        // 先添加到本地
        entries.insert(newEntry, at: 0)
        
        // 注：如果需要保存到 Supabase，需要更新数据库表结构添加新字段
        // 这里暂时只保存到本地
    }
}
