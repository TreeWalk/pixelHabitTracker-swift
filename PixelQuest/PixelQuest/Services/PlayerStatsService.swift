import Foundation
import Combine

// MARK: - Player Stats Service

@MainActor
class PlayerStatsService: ObservableObject {
    
    // MARK: - Dependencies
    private var questStore: SwiftDataQuestStore?
    private var bookStore: SwiftDataBookStore?
    private var exerciseStore: SwiftDataExerciseStore?
    private var financeStore: SwiftDataFinanceStore?
    
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Published Stats
    @Published var level: Int = 1
    @Published var currentXP: Int = 0
    @Published var xpToNextLevel: Int = 100
    
    @Published var strength: Int = 0     // 力量 - 来自运动 (火)
    @Published var intelligence: Int = 0 // 智力 - 来自阅读 (木)
    @Published var vitality: Int = 0     // 活力 - 来自习惯完成率 (水)
    @Published var wealth: Int = 0       // 财富 - 来自资产净值 (金)
    
    // 土 (Earth) - 总完成任务数
    var totalQuests: Int {
        questStore?.totalCompletedQuests ?? 0
    }
    
    // MARK: - Configuration
    
    func configure(
        questStore: SwiftDataQuestStore,
        bookStore: SwiftDataBookStore,
        exerciseStore: SwiftDataExerciseStore,
        financeStore: SwiftDataFinanceStore
    ) {
        self.questStore = questStore
        self.bookStore = bookStore
        self.exerciseStore = exerciseStore
        self.financeStore = financeStore
        
        setupSubscriptions()
        recalculateStats()
    }
    
    // MARK: - Subscriptions
    
    private func setupSubscriptions() {
        // 监听 QuestStore 变化 (with debounce to prevent rapid recalculations)
        questStore?.$quests
            .debounce(for: .milliseconds(100), scheduler: RunLoop.main)
            .sink { [weak self] _ in self?.recalculateStats() }
            .store(in: &cancellables)
        
        // 监听 BookStore 变化
        bookStore?.$books
            .debounce(for: .milliseconds(100), scheduler: RunLoop.main)
            .sink { [weak self] _ in self?.recalculateStats() }
            .store(in: &cancellables)
        
        // 监听 ExerciseStore 变化
        exerciseStore?.$entries
            .debounce(for: .milliseconds(100), scheduler: RunLoop.main)
            .sink { [weak self] _ in self?.recalculateStats() }
            .store(in: &cancellables)
        
        // 监听 FinanceStore 变化
        financeStore?.$assets
            .debounce(for: .milliseconds(100), scheduler: RunLoop.main)
            .sink { [weak self] _ in self?.recalculateStats() }
            .store(in: &cancellables)
    }
    
    // MARK: - Stats Calculation

    private func recalculateStats() {
        // 将计算移到后台线程，避免阻塞 UI
        Task.detached { [weak self] in
            guard let self = self else { return }

            // 在后台线程获取数据快照
            let questsSnapshot = await MainActor.run { self.questStore?.quests ?? [] }
            let booksSnapshot = await MainActor.run { self.bookStore?.books ?? [] }
            let exerciseWeekDuration = await MainActor.run { self.exerciseStore?.weekTotalDuration ?? 0 }
            let netWorth = await MainActor.run { self.financeStore?.netWorth ?? 0 }
            let completionPercentage = await MainActor.run { self.questStore?.completionPercentage ?? 0 }

            // 在后台线程执行计算
            let levelData = self.computeXPAndLevel(from: questsSnapshot)
            let strengthValue = exerciseWeekDuration / 10
            let intelligenceValue = self.computeIntelligence(from: booksSnapshot)
            let vitalityValue = completionPercentage
            let wealthValue = netWorth / 100000

            // 在主线程更新 UI
            await MainActor.run {
                self.level = levelData.level
                self.currentXP = levelData.currentXP
                self.xpToNextLevel = levelData.xpToNextLevel
                self.strength = strengthValue
                self.intelligence = intelligenceValue
                self.vitality = vitalityValue
                self.wealth = wealthValue
            }
        }
    }

    // 纯计算函数 - 可在后台线程安全执行
    private nonisolated func computeXPAndLevel(from quests: [QuestData]) -> (level: Int, currentXP: Int, xpToNextLevel: Int) {
        let totalXP = quests
            .filter { $0.completed }
            .reduce(0) { $0 + $1.xp }

        let baseXP = 100
        let growthRate = 1.2

        var xpNeeded = baseXP
        var accumulatedXP = 0
        var calculatedLevel = 1

        while accumulatedXP + xpNeeded <= totalXP {
            accumulatedXP += xpNeeded
            calculatedLevel += 1

            let nextXP = Double(baseXP) * pow(growthRate, Double(calculatedLevel - 1))

            if nextXP > Double(Int.max) || calculatedLevel >= 100 {
                xpNeeded = Int.max
                break
            }

            xpNeeded = Int(nextXP)

            if xpNeeded <= 0 {
                xpNeeded = Int.max
                break
            }
        }

        return (calculatedLevel, totalXP - accumulatedXP, xpNeeded)
    }

    private nonisolated func computeIntelligence(from books: [BookEntryData]) -> Int {
        let finishedCount = books.filter { $0.status == "finished" }.count
        let readingCount = books.filter { $0.status == "reading" }.count
        return finishedCount * 5 + readingCount * 2
    }
    
    // MARK: - Formatted Stats (for display)
    
    var xpProgress: Double {
        guard xpToNextLevel > 0 else { return 0 }
        let progress = Double(currentXP) / Double(xpToNextLevel)
        // Ensure progress is valid number between 0 and 1
        if progress.isNaN || progress.isInfinite { return 0 }
        return max(0.0, min(1.0, progress))
    }
    
    var formattedLevel: String {
        "Lv. \(level)"
    }
    
    var formattedXP: String {
        "\(currentXP) / \(xpToNextLevel) XP"
    }
    
    var currentTitle: String {
        switch level {
        case 1...5: return "Novice"
        case 6...10: return "Apprentice"
        case 11...20: return "Adventurer"
        case 21...35: return "Skilled"
        case 36...50: return "Expert"
        default: return "Master"
        }
    }
}
