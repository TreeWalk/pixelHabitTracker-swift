import Foundation
import SwiftData

@MainActor
class SwiftDataBookStore: ObservableObject {
    private var modelContext: ModelContext?

    @Published var books: [BookEntryData] = []
    @Published var isLoading = false
    @Published var error: String?
    @Published var lastSaveError: Error?

    // MARK: - Private Helpers

    /// 统一的保存方法，带错误处理
    private func saveContext() {
        guard let context = modelContext else { return }
        do {
            try context.save()
            lastSaveError = nil
        } catch {
            lastSaveError = error
            self.error = "保存失败: \(error.localizedDescription)"
            print("❌ SwiftDataBookStore 保存失败: \(error)")
        }
    }

    // MARK: - Configure
    
    func configure(modelContext: ModelContext) async {
        self.modelContext = modelContext
        loadData()
    }
    
    // MARK: - Load Data
    
    private func loadData() {
        guard let context = modelContext else { return }
        
        do {
            let descriptor = FetchDescriptor<BookEntryData>(sortBy: [SortDescriptor(\.createdAt, order: .reverse)])
            books = try context.fetch(descriptor)
        } catch {
            self.error = "加载书籍失败: \(error.localizedDescription)"
        }
    }
    
    // MARK: - Computed Properties
    
    var readingBooks: [BookEntryData] {
        books.filter { $0.status == "reading" }
    }
    
    var finishedBooks: [BookEntryData] {
        books.filter { $0.status == "finished" }
    }
    
    var wantToReadBooks: [BookEntryData] {
        books.filter { $0.status == "wishlist" }
    }
    
    var totalBooksRead: Int {
        finishedBooks.count
    }
    
    var averageRating: Double {
        let rated = books.filter { $0.rating > 0 }
        guard !rated.isEmpty else { return 0 }
        return Double(rated.reduce(0) { $0 + $1.rating }) / Double(rated.count)
    }
    
    // MARK: - CRUD Operations
    
    func addBook(title: String, author: String, status: String = "wishlist", rating: Int = 0, coverIcon: String = "book.fill") {
        guard let context = modelContext else { return }
        
        let book = BookEntryData(
            title: title,
            author: author,
            coverIcon: coverIcon,
            status: status,
            rating: rating,
            startDate: status == "reading" ? Date() : nil,
            finishDate: status == "finished" ? Date() : nil
        )
        
        context.insert(book)
        books.insert(book, at: 0)

        saveContext()
    }

    func updateBook(_ book: BookEntryData, title: String, author: String, status: String, rating: Int) {
        book.title = title
        book.author = author

        // Handle status changes
        if book.status != status {
            if status == "reading" && book.startDate == nil {
                book.startDate = Date()
            }
            if status == "finished" && book.finishDate == nil {
                book.finishDate = Date()
            }
        }

        book.status = status
        book.rating = rating

        saveContext()
    }

    func deleteBook(_ book: BookEntryData) {
        guard let context = modelContext else { return }

        context.delete(book)
        books.removeAll { $0.title == book.title && $0.author == book.author }

        saveContext()
    }

    func updateNotes(_ book: BookEntryData, notes: String) {
        book.notes = notes
        saveContext()
    }
}
