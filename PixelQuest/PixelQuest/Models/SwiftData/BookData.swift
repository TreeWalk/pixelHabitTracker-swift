import Foundation
import SwiftData

@Model
final class BookEntryData {
    var title: String
    var author: String
    var coverIcon: String
    var coverColor: String // BookCoverColor rawValue
    var status: String // reading, finished, wishlist
    var rating: Int // 1-5
    var startDate: Date?
    var finishDate: Date?
    var notes: String?
    var createdAt: Date
    
    init(
        title: String,
        author: String,
        coverIcon: String = "book.fill",
        coverColor: String = "蓝色",
        status: String = "wishlist",
        rating: Int = 0,
        startDate: Date? = nil,
        finishDate: Date? = nil,
        notes: String? = nil,
        createdAt: Date = Date()
    ) {
        self.title = title
        self.author = author
        self.coverIcon = coverIcon
        self.coverColor = coverColor
        self.status = status
        self.rating = rating
        self.startDate = startDate
        self.finishDate = finishDate
        self.notes = notes
        self.createdAt = createdAt
    }
}
