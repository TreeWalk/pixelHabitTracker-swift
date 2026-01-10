import Foundation
import SwiftData

@Model
final class ExerciseEntryData {
    var type: String  // running, strength, cycling, etc.
    var duration: Int  // minutes
    var calories: Int
    var date: Date
    
    init(type: String, duration: Int, calories: Int, date: Date = Date()) {
        self.type = type
        self.duration = duration
        self.calories = calories
        self.date = date
    }
    
    var typeEnum: ExerciseType {
        ExerciseType(rawValue: type) ?? .other
    }
    
    var formattedDuration: String {
        if duration >= 60 {
            let hours = duration / 60
            let mins = duration % 60
            return mins > 0 ? "\(hours)h \(mins)min" : "\(hours)h"
        }
        return "\(duration)min"
    }
    
    var icon: String {
        typeEnum.icon
    }
}

enum ExerciseType: String, CaseIterable {
    case running = "跑步"
    case strength = "力量训练"
    case cycling = "骑行"
    case swimming = "游泳"
    case yoga = "瑜伽"
    case hiking = "徒步"
    case other = "其他"
    
    var icon: String {
        switch self {
        case .running: return "figure.run"
        case .strength: return "dumbbell.fill"
        case .cycling: return "bicycle"
        case .swimming: return "figure.pool.swim"
        case .yoga: return "figure.mind.and.body"
        case .hiking: return "figure.hiking"
        case .other: return "sportscourt.fill"
        }
    }
}
