import SwiftUI

struct QuickReadSheet: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var bookStore: SwiftDataBookStore
    
    @State private var selectedBook: BookEntryData?
    @State private var duration: Int = 30
    @State private var note: String = ""
    @State private var isSaving = false
    
    var readingBooks: [BookEntryData] {
        bookStore.readingBooks
    }
    
    var body: some View {
        ZStack {
            Color("PixelBg").ignoresSafeArea()
            
            VStack(spacing: 16) {
                // Header
                HStack {
                    HStack(spacing: 8) {
                        Image(systemName: "book.fill")
                            .font(.system(size: 20))
                            .foregroundColor(Color("PixelGreen"))
                        Text("快速记录阅读")
                            .font(.pixel(22))
                            .foregroundColor(Color("PixelBorder"))
                    }
                    Spacer()
                    Button(action: { dismiss() }) {
                        Text("✕")
                            .font(.pixel(20))
                            .foregroundColor(Color("PixelBorder"))
                            .frame(width: 32, height: 32)
                            .background(Color("PixelAccent"))
                            .pixelBorderSmall()
                    }
                }
                .padding(.horizontal)
                
                // Book Selection Card
                VStack(alignment: .leading, spacing: 8) {
                    Text("选择书籍")
                        .font(.pixel(14))
                        .foregroundColor(Color("PixelBorder").opacity(0.7))
                    
                    if readingBooks.isEmpty {
                        HStack {
                            Image(systemName: "book.closed")
                                .foregroundColor(Color("PixelBorder").opacity(0.5))
                            Text("暂无在读书籍")
                                .font(.pixel(14))
                                .foregroundColor(Color("PixelBorder").opacity(0.5))
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.white)
                        .pixelBorderSmall()
                    } else {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(readingBooks) { book in
                                    Button(action: { selectedBook = book }) {
                                        VStack(spacing: 4) {
                                            Image(systemName: "book.closed.fill")
                                                .font(.system(size: 20))
                                            Text(book.title)
                                                .font(.pixel(10))
                                                .lineLimit(1)
                                        }
                                        .foregroundColor(selectedBook?.title == book.title ? .white : Color("PixelBorder"))
                                        .frame(width: 70, height: 60)
                                        .background(selectedBook?.title == book.title ? Color("PixelGreen") : Color.white)
                                        .pixelBorderSmall(color: selectedBook?.title == book.title ? Color("PixelGreen") : Color("PixelBorder"))
                                    }
                                }
                            }
                        }
                    }
                }
                .padding()
                .background(Color.white)
                .pixelBorderSmall()
                .padding(.horizontal)
                
                // Duration Card
                HStack {
                    Text("阅读时长")
                        .font(.pixel(16))
                        .foregroundColor(Color("PixelBorder"))
                    
                    Spacer()
                    
                    Button(action: { if duration > 10 { duration -= 10 } }) {
                        Text("−")
                            .font(.pixel(24))
                            .foregroundColor(Color("PixelBorder"))
                            .frame(width: 40, height: 40)
                            .background(Color("PixelAccent"))
                            .pixelBorderSmall()
                    }
                    
                    Text("\(duration)")
                        .font(.pixel(28))
                        .foregroundColor(Color("PixelGreen"))
                        .frame(width: 60)
                    
                    Text("分钟")
                        .font(.pixel(14))
                        .foregroundColor(Color("PixelBorder").opacity(0.7))
                    
                    Button(action: { duration += 10 }) {
                        Text("+")
                            .font(.pixel(24))
                            .foregroundColor(Color("PixelBorder"))
                            .frame(width: 40, height: 40)
                            .background(Color("PixelAccent"))
                            .pixelBorderSmall()
                    }
                }
                .padding()
                .background(Color.white)
                .pixelBorderSmall()
                .padding(.horizontal)
                
                // Quick Note Card
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 6) {
                        Image(systemName: "note.text")
                            .foregroundColor(Color("PixelGreen"))
                        Text("快速笔记")
                            .font(.pixel(14))
                            .foregroundColor(Color("PixelBorder").opacity(0.7))
                    }
                    
                    TextField("记录一下读书心得...", text: $note, axis: .vertical)
                        .font(.pixel(14))
                        .lineLimit(2...3)
                        .padding(10)
                        .background(Color("PixelBg"))
                        .pixelBorderSmall()
                }
                .padding()
                .background(Color.white)
                .pixelBorderSmall()
                .padding(.horizontal)
                
                Spacer()
                
                // Save Button
                Button(action: saveReading) {
                    HStack {
                        if isSaving {
                            ProgressView()
                                .scaleEffect(0.8)
                                .tint(Color("PixelBorder"))
                        }
                        Text("记录阅读 ✓")
                            .font(.pixel(22))
                    }
                    .foregroundColor(Color("PixelBorder"))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color("PixelAccent"))
                    .pixelBorderSmall()
                }
                .disabled(isSaving || selectedBook == nil)
                .opacity(selectedBook == nil ? 0.5 : 1)
                .padding(.horizontal)
                .padding(.bottom)
            }
            .padding(.top)
        }
        .onAppear {
            if selectedBook == nil {
                selectedBook = readingBooks.first
            }
        }
    }
    
    func saveReading() {
        guard let book = selectedBook else { return }
        isSaving = true
        
        if !note.isEmpty {
            let existingNotes = book.notes ?? ""
            let newNote = "[\(formattedDate)] \(duration)分钟: \(note)"
            book.notes = existingNotes.isEmpty ? newNote : "\(existingNotes)\n\n\(newNote)"
            bookStore.updateNotes(book, notes: book.notes ?? "")
        }
        
        isSaving = false
        dismiss()
    }
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd"
        return formatter.string(from: Date())
    }
}

#Preview {
    QuickReadSheet()
        .environmentObject(SwiftDataBookStore())
}
