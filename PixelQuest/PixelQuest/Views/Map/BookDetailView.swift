import SwiftUI

struct BookDetailView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var bookStore: BookStore
    let book: BookEntry
    
    @State private var editedBook: BookEntry
    @State private var isEditing = false
    @State private var showDeleteAlert = false
    @State private var newNoteContent = ""
    @State private var showAddNote = false
    
    init(book: BookEntry) {
        self.book = book
        self._editedBook = State(initialValue: book)
    }
    
    var body: some View {
        GeometryReader { geometry in
            let contentWidth = geometry.size.width - 32
            
            ZStack {
                Color("PixelBg").ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Book Cover
                        BookCoverView(color: editedBook.coverColor, size: 120)
                            .padding(.top, 20)
                        
                        // Title & Author
                        VStack(spacing: 8) {
                            Text(editedBook.title)
                                .font(.pixel(24))
                                .foregroundColor(Color("PixelBorder"))
                                .multilineTextAlignment(.center)
                            
                            Text(editedBook.author)
                                .font(.pixel(16))
                                .foregroundColor(Color("PixelBorder").opacity(0.7))
                        }
                        
                        // Rating
                        HStack(spacing: 8) {
                            ForEach(1...5, id: \.self) { index in
                                Button(action: {
                                    editedBook.rating = index
                                    Task { await bookStore.updateBook(editedBook) }
                                }) {
                                    Image(systemName: index <= editedBook.rating ? "star.fill" : "star")
                                        .font(.system(size: 24))
                                        .foregroundColor(index <= editedBook.rating ? Color("PixelAccent") : Color.gray.opacity(0.3))
                                }
                            }
                        }
                        
                        // Status & Dates Card
                        VStack(spacing: 16) {
                            // Status Picker
                            HStack {
                                Text("阅读状态")
                                    .font(.pixel(14))
                                    .foregroundColor(Color("PixelBorder"))
                                Spacer()
                                
                                Menu {
                                    ForEach(ReadingStatus.allCases, id: \.self) { status in
                                        Button(action: {
                                            editedBook.status = status
                                            if status == .reading && editedBook.startDate == nil {
                                                editedBook.startDate = Date()
                                            }
                                            if status == .finished && editedBook.finishDate == nil {
                                                editedBook.finishDate = Date()
                                            }
                                            Task { await bookStore.updateBook(editedBook) }
                                        }) {
                                            Label(status.rawValue, systemImage: status.icon)
                                        }
                                    }
                                } label: {
                                    HStack(spacing: 6) {
                                        Image(systemName: editedBook.status.icon)
                                        Text(editedBook.status.rawValue)
                                            .font(.pixel(14))
                                        Image(systemName: "chevron.down")
                                            .font(.system(size: 10))
                                    }
                                    .foregroundColor(Color(editedBook.status.color))
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(Color(editedBook.status.color).opacity(0.1))
                                    .pixelBorderSmall(color: Color(editedBook.status.color))
                                }
                            }
                            
                            Divider()
                            
                            // Dates
                            if let startDate = editedBook.startDate {
                                HStack {
                                    Image(systemName: "calendar")
                                        .foregroundColor(Color("PixelBlue"))
                                    Text("开始阅读")
                                        .font(.pixel(14))
                                        .foregroundColor(Color("PixelBorder"))
                                    Spacer()
                                    Text(formatDate(startDate))
                                        .font(.pixel(14))
                                        .foregroundColor(Color("PixelBlue"))
                                }
                            }
                            
                            if let finishDate = editedBook.finishDate {
                                HStack {
                                    Image(systemName: "checkmark.circle")
                                        .foregroundColor(Color("PixelGreen"))
                                    Text("完成阅读")
                                        .font(.pixel(14))
                                        .foregroundColor(Color("PixelBorder"))
                                    Spacer()
                                    Text(formatDate(finishDate))
                                        .font(.pixel(14))
                                        .foregroundColor(Color("PixelGreen"))
                                }
                            }
                        }
                        .padding()
                        .frame(width: contentWidth)
                        .background(Color.white)
                        .pixelBorderSmall()
                        
                        // Notes Section
                        VStack(spacing: 12) {
                            HStack {
                                Image(systemName: "note.text")
                                    .foregroundColor(Color("PixelBlue"))
                                Text("读书笔记")
                                    .font(.pixel(16))
                                    .foregroundColor(Color("PixelBorder"))
                                Spacer()
                                
                                Button(action: { showAddNote = true }) {
                                    HStack(spacing: 4) {
                                        Image(systemName: "plus")
                                        Text("添加")
                                            .font(.pixel(12))
                                    }
                                    .foregroundColor(Color("PixelBlue"))
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(Color("PixelBlue").opacity(0.1))
                                    .pixelBorderSmall(color: Color("PixelBlue"))
                                }
                            }
                            
                            let bookNotes = bookStore.notesFor(bookId: book.id)
                            
                            if bookNotes.isEmpty {
                                Text("还没有笔记，点击上方添加")
                                    .font(.pixel(12))
                                    .foregroundColor(Color("PixelBorder").opacity(0.5))
                                    .padding(.vertical, 20)
                            } else {
                                ForEach(bookNotes) { note in
                                    NoteCard(note: note) {
                                        Task { await bookStore.deleteNote(note) }
                                    }
                                }
                            }
                        }
                        .padding()
                        .frame(width: contentWidth)
                        .background(Color.white)
                        .pixelBorderSmall()
                        
                        // Delete Button
                        Button(action: { showDeleteAlert = true }) {
                            HStack {
                                Image(systemName: "trash")
                                Text("删除这本书")
                                    .font(.pixel(14))
                            }
                            .foregroundColor(.red)
                            .padding()
                            .frame(width: contentWidth)
                            .background(Color.red.opacity(0.1))
                            .pixelBorderSmall(color: .red)
                        }
                        .padding(.top, 10)
                    }
                    .frame(width: geometry.size.width)
                    .padding(.vertical, 16)
                }
            }
        }
        .navigationTitle(book.title)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { dismiss() }) {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.left")
                        Text("返回")
                    }
                    .font(.pixel(16))
                    .foregroundColor(Color("PixelBorder"))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color("PixelAccent"))
                    .pixelBorderSmall()
                }
            }
        }
        .sheet(isPresented: $showAddNote) {
            AddNoteView(bookId: book.id)
        }
        .alert("确定删除？", isPresented: $showDeleteAlert) {
            Button("取消", role: .cancel) { }
            Button("删除", role: .destructive) {
                Task {
                    await bookStore.deleteBook(book)
                    dismiss()
                }
            }
        } message: {
            Text("删除后将无法恢复")
        }
        .onAppear {
            Task { await bookStore.fetchNotes(for: book.id) }
        }
    }
    
    func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
}

