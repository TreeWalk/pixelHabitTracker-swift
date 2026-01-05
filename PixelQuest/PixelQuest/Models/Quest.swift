import Foundation

struct Quest: Identifiable, Codable {
    let id: Int
    var title: String
    var xp: Int
    var completed: Bool
    var type: QuestType
    var userId: UUID?
    
    enum CodingKeys: String, CodingKey {
        case id, title, xp, completed, type
        case userId = "user_id"
    }
    
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
}

// 用于插入数据库的结构（不包含 ID，让数据库自动生成）
struct InsertQuest: Codable {
    var title: String
    var xp: Int
    var completed: Bool
    var type: String
    var userId: UUID?
    
    enum CodingKeys: String, CodingKey {
        case title, xp, completed, type
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
