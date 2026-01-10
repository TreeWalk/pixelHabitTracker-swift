import Foundation
import SwiftData

@MainActor
class SwiftDataSleepStore: ObservableObject {
    private var modelContext: ModelContext?
    
    @Published var entries: [SleepEntryData] = []
    @Published var isLoading = false
    @Published var error: String?
    
    // MARK: - Configure
    
    func configure(modelContext: ModelContext) {
        self.modelContext = modelContext
        loadData()
    }
    
    // MARK: - Load Data
    
    private func loadData() {
        guard let context = modelContext else { return }
        
        do {
            let descriptor = FetchDescriptor<SleepEntryData>(sortBy: [SortDescriptor(\.date, order: .reverse)])
            entries = try context.fetch(descriptor)
        } catch {
            self.error = "加载睡眠记录失败: \(error.localizedDescription)"
        }
    }
    
    // MARK: - Computed Properties
    
    var todayEntry: SleepEntryData? {
        let calendar = Calendar.current
        return entries.first { calendar.isDateInToday($0.date) }
    }
    
    var weekEntries: [SleepEntryData] {
        let calendar = Calendar.current
        guard let weekAgo = calendar.date(byAdding: .day, value: -6, to: Date()) else { return [] }
        return entries.filter { $0.date >= weekAgo }
    }
    
    var averageDuration: Double {
        guard !weekEntries.isEmpty else { return 0 }
        return weekEntries.reduce(0) { $0 + $1.durationHours } / Double(weekEntries.count)
    }
    
    var averageQuality: Double {
        guard !weekEntries.isEmpty else { return 0 }
        return Double(weekEntries.reduce(0) { $0 + $1.quality }) / Double(weekEntries.count)
    }
    
    // MARK: - CRUD Operations
    
    func addEntry(bedTime: Date, wakeTime: Date, quality: Int) {
        guard let context = modelContext else { return }
        
        let entry = SleepEntryData(
            bedTime: bedTime,
            wakeTime: wakeTime,
            quality: quality
        )
        
        context.insert(entry)
        entries.insert(entry, at: 0)
        
        try? context.save()
    }
    
    func addEntryWithHealthKitData(
        bedTime: Date,
        wakeTime: Date,
        quality: Int,
        deepSleep: Double?,
        coreSleep: Double?,
        remSleep: Double?,
        awakeTime: Double?,
        sleepScore: Int?
    ) {
        guard let context = modelContext else { return }
        
        let entry = SleepEntryData(
            bedTime: bedTime,
            wakeTime: wakeTime,
            quality: quality,
            deepSleep: deepSleep,
            coreSleep: coreSleep,
            remSleep: remSleep,
            awakeTime: awakeTime,
            sleepScore: sleepScore,
            isFromHealthKit: true
        )
        
        context.insert(entry)
        entries.insert(entry, at: 0)
        
        try? context.save()
    }
    
    func deleteEntry(_ entry: SleepEntryData) {
        guard let context = modelContext else { return }
        
        context.delete(entry)
        entries.removeAll { $0.date == entry.date }
        
        try? context.save()
    }
}
