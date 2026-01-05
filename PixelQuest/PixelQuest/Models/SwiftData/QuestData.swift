import Foundation
import SwiftData

@Model
final class QuestData {
    var title: String
    var xp: Int
    var completed: Bool
    var type: String // health, intellect, strength, spirit, skill
    var createdAt: Date
    
    init(title: String, xp: Int, completed: Bool = false, type: String, createdAt: Date = Date()) {
        self.title = title
        self.xp = xp
        self.completed = completed
        self.type = type
        self.createdAt = createdAt
    }
}

@Model
final class QuestLogData {
    var questTitle: String
    var questType: String
    var xp: Int
    var completedAt: Date
    
    init(questTitle: String, questType: String, xp: Int, completedAt: Date = Date()) {
        self.questTitle = questTitle
        self.questType = questType
        self.xp = xp
        self.completedAt = completedAt
    }
}
