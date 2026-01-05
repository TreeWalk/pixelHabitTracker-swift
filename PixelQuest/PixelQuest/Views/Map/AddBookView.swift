import SwiftUI

struct AddBookView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var bookStore: BookStore
    
    @State private var title = ""
    @State private var author = ""
    @State private var status: ReadingStatus = .wantToRead
    @State private var rating: Int = 0
    @State private var coverColor: BookCoverColor = .blue
    @State private var isSaving = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Preview
                    VStack(spacing: 12) {
                        BookCoverView(color: coverColor, size: 100)
                        
                        if !title.isEmpty {
                            Text(title)
                                .font(.pixel(16))
                                .foregroundColor(Color("PixelBorder"))
                        }
                    }
                    .padding(.top, 20)
                    
                    // Form
                    VStack(spacing: 16) {
                        // Title
                        VStack(alignment: .leading, spacing: 8) {
                            Text("书名")
                                .font(.pixel(14))
                                .foregroundColor(Color("PixelBorder"))
                            TextField("输入书名", text: $title)
                                .font(.pixel(16))
                                .padding()
                                .background(Color("PixelBg"))
                                .pixelBorderSmall()
                        }
                        
                        // Author
                        VStack(alignment: .leading, spacing: 8) {
                            Text("作者")
                                .font(.pixel(14))
                                .foregroundColor(Color("PixelBorder"))
                            TextField("输入作者", text: $author)
                                .font(.pixel(16))
                                .padding()
                                .background(Color("PixelBg"))
                                .pixelBorderSmall()
                        }
                        
                        // Cover Color
                        VStack(alignment: .leading, spacing: 8) {
                            Text("封面颜色")
                                .font(.pixel(14))
                                .foregroundColor(Color("PixelBorder"))
                            
                            HStack(spacing: 12) {
                                ForEach(BookCoverColor.allCases, id: \.self) { color in
                                    Button(action: { coverColor = color }) {
                                        Circle()
                                            .fill(Color(hex: color.color))
                                            .frame(width: 36, height: 36)
                                            .overlay(
                                                Circle()
                                                    .stroke(Color("PixelBorder"), lineWidth: coverColor == color ? 3 : 0)
                                            )
                                    }
                                }
                            }
                        }
                        
                        // Status
                        VStack(alignment: .leading, spacing: 8) {
                            Text("阅读状态")
                                .font(.pixel(14))
                                .foregroundColor(Color("PixelBorder"))
                            
                            HStack(spacing: 10) {
                                ForEach(ReadingStatus.allCases, id: \.self) { st in
                                    Button(action: { status = st }) {
                                        HStack(spacing: 4) {
                                            Image(systemName: st.icon)
                                                .font(.system(size: 12))
                                            Text(st.rawValue)
                                                .font(.pixel(12))
                                        }
                                        .foregroundColor(status == st ? .white : Color(st.color))
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 8)
                                        .background(status == st ? Color(st.color) : Color.white)
                                        .pixelBorderSmall(color: Color(st.color))
                                    }
                                }
                            }
                        }
                        
                        // Rating
                        VStack(alignment: .leading, spacing: 8) {
                            Text("评分（可选）")
                                .font(.pixel(14))
                                .foregroundColor(Color("PixelBorder"))
                            
                            HStack(spacing: 12) {
                                ForEach(1...5, id: \.self) { index in
                                    Button(action: { rating = rating == index ? 0 : index }) {
                                        Image(systemName: index <= rating ? "star.fill" : "star")
                                            .font(.system(size: 28))
                                            .foregroundColor(index <= rating ? Color("PixelAccent") : Color.gray.opacity(0.3))
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                    
                    // Save Button
                    Button(action: saveBook) {
                        HStack {
                            if isSaving {
                                ProgressView()
                                    .scaleEffect(0.8)
                            }
                            Text("保存")
                                .font(.pixel(18))
                        }
                        .foregroundColor(Color("PixelBorder"))
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color("PixelAccent"))
                        .pixelBorderSmall()
                    }
                    .disabled(title.isEmpty || isSaving)
                    .opacity(title.isEmpty ? 0.5 : 1)
                    .padding(.horizontal)
                }
                .padding(.bottom, 40)
            }
            .background(Color.white)
            .navigationTitle("添加新书")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                        .font(.pixel(14))
                }
            }
        }
    }
    
    func saveBook() {
        isSaving = true
        Task {
            await bookStore.addBook(
                title: title,
                author: author,
                status: status,
                rating: rating,
                coverColor: coverColor
            )
            dismiss()
        }
    }
}
