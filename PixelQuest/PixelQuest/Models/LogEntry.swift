import Foundation

struct LogEntry: Identifiable, Codable {
    let id: UUID
    var locationId: Int
    var text: String
    var date: Date
    var userId: UUID?
    
    enum CodingKeys: String, CodingKey {
        case id, text, date
        case locationId = "location_id"
        case userId = "user_id"
    }
    
    // 用于显示的格式化日期
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
}

// 用于插入数据库的结构（不包含 ID）
struct InsertLogEntry: Codable {
    var locationId: Int
    var text: String
    var date: Date
    var userId: UUID?
    
    enum CodingKeys: String, CodingKey {
        case text, date
        case locationId = "location_id"
        case userId = "user_id"
    }
}
