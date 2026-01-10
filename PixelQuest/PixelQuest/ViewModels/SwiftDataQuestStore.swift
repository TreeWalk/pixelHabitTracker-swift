import Foundation
import SwiftData

@MainActor
class SwiftDataQuestStore: ObservableObject {
    private var modelContext: ModelContext?
    
    @Published var quests: [QuestData] = []
    @Published var questLog: [QuestLogData] = []
    @Published var isLoading = false
    @Published var error: String?
    
    // MARK: - Cached Statistics (Performance Optimization)
    private(set) var cachedStreak: Int = 0
    private(set) var cachedHeatmapData: [Date: Int] = [:]
    private(set) var cachedTypeDistribution: [String: Int] = [:]
    
    // MARK: - Configure
    
    func configure(modelContext: ModelContext) {
        self.modelContext = modelContext
        loadData()
    }
    
    // MARK: - Load Data
    
    private func loadData() {
        guard let context = modelContext else { return }
        
        do {
            let questDescriptor = FetchDescriptor<QuestData>(sortBy: [SortDescriptor(\.createdAt, order: .reverse)])
            quests = try context.fetch(questDescriptor)
            
            let logDescriptor = FetchDescriptor<QuestLogData>(sortBy: [SortDescriptor(\.completedAt, order: .reverse)])
            questLog = try context.fetch(logDescriptor)
            
            // Rebuild cache after data is loaded (async to not block main thread)
            Task { @MainActor in
                rebuildCache()
            }
        } catch {
            self.error = "加载任务失败: \(error.localizedDescription)"
        }
    }
    
    // MARK: - Computed Properties
    
    var activeQuests: [QuestData] {
        quests.filter { !$0.completed }
    }
    
    var completedQuests: [QuestData] {
        quests.filter { $0.completed }
    }
    
    var totalGold: Int {
        quests.filter { $0.completed }.reduce(0) { $0 + $1.xp }
    }
    
    var currentLevel: Int {
        let totalXP = questLog.reduce(0) { $0 + $1.xp }
        return max(1, totalXP / 100 + 1)
    }
    
    var currentTitle: String {
        switch currentLevel {
        case 1...5: return "Novice"
        case 6...10: return "Apprentice"
        case 11...20: return "Adventurer"
        case 21...35: return "Skilled"
        case 36...50: return "Expert"
        default: return "Master"
        }
    }
    
    var completionPercentage: Int {
        guard !quests.isEmpty else { return 0 }
        let completed = quests.filter { $0.completed }.count
        return Int((Double(completed) / Double(quests.count)) * 100)
    }
    
    // Use cached values for performance
    var currentStreak: Int { cachedStreak }
    var heatmapData: [Date: Int] { cachedHeatmapData }
    var typeDistribution: [String: Int] { cachedTypeDistribution }
    
    var totalCompletedQuests: Int {
        questLog.count
    }
    
    var totalXP: Int {
        questLog.reduce(0) { $0 + $1.xp }
    }
    
    // MARK: - CRUD Operations
    
    func toggleQuest(_ quest: QuestData) {
        let wasCompleted = quest.completed
        quest.completed.toggle()
        
        if !wasCompleted, let context = modelContext {
            let log = QuestLogData(
                questTitle: quest.title,
                questType: quest.type,
                xp: quest.xp
            )
            context.insert(log)
            questLog.insert(log, at: 0)
        }
        
        try? modelContext?.save()
    }
    
    func addQuest(title: String, xp: Int, type: String, recurrence: String = "daily") {
        guard let context = modelContext else { return }
        
        let quest = QuestData(title: title, xp: xp, type: type, recurrence: recurrence)
        context.insert(quest)
        quests.insert(quest, at: 0)
        
        try? context.save()
    }
    
    func deleteQuest(_ quest: QuestData) {
        guard let context = modelContext else { return }
        
        context.delete(quest)
        quests.removeAll { $0.title == quest.title }
        
        try? context.save()
    }
    
    func resetQuests() {
        for quest in quests {
            quest.completed = false
        }
        try? modelContext?.save()
    }
    
    // MARK: - Cache Rebuild
    
    private func rebuildCache() {
        cachedStreak = calculateStreak()
        cachedHeatmapData = calculateHeatmapData()
        cachedTypeDistribution = calculateTypeDistribution()
    }
    
    private func calculateStreak() -> Int {
        let calendar = Calendar.current
        var streak = 0
        var checkDate = Date()
        
        let todayCompleted = questLog.contains { calendar.isDate($0.completedAt, inSameDayAs: checkDate) }
        if !todayCompleted {
            checkDate = calendar.date(byAdding: .day, value: -1, to: checkDate)!
        }
        
        // Safety limit: max 365 days to prevent infinite loop
        for _ in 0..<365 {
            let targetDate = checkDate
            let hasCompleted = questLog.contains { calendar.isDate($0.completedAt, inSameDayAs: targetDate) }
            if hasCompleted {
                streak += 1
                guard let newDate = calendar.date(byAdding: .day, value: -1, to: checkDate) else { break }
                checkDate = newDate
            } else {
                break
            }
        }
        return streak
    }
    
    private func calculateHeatmapData() -> [Date: Int] {
        var data: [Date: Int] = [:]
        let calendar = Calendar.current
        
        for log in questLog {
            let startOfDay = calendar.startOfDay(for: log.completedAt)
            data[startOfDay, default: 0] += 1
        }
        return data
    }
    
    private func calculateTypeDistribution() -> [String: Int] {
        var distribution: [String: Int] = [:]
        for log in questLog {
            distribution[log.questType, default: 0] += 1
        }
        return distribution
    }
}
