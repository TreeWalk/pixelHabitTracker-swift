import Foundation
import SwiftData

@Model
final class SleepEntryData {
    var bedTime: Date
    var wakeTime: Date
    var quality: Int  // 1-5 rating
    var date: Date
    
    // HealthKit data (optional)
    var deepSleep: Double?  // TimeInterval in seconds
    var coreSleep: Double?
    var remSleep: Double?
    var awakeTime: Double?
    var sleepScore: Int?
    var isFromHealthKit: Bool
    
    init(
        bedTime: Date,
        wakeTime: Date,
        quality: Int,
        date: Date = Date(),
        deepSleep: Double? = nil,
        coreSleep: Double? = nil,
        remSleep: Double? = nil,
        awakeTime: Double? = nil,
        sleepScore: Int? = nil,
        isFromHealthKit: Bool = false
    ) {
        self.bedTime = bedTime
        self.wakeTime = wakeTime
        self.quality = quality
        self.date = date
        self.deepSleep = deepSleep
        self.coreSleep = coreSleep
        self.remSleep = remSleep
        self.awakeTime = awakeTime
        self.sleepScore = sleepScore
        self.isFromHealthKit = isFromHealthKit
    }
    
    // Computed properties
    var durationHours: Double {
        var duration = wakeTime.timeIntervalSince(bedTime)
        if duration < 0 {
            duration += 24 * 3600
        }
        return duration / 3600
    }
    
    var formattedDuration: String {
        let hours = Int(durationHours)
        let minutes = Int((durationHours - Double(hours)) * 60)
        return "\(hours)h \(minutes)m"
    }
    
    var totalSleepFromStages: Double {
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
    
    var awakePercent: Double {
        let total = totalSleepFromStages + (awakeTime ?? 0)
        guard total > 0 else { return 0 }
        return ((awakeTime ?? 0) / total) * 100
    }
    
    var scoreLevel: String {
        guard let score = sleepScore else { return "" }
        switch score {
        case 85...100: return "优秀"
        case 70..<85: return "良好"
        case 55..<70: return "一般"
        default: return "较差"
        }
    }
    
    func formatDuration(_ interval: Double?) -> String {
        guard let interval = interval else { return "--" }
        let hours = Int(interval / 3600)
        let minutes = Int((interval.truncatingRemainder(dividingBy: 3600)) / 60)
        if hours > 0 {
            return "\(hours)h\(minutes)m"
        }
        return "\(minutes)m"
    }
}