// MARK: - Note Card

struct NoteCard: View {
    let note: ReadingNote
    let onDelete: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                if let page = note.page {
                    Text("P.\(page)")
                        .font(.pixel(10))
                        .foregroundColor(Color("PixelBlue"))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color("PixelBlue").opacity(0.1))
                        .cornerRadius(4)
                }
                
                Spacer()
                
                Text(formatDate(note.date))
                    .font(.pixel(10))
                    .foregroundColor(Color("PixelBorder").opacity(0.5))
                
                Button(action: onDelete) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 14))
                        .foregroundColor(Color.gray.opacity(0.5))
                }
            }
            
            Text(note.content)
                .font(.pixel(12))
                .foregroundColor(Color("PixelBorder"))
                .lineLimit(nil)
        }
        .padding()
        .background(Color("PixelBg"))
        .cornerRadius(8)
    }
    
    func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM-dd"
        return formatter.string(from: date)
    }
}

// MARK: - Add Note View

struct AddNoteView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var bookStore: BookStore
    let bookId: UUID
    
    @State private var content = ""
    @State private var pageText = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Page Input (Optional)
                HStack {
                    Text("页码（可选）")
                        .font(.pixel(14))
                        .foregroundColor(Color("PixelBorder"))
                    Spacer()
                    TextField("", text: $pageText)
                        .keyboardType(.numberPad)
                        .font(.pixel(14))
                        .frame(width: 80)
                        .padding(8)
                        .background(Color("PixelBg"))
                        .pixelBorderSmall()
                }
                .padding(.horizontal)
                
                // Content Input
                VStack(alignment: .leading, spacing: 8) {
                    Text("笔记内容")
                        .font(.pixel(14))
                        .foregroundColor(Color("PixelBorder"))
                    
                    TextEditor(text: $content)
                        .font(.pixel(14))
                        .frame(minHeight: 150)
                        .padding(8)
                        .background(Color("PixelBg"))
                        .pixelBorderSmall()
                }
                .padding(.horizontal)
                
                Spacer()
            }
            .padding(.top, 20)
            .navigationTitle("添加笔记")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                        .font(.pixel(14))
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        let page = Int(pageText)
                        Task {
                            await bookStore.addNote(bookId: bookId, content: content, page: page)
                            dismiss()
                        }
                    }
                    .font(.pixel(14))
                    .disabled(content.isEmpty)
                }
            }
        }
    }
}
