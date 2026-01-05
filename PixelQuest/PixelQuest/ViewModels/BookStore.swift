import Foundation
import Supabase

@MainActor
class BookStore: ObservableObject {
    @Published var books: [BookEntry] = []
    @Published var notes: [ReadingNote] = []
    @Published var isLoading = false
    @Published var error: String?
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
    
    // MARK: - Computed Properties
    
    var readingBooks: [BookEntry] {
        books.filter { $0.status == .reading }
    }
    
    var finishedBooks: [BookEntry] {
        books.filter { $0.status == .finished }
    }
    
    var wantToReadBooks: [BookEntry] {
        books.filter { $0.status == .wantToRead }
    }
    
    // MARK: - Book Operations
    
    func fetchBooks() async {
        isLoading = true
        error = nil
        
        do {
            let response: [BookEntry] = try await supabase
                .from("books")
                .select()
                .order("date", ascending: false)
                .execute()
                .value
            books = response
        } catch {
            self.error = "获取书籍失败: \(error.localizedDescription)"
            print("Fetch books error: \(error)")
        }
        
        isLoading = false
    }
    
    func addBook(title: String, author: String, status: ReadingStatus, rating: Int, coverColor: BookCoverColor) async {
        let newBook = BookEntry(
            title: title,
            author: author,
            status: status,
            rating: rating,
            coverColor: coverColor,
            startDate: status == .reading ? Date() : nil,
            finishDate: status == .finished ? Date() : nil,
            userId: supabase.auth.currentUser?.id
        )
        
        books.insert(newBook, at: 0)
        
        let insertBook = InsertBookEntry(
            title: title,
            author: author,
            status: status.rawValue,
            rating: rating,
            coverColor: coverColor.rawValue,
            startDate: status == .reading ? dateFormatter.string(from: Date()) : nil,
            finishDate: status == .finished ? dateFormatter.string(from: Date()) : nil,
            date: dateFormatter.string(from: Date()),
            userId: supabase.auth.currentUser?.id
        )
        
        do {
            try await supabase.from("books").insert(insertBook).execute()
        } catch {
            self.error = "添加书籍失败: \(error.localizedDescription)"
            print("Insert book error: \(error)")
        }
    }
    
    func updateBook(_ book: BookEntry) async {
        if let index = books.firstIndex(where: { $0.id == book.id }) {
            books[index] = book
        }
        
        struct UpdateBookData: Codable {
            let title: String
            let author: String
            let status: String
            let rating: Int
            let cover_color: String
            let start_date: String?
            let finish_date: String?
        }
        
        let updateData = UpdateBookData(
            title: book.title,
            author: book.author,
            status: book.status.rawValue,
            rating: book.rating,
            cover_color: book.coverColor.rawValue,
            start_date: book.startDate.map { dateFormatter.string(from: $0) },
            finish_date: book.finishDate.map { dateFormatter.string(from: $0) }
        )
        
        do {
            try await supabase.from("books")
                .update(updateData)
                .eq("id", value: book.id)
                .execute()
        } catch {
            self.error = "更新书籍失败: \(error.localizedDescription)"
            print("Update book error: \(error)")
        }
    }
    
    func deleteBook(_ book: BookEntry) async {
        books.removeAll { $0.id == book.id }
        notes.removeAll { $0.bookId == book.id }
        
        do {
            try await supabase.from("books").delete().eq("id", value: book.id).execute()
            try await supabase.from("reading_notes").delete().eq("book_id", value: book.id).execute()
        } catch {
            self.error = "删除书籍失败: \(error.localizedDescription)"
            print("Delete book error: \(error)")
        }
    }
    
    // MARK: - Notes Operations
    
    func fetchNotes(for bookId: UUID) async {
        do {
            let response: [ReadingNote] = try await supabase
                .from("reading_notes")
                .select()
                .eq("book_id", value: bookId)
                .order("date", ascending: false)
                .execute()
                .value
            
            // 更新笔记列表
            notes.removeAll { $0.bookId == bookId }
            notes.append(contentsOf: response)
        } catch {
            print("Fetch notes error: \(error)")
        }
    }
    
    func addNote(bookId: UUID, content: String, page: Int? = nil) async {
        let newNote = ReadingNote(
            bookId: bookId,
            content: content,
            page: page,
            userId: supabase.auth.currentUser?.id
        )
        
        notes.insert(newNote, at: 0)
        
        let insertNote = InsertReadingNote(
            bookId: bookId,
            content: content,
            page: page,
            date: dateFormatter.string(from: Date()),
            userId: supabase.auth.currentUser?.id
        )
        
        do {
            try await supabase.from("reading_notes").insert(insertNote).execute()
        } catch {
            print("Insert note error: \(error)")
        }
    }
    
    func deleteNote(_ note: ReadingNote) async {
        notes.removeAll { $0.id == note.id }
        
        do {
            try await supabase.from("reading_notes").delete().eq("id", value: note.id).execute()
        } catch {
            print("Delete note error: \(error)")
        }
    }
    
    func notesFor(bookId: UUID) -> [ReadingNote] {
        notes.filter { $0.bookId == bookId }
    }
    
    // MARK: - Local Operations
    
    func addBookLocally(title: String, author: String, status: ReadingStatus, rating: Int, coverColor: BookCoverColor) {
        let newBook = BookEntry(
            title: title,
            author: author,
            status: status,
            rating: rating,
            coverColor: coverColor
        )
        books.insert(newBook, at: 0)
    }
}
