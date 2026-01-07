import Foundation
import Supabase

@MainActor
class QuestStore: ObservableObject {
    @Published var quests: [Quest] = []
    @Published var questLog: [QuestLog] = []
    @Published var isLoading = false
    @Published var error: String?
    
    // 本地默认数据（用于离线模式或初始化）
    private let defaultQuests: [Quest] = [
        Quest(id: 1, title: "Drink Water", xp: 50, completed: false, type: .health, recurrence: .daily, lastCompletedAt: nil, userId: nil),
        Quest(id: 2, title: "Read Book", xp: 100, completed: false, type: .intellect, recurrence: .daily, lastCompletedAt: nil, userId: nil),
        Quest(id: 3, title: "Exercise", xp: 150, completed: true, type: .strength, recurrence: .daily, lastCompletedAt: Date(), userId: nil),
        Quest(id: 4, title: "Meditate", xp: 50, completed: false, type: .spirit, recurrence: .daily, lastCompletedAt: nil, userId: nil),
        Quest(id: 5, title: "Code", xp: 200, completed: false, type: .skill, recurrence: .weekly, lastCompletedAt: nil, userId: nil),
        Quest(id: 6, title: "Walk Dog", xp: 75, completed: false, type: .strength, recurrence: .once, lastCompletedAt: nil, userId: nil),
    ]
    
    init() {
        // 初始化时使用本地数据
        quests = defaultQuests
    }
    
    var totalGold: Int {
        quests.filter { $0.completed }.reduce(0) { $0 + $1.xp }
    }
    
    var completionPercentage: Int {
        guard !quests.isEmpty else { return 0 }
        let completed = quests.filter { $0.completed }.count
        return Int((Double(completed) / Double(quests.count)) * 100)
    }
    
    // MARK: - 分区任务列表
    var activeQuests: [Quest] {
        quests.filter { !$0.completed }
    }
    
    var completedQuests: [Quest] {
        quests.filter { $0.completed }
    }
    
    // MARK: - 从 Supabase 获取任务
    func fetchQuests() async {
        isLoading = true
        error = nil
        
        do {
            let response: [Quest] = try await supabase
                .from("quests")
                .select()
                .order("id", ascending: true)
                .execute()
                .value
            
            quests = response.isEmpty ? defaultQuests : response
        } catch {
            self.error = "获取任务失败: \(error.localizedDescription)"
            print("Fetch quests error: \(error)")
        }
        
        isLoading = false
    }
    
    // MARK: - 切换任务完成状态
    func toggleQuest(id: Int) async {
        guard let index = quests.firstIndex(where: { $0.id == id }) else { return }
        let wasCompleted = quests[index].completed
        quests[index].completed.toggle()
        
        // 如果刚完成，记录到 questLog
        if !wasCompleted {
            let quest = quests[index]
            let log = QuestLog(
                id: Int(Date().timeIntervalSince1970),
                questTitle: quest.title,
                questType: quest.type,
                xp: quest.xp,
                completedAt: Date(),
                userId: supabase.auth.currentUser?.id
            )
            questLog.insert(log, at: 0)
            
            // 同步到 Supabase（使用不含 ID 的 InsertQuestLog）
            let insertLog = InsertQuestLog(
                questTitle: quest.title,
                questType: quest.type.rawValue,
                xp: quest.xp,
                completedAt: Date(),
                userId: supabase.auth.currentUser?.id
            )
            do {
                try await supabase.from("quest_logs").insert(insertLog).execute()
            } catch {
                print("Insert quest log error: \(error)")
            }
        }
        
        // 更新 Supabase 中的任务状态
        do {
            try await supabase
                .from("quests")
                .update(["completed": quests[index].completed])
                .eq("id", value: id)
                .execute()
        } catch {
            print("Update quest error: \(error)")
        }
    }
    
    // MARK: - 添加新任务
    func addQuest(title: String, xp: Int, type: Quest.QuestType, recurrence: Quest.QuestRecurrence = .daily) async {
        let newQuest = Quest(
            id: Int(Date().timeIntervalSince1970),
            title: title,
            xp: xp,
            completed: false,
            type: type,
            recurrence: recurrence,
            lastCompletedAt: nil,
            userId: supabase.auth.currentUser?.id
        )
        
        quests.append(newQuest)
        
        // 使用不含 ID 的 InsertQuest
        let insertQuest = InsertQuest(
            title: title,
            xp: xp,
            completed: false,
            type: type.rawValue,
            recurrence: recurrence.rawValue,
            userId: supabase.auth.currentUser?.id
        )
        
        do {
            try await supabase.from("quests").insert(insertQuest).execute()
        } catch {
            print("Insert quest error: \(error)")
        }
    }
    
    // MARK: - 重置所有任务
    func resetQuests() async {
        for i in quests.indices {
            quests[i].completed = false
        }
        
        do {
            try await supabase
                .from("quests")
                .update(["completed": false])
                .execute()
        } catch {
            print("Reset quests error: \(error)")
        }
    }
    
    // MARK: - 本地同步方法（离线模式）
    func toggleQuestLocally(id: Int) {
        guard let index = quests.firstIndex(where: { $0.id == id }) else { return }
        let wasCompleted = quests[index].completed
        quests[index].completed.toggle()
        
        if !wasCompleted {
            let quest = quests[index]
            let log = QuestLog(
                id: Int(Date().timeIntervalSince1970),
                questTitle: quest.title,
                questType: quest.type,
                xp: quest.xp,
                completedAt: Date(),
                userId: nil
            )
            questLog.insert(log, at: 0)
        }
    }
    
    func addQuestLocally(title: String, xp: Int, type: Quest.QuestType, recurrence: Quest.QuestRecurrence = .daily) {
        let newQuest = Quest(
            id: Int(Date().timeIntervalSince1970),
            title: title,
            xp: xp,
            completed: false,
            type: type,
            recurrence: recurrence,
            lastCompletedAt: nil,
            userId: nil
        )
        quests.append(newQuest)
    }
    
    func resetQuestsLocally() {
        for i in quests.indices {
            quests[i].completed = false
        }
    }
}
