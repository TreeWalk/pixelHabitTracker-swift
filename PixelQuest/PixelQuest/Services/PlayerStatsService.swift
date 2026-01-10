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
        calculateXPAndLevel()
        calculateStrength()
        calculateIntelligence()
        calculateVitality()
        calculateWealth()
    }
    
    // XP 来自完成的任务
    private func calculateXPAndLevel() {
        guard let questStore = questStore else { return }
        
        // 总XP = 所有已完成任务的XP总和
        let totalXP = questStore.quests
            .filter { $0.completed }
            .reduce(0) { $0 + $1.xp }
        
        // 等级计算: 每100XP升一级
        let baseXP = 100
        let growthRate = 1.2
        
        var xpNeeded = baseXP
        var accumulatedXP = 0
        var calculatedLevel = 1
        
        while accumulatedXP + xpNeeded <= totalXP {
            accumulatedXP += xpNeeded
            calculatedLevel += 1
            
            // Calculate next level requirement safely
            let nextXP = Double(baseXP) * pow(growthRate, Double(calculatedLevel - 1))
            
            // Safety check: Prevent Integer overflow or infinite loop
            if nextXP > Double(Int.max) || calculatedLevel >= 100 {
                xpNeeded = Int.max // Cap at max
                break
            }
            
            xpNeeded = Int(nextXP)
            
            // Safety check: Ensure xpNeeded is positive to prevent infinite loop
            if xpNeeded <= 0 { 
                xpNeeded = Int.max 
                break 
            }
        }
        
        self.level = calculatedLevel
        self.currentXP = totalXP - accumulatedXP
        self.xpToNextLevel = xpNeeded
    }
    
    // STR 力量 - 来自本周运动次数和时长
    private func calculateStrength() {
        guard let exerciseStore = exerciseStore else { return }
        
        // 本周运动总时长 (分钟) / 10 = STR点数
        let weekDuration = exerciseStore.weekTotalDuration
        self.strength = weekDuration / 10
    }
    
    // INT 智力 - 来自已读书籍数量
    private func calculateIntelligence() {
        guard let bookStore = bookStore else { return }
        
        // 每本已读完的书 = 5 INT
        // 每本正在读的书 = 2 INT
        let finishedBooks = bookStore.finishedBooks.count
        let readingBooks = bookStore.readingBooks.count
        
        self.intelligence = finishedBooks * 5 + readingBooks * 2
    }
    
    // VIT 活力 - 来自任务完成率
    private func calculateVitality() {
        guard let questStore = questStore else { return }
        
        // 任务完成率 * 100 = VIT
        self.vitality = questStore.completionPercentage
    }
    
    // GOLD 财富 - 来自资产净值
    private func calculateWealth() {
        guard let financeStore = financeStore else { return }
        
        // 净资产 / 1000 = GOLD (以分为单位，所以 / 100000)
        let netWorth = financeStore.netWorth
        self.wealth = netWorth / 100000  // 1000元 = 1 GOLD
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
}
