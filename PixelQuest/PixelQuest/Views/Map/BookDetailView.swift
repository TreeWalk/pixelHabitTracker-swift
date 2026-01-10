import SwiftUI

struct BookDetailView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var bookStore: SwiftDataBookStore
    let book: BookEntryData
    
    @State private var showDeleteAlert = false
    @State private var editedRating: Int
    @State private var editedStatus: String
    
    // Convert status string to ReadingStatus for display
    private var readingStatus: ReadingStatus {
        switch editedStatus {
        case "reading": return .reading
        case "finished": return .finished
        default: return .wantToRead
        }
    }
    
    init(book: BookEntryData) {
        self.book = book
        self._editedRating = State(initialValue: book.rating)
        self._editedStatus = State(initialValue: book.status)
    }
    
    var body: some View {
        GeometryReader { geometry in
            let contentWidth = geometry.size.width - 32
            
            ZStack {
                Color("PixelBg").ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Book Cover
                        BookCoverView(color: .blue, size: 120)
                            .padding(.top, 20)
                        
                        // Title & Author
                        VStack(spacing: 8) {
                            Text(book.title)
                                .font(.pixel(24))
                                .foregroundColor(Color("PixelBorder"))
                                .multilineTextAlignment(.center)
                            
                            Text(book.author)
                                .font(.pixel(16))
                                .foregroundColor(Color("PixelBorder").opacity(0.7))
                        }
                        
                        // Rating
                        HStack(spacing: 8) {
                            ForEach(1...5, id: \.self) { index in
                                Button(action: {
                                    editedRating = index
                                    bookStore.updateBook(book, title: book.title, author: book.author, status: editedStatus, rating: index)
                                }) {
                                    Image(systemName: index <= editedRating ? "star.fill" : "star")
                                        .font(.system(size: 24))
                                        .foregroundColor(index <= editedRating ? Color("PixelAccent") : Color.gray.opacity(0.3))
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
                                            let newStatus: String
                                            switch status {
                                            case .reading: newStatus = "reading"
                                            case .finished: newStatus = "finished"
                                            case .wantToRead: newStatus = "wishlist"
                                            }
                                            editedStatus = newStatus
                                            bookStore.updateBook(book, title: book.title, author: book.author, status: newStatus, rating: editedRating)
                                        }) {
                                            Label(status.rawValue, systemImage: status.icon)
                                        }
                                    }
                                } label: {
                                    HStack(spacing: 6) {
                                        Image(systemName: readingStatus.icon)
                                        Text(readingStatus.rawValue)
                                            .font(.pixel(14))
                                        Image(systemName: "chevron.down")
                                            .font(.system(size: 10))
                                    }
                                    .foregroundColor(Color(readingStatus.color))
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(Color(readingStatus.color).opacity(0.1))
                                    .pixelBorderSmall(color: Color(readingStatus.color))
                                }
                            }
                            
                            Divider()
                            
                            // Dates
                            if let startDate = book.startDate {
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
                            
                            if let finishDate = book.finishDate {
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
                        
                        // Notes display (simplified - just show notes string if exists)
                        if let notes = book.notes, !notes.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Image(systemName: "note.text")
                                        .foregroundColor(Color("PixelBlue"))
                                    Text("读书笔记")
                                        .font(.pixel(16))
                                        .foregroundColor(Color("PixelBorder"))
                                    Spacer()
                                }
                                
                                Text(notes)
                                    .font(.pixel(12))
                                    .foregroundColor(Color("PixelBorder"))
                            }
                            .padding()
                            .frame(width: contentWidth, alignment: .leading)
                            .background(Color.white)
                            .pixelBorderSmall()
                        }
                        
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
        .alert("确定删除？", isPresented: $showDeleteAlert) {
            Button("取消", role: .cancel) { }
            Button("删除", role: .destructive) {
                bookStore.deleteBook(book)
                dismiss()
            }
        } message: {
            Text("删除后将无法恢复")
        }
    }
    
    func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
}
