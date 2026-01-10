import Foundation
import SwiftData

@Model
final class LogEntryData {
    var locationId: Int
    var content: String
    var date: Date
    
    init(locationId: Int, content: String, date: Date = Date()) {
        self.locationId = locationId
        self.content = content
        self.date = date
    }
    
    // Computed properties for view compatibility
    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        return formatter
    }()
    
    var formattedDate: String {
        Self.dateFormatter.string(from: date)
    }
}
