import Foundation

struct ExerciseEntry: Identifiable, Codable, Hashable {
    let id: UUID
    var type: ExerciseType
    var duration: Int        // 时长(分钟)
    var calories: Int        // 消耗卡路里
    var date: Date
    var userId: UUID?
    
    enum CodingKeys: String, CodingKey {
        case id, type, duration, calories, date
        case userId = "user_id"
    }
    
    enum ExerciseType: String, CaseIterable, Codable {
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
    
    var formattedDuration: String {
        if duration >= 60 {
            let hours = duration / 60
            let mins = duration % 60
            return mins > 0 ? "\(hours)h \(mins)min" : "\(hours)h"
        }
        return "\(duration)min"
    }
}

// 用于插入数据库的结构
struct InsertExerciseEntry: Codable {
    var type: String
    var duration: Int
    var calories: Int
    var date: Date
    var userId: UUID?
    
    enum CodingKeys: String, CodingKey {
        case type, duration, calories, date
        case userId = "user_id"
    }
}
