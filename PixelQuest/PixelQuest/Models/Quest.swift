import Foundation

struct Quest: Identifiable, Codable {
    let id: Int
    var title: String
    var xp: Int
    var completed: Bool
    var type: QuestType
    var recurrence: QuestRecurrence
    var lastCompletedAt: Date?
    var userId: UUID?
    
    enum CodingKeys: String, CodingKey {
        case id, title, xp, completed, type, recurrence
        case lastCompletedAt = "last_completed_at"
        case userId = "user_id"
    }
    
    // MARK: - 任务类型
    enum QuestType: String, CaseIterable, Codable {
        case health = "Health"
        case intellect = "Intellect"
        case strength = "Strength"
        case spirit = "Spirit"
        case skill = "Skill"
        
        var color: String {
            switch self {
            case .health: return "PixelRed"
            case .intellect: return "PixelBlue"
            case .strength: return "PixelGreen"
            case .spirit: return "PixelAccent"
            case .skill: return "PixelWood"
            }
        }
    }
    
    // MARK: - 任务周期
    enum QuestRecurrence: String, CaseIterable, Codable {
        case once = "once"       // 单次任务
        case daily = "daily"     // 每日任务
        case weekly = "weekly"   // 每周任务
        case monthly = "monthly" // 每月任务
        
        var displayName: String {
            switch self {
            case .once: return "quest_recurrence_once".localized
            case .daily: return "quest_recurrence_daily".localized
            case .weekly: return "quest_recurrence_weekly".localized
            case .monthly: return "quest_recurrence_monthly".localized
            }
        }
        
        var icon: String {
            switch self {
            case .once: return "1.circle.fill"
            case .daily: return "sun.max.fill"
            case .weekly: return "calendar.badge.clock"
            case .monthly: return "calendar"
            }
        }
    }
    
    // 检查周期任务是否需要重置
    var shouldReset: Bool {
        guard recurrence != .once, completed, let lastCompleted = lastCompletedAt else {
            return false
        }
        
        let calendar = Calendar.current
        let now = Date()
        
        switch recurrence {
        case .once:
            return false
        case .daily:
            return !calendar.isDate(lastCompleted, inSameDayAs: now)
        case .weekly:
            return !calendar.isDate(lastCompleted, equalTo: now, toGranularity: .weekOfYear)
        case .monthly:
            return !calendar.isDate(lastCompleted, equalTo: now, toGranularity: .month)
        }
    }
}

// 用于插入数据库的结构（不包含 ID，让数据库自动生成）
struct InsertQuest: Codable {
    var title: String
    var xp: Int
    var completed: Bool
    var type: String
    var recurrence: String
    var userId: UUID?
    
    enum CodingKeys: String, CodingKey {
        case title, xp, completed, type, recurrence
        case userId = "user_id"
    }
}

struct QuestLog: Identifiable, Codable {
    let id: Int
    let questTitle: String
    let questType: Quest.QuestType
    let xp: Int
    let completedAt: Date
    var userId: UUID?
    
    enum CodingKeys: String, CodingKey {
        case id, xp
        case questTitle = "quest_title"
        case questType = "quest_type"
        case completedAt = "completed_at"
        case userId = "user_id"
    }
}

// 用于插入数据库的结构
struct InsertQuestLog: Codable {
    let questTitle: String
    let questType: String
    let xp: Int
    let completedAt: Date
    var userId: UUID?
    
    enum CodingKeys: String, CodingKey {
        case xp
        case questTitle = "quest_title"
        case questType = "quest_type"
        case completedAt = "completed_at"
        case userId = "user_id"
    }
}
