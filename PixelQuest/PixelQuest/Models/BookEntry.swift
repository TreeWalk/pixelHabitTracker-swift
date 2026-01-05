import Foundation

// MARK: - Reading Status

enum ReadingStatus: String, Codable, CaseIterable {
    case wantToRead = "想读"
    case reading = "在读"
    case finished = "已读完"
    
    var icon: String {
        switch self {
        case .wantToRead: return "bookmark"
        case .reading: return "book"
        case .finished: return "checkmark.circle.fill"
        }
    }
    
    var color: String {
        switch self {
        case .wantToRead: return "PixelAccent"
        case .reading: return "PixelBlue"
        case .finished: return "PixelGreen"
        }
    }
}

// MARK: - Book Cover Colors

enum BookCoverColor: String, Codable, CaseIterable {
    case red = "红色"
    case blue = "蓝色"
    case green = "绿色"
    case purple = "紫色"
    case orange = "橙色"
    case teal = "青色"
    
    var color: String {
        switch self {
        case .red: return "#E57373"
        case .blue: return "#64B5F6"
        case .green: return "#81C784"
        case .purple: return "#BA68C8"
        case .orange: return "#FFB74D"
        case .teal: return "#4DB6AC"
        }
    }
}

// MARK: - Book Entry

struct BookEntry: Identifiable, Codable, Hashable {
    let id: UUID
    var title: String
    var author: String
    var status: ReadingStatus
    var rating: Int  // 1-5
    var coverColor: BookCoverColor
    var startDate: Date?
    var finishDate: Date?
    var date: Date  // 创建日期
    var userId: UUID?
    
    enum CodingKeys: String, CodingKey {
        case id, title, author, status, rating
        case coverColor = "cover_color"
        case startDate = "start_date"
        case finishDate = "finish_date"
        case date
        case userId = "user_id"
    }
    
    // 日期格式化器
    private static let dateOnlyFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone.current
        return formatter
    }()
    
    // 自定义解码器
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(UUID.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        author = try container.decode(String.self, forKey: .author)
        
        let statusString = try container.decode(String.self, forKey: .status)
        status = ReadingStatus(rawValue: statusString) ?? .wantToRead
        
        rating = try container.decode(Int.self, forKey: .rating)
        
        let colorString = try container.decode(String.self, forKey: .coverColor)
        coverColor = BookCoverColor(rawValue: colorString) ?? .blue
        
        // 解码可选日期
        if let startDateString = try container.decodeIfPresent(String.self, forKey: .startDate) {
            startDate = BookEntry.dateOnlyFormatter.date(from: startDateString)
        } else {
            startDate = nil
        }
        
        if let finishDateString = try container.decodeIfPresent(String.self, forKey: .finishDate) {
            finishDate = BookEntry.dateOnlyFormatter.date(from: finishDateString)
        } else {
            finishDate = nil
        }
        
        let dateString = try container.decode(String.self, forKey: .date)
        date = BookEntry.dateOnlyFormatter.date(from: dateString) ?? Date()
        
        userId = try container.decodeIfPresent(UUID.self, forKey: .userId)
    }
    
    init(id: UUID = UUID(), title: String, author: String, status: ReadingStatus = .wantToRead,
         rating: Int = 0, coverColor: BookCoverColor = .blue, startDate: Date? = nil,
         finishDate: Date? = nil, date: Date = Date(), userId: UUID? = nil) {
        self.id = id
        self.title = title
        self.author = author
        self.status = status
        self.rating = rating
        self.coverColor = coverColor
        self.startDate = startDate
        self.finishDate = finishDate
        self.date = date
        self.userId = userId
    }
}

// 用于插入的结构
struct InsertBookEntry: Codable {
    var title: String
    var author: String
    var status: String
    var rating: Int
    var coverColor: String
    var startDate: String?
    var finishDate: String?
    var date: String
    var userId: UUID?
    
    enum CodingKeys: String, CodingKey {
        case title, author, status, rating
        case coverColor = "cover_color"
        case startDate = "start_date"
        case finishDate = "finish_date"
        case date
        case userId = "user_id"
    }
}

// MARK: - Reading Note

struct ReadingNote: Identifiable, Codable, Hashable {
    let id: UUID
    var bookId: UUID
    var content: String
    var page: Int?
    var date: Date
    var userId: UUID?
    
    enum CodingKeys: String, CodingKey {
        case id, content, page, date
        case bookId = "book_id"
        case userId = "user_id"
    }
    
    private static let dateOnlyFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone.current
        return formatter
    }()
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(UUID.self, forKey: .id)
        bookId = try container.decode(UUID.self, forKey: .bookId)
        content = try container.decode(String.self, forKey: .content)
        page = try container.decodeIfPresent(Int.self, forKey: .page)
        
        let dateString = try container.decode(String.self, forKey: .date)
        date = ReadingNote.dateOnlyFormatter.date(from: dateString) ?? Date()
        
        userId = try container.decodeIfPresent(UUID.self, forKey: .userId)
    }
    
    init(id: UUID = UUID(), bookId: UUID, content: String, page: Int? = nil,
         date: Date = Date(), userId: UUID? = nil) {
        self.id = id
        self.bookId = bookId
        self.content = content
        self.page = page
        self.date = date
        self.userId = userId
    }
}

// 用于插入的结构
struct InsertReadingNote: Codable {
    var bookId: UUID
    var content: String
    var page: Int?
    var date: String
    var userId: UUID?
    
    enum CodingKeys: String, CodingKey {
        case content, page, date
        case bookId = "book_id"
        case userId = "user_id"
    }
}
