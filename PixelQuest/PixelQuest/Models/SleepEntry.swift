import Foundation

struct SleepEntry: Identifiable, Codable, Hashable {
    let id: UUID
    var bedTime: Date      // 入睡时间
    var wakeTime: Date     // 起床时间
    var quality: Int       // 睡眠质量 1-5 (手动评分)
    var date: Date         // 记录日期
    var userId: UUID?
    
    // HealthKit 同步的睡眠阶段数据
    var deepSleep: TimeInterval?     // 深度睡眠时长
    var coreSleep: TimeInterval?     // 核心睡眠时长
    var remSleep: TimeInterval?      // REM睡眠时长
    var awakeTime: TimeInterval?     // 清醒时长
    var sleepScore: Int?             // 睡眠分数 0-100
    var isFromHealthKit: Bool        // 是否来自 HealthKit
    
    enum CodingKeys: String, CodingKey {
        case id
        case bedTime = "bed_time"
        case wakeTime = "wake_time"
        case quality, date
        case userId = "user_id"
        case deepSleep = "deep_sleep"
        case coreSleep = "core_sleep"
        case remSleep = "rem_sleep"
        case awakeTime = "awake_time"
        case sleepScore = "sleep_score"
        case isFromHealthKit = "is_from_healthkit"
    }
    
    // 日期格式化器
    private static let dateOnlyFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone.current
        return formatter
    }()
    
    private static let iso8601Formatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()
    
    private static let iso8601FormatterNoFraction: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }()
    
    // 自定义解码器 - 处理 Supabase 的日期格式
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(UUID.self, forKey: .id)
        quality = try container.decode(Int.self, forKey: .quality)
        userId = try container.decodeIfPresent(UUID.self, forKey: .userId)
        
        // 解码日期字段 (yyyy-MM-dd 格式)
        let dateString = try container.decode(String.self, forKey: .date)
        if let parsedDate = SleepEntry.dateOnlyFormatter.date(from: dateString) {
            date = parsedDate
        } else {
            throw DecodingError.dataCorrupted(.init(codingPath: [CodingKeys.date], debugDescription: "Invalid date format: \(dateString)"))
        }
        
        // 解码时间戳字段 (ISO8601 格式)
        bedTime = try SleepEntry.decodeTimestamp(from: container, forKey: .bedTime)
        wakeTime = try SleepEntry.decodeTimestamp(from: container, forKey: .wakeTime)
        
        // 可选字段
        deepSleep = try container.decodeIfPresent(TimeInterval.self, forKey: .deepSleep)
        coreSleep = try container.decodeIfPresent(TimeInterval.self, forKey: .coreSleep)
        remSleep = try container.decodeIfPresent(TimeInterval.self, forKey: .remSleep)
        awakeTime = try container.decodeIfPresent(TimeInterval.self, forKey: .awakeTime)
        sleepScore = try container.decodeIfPresent(Int.self, forKey: .sleepScore)
        isFromHealthKit = try container.decodeIfPresent(Bool.self, forKey: .isFromHealthKit) ?? false
    }
    
    private static func decodeTimestamp(from container: KeyedDecodingContainer<CodingKeys>, forKey key: CodingKeys) throws -> Date {
        let dateString = try container.decode(String.self, forKey: key)
        
        // 尝试多种格式
        if let date = iso8601Formatter.date(from: dateString) {
            return date
        }
        if let date = iso8601FormatterNoFraction.date(from: dateString) {
            return date
        }
        // Supabase 有时返回这种格式
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        formatter.timeZone = TimeZone(identifier: "UTC")
        if let date = formatter.date(from: dateString) {
            return date
        }
        
        throw DecodingError.dataCorrupted(.init(codingPath: [key], debugDescription: "Invalid timestamp format: \(dateString)"))
    }
    
    // 初始化时设置默认值
    init(id: UUID = UUID(), bedTime: Date, wakeTime: Date, quality: Int, date: Date, userId: UUID? = nil,
         deepSleep: TimeInterval? = nil, coreSleep: TimeInterval? = nil, remSleep: TimeInterval? = nil,
         awakeTime: TimeInterval? = nil, sleepScore: Int? = nil, isFromHealthKit: Bool = false) {
        self.id = id
        self.bedTime = bedTime
        self.wakeTime = wakeTime
        self.quality = quality
        self.date = date
        self.userId = userId
        self.deepSleep = deepSleep
        self.coreSleep = coreSleep
        self.remSleep = remSleep
        self.awakeTime = awakeTime
        self.sleepScore = sleepScore
        self.isFromHealthKit = isFromHealthKit
    }

    
    // 睡眠时长（小时）
    var durationHours: Double {
        let duration = wakeTime.timeIntervalSince(bedTime)
        // 如果起床时间早于入睡时间，说明跨天了
        if duration < 0 {
            return (duration + 24 * 3600) / 3600
        }
        return duration / 3600
    }
    
    // 格式化时长显示
    var formattedDuration: String {
        let hours = Int(durationHours)
        let minutes = Int((durationHours - Double(hours)) * 60)
        return "\(hours)h \(minutes)m"
    }
    
    // 格式化时间
    static func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
    
    // 各阶段占比
    var totalSleepFromStages: TimeInterval {
        (deepSleep ?? 0) + (coreSleep ?? 0) + (remSleep ?? 0)
    }
    
    var deepPercent: Double {
        guard totalSleepFromStages > 0 else { return 0 }
        return ((deepSleep ?? 0) / totalSleepFromStages) * 100
    }
    
    var corePercent: Double {
        guard totalSleepFromStages > 0 else { return 0 }
        return ((coreSleep ?? 0) / totalSleepFromStages) * 100
    }
    
    var remPercent: Double {
        guard totalSleepFromStages > 0 else { return 0 }
        return ((remSleep ?? 0) / totalSleepFromStages) * 100
    }
    
    // 睡眠分数等级
    var scoreLevel: String {
        guard let score = sleepScore else { return "" }
        switch score {
        case 85...100: return "优秀"
        case 70..<85: return "良好"
        case 55..<70: return "一般"
        default: return "较差"
        }
    }
    
    // 格式化睡眠阶段时长
    func formatStageDuration(_ interval: TimeInterval?) -> String {
        guard let interval = interval else { return "--" }
        let hours = Int(interval / 3600)
        let minutes = Int((interval.truncatingRemainder(dividingBy: 3600)) / 60)
        if hours > 0 {
            return "\(hours)h\(minutes)m"
        }
        return "\(minutes)m"
    }
}

// 用于插入数据库的结构（不包含 ID）
struct InsertSleepEntry: Codable {
    var bedTime: Date
    var wakeTime: Date
    var quality: Int
    var date: Date
    var userId: UUID?
    
    enum CodingKeys: String, CodingKey {
        case bedTime = "bed_time"
        case wakeTime = "wake_time"
        case quality, date
        case userId = "user_id"
    }
}
