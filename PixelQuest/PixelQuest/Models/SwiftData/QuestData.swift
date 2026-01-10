import Foundation
import SwiftData

@Model
final class QuestData {
    var title: String
    var xp: Int
    var completed: Bool
    var type: String // health, intellect, strength, spirit, skill
    var recurrence: String? // once, daily, weekly, monthly - optional for migration
    var createdAt: Date
    var lastCompletedAt: Date?
    
    // Safe accessor with default value
    var recurrenceValue: String {
        recurrence ?? "daily"
    }
    
    init(title: String, xp: Int, completed: Bool = false, type: String, recurrence: String = "daily", createdAt: Date = Date(), lastCompletedAt: Date? = nil) {
        self.title = title
        self.xp = xp
        self.completed = completed
        self.type = type
        self.recurrence = recurrence
        self.createdAt = createdAt
        self.lastCompletedAt = lastCompletedAt
    }
    
    // Check if periodic quest should reset
    var shouldReset: Bool {
        guard recurrenceValue != "once", completed, let lastCompleted = lastCompletedAt else {
            return false
        }
        
        let calendar = Calendar.current
        let now = Date()
        
        switch recurrenceValue {
        case "daily":
            return !calendar.isDate(lastCompleted, inSameDayAs: now)
        case "weekly":
            return !calendar.isDate(lastCompleted, equalTo: now, toGranularity: .weekOfYear)
        case "monthly":
            return !calendar.isDate(lastCompleted, equalTo: now, toGranularity: .month)
        default:
            return false
        }
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
