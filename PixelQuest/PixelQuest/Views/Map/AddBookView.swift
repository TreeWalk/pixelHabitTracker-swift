import SwiftUI

struct AddBookView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var bookStore: SwiftDataBookStore
    
    @State private var title = ""
    @State private var author = ""
    @State private var status: ReadingStatus = .wantToRead
    @State private var rating: Int = 0
    @State private var coverColor: BookCoverColor = .blue
    @State private var isSaving = false
    
    // Animation states
    @State private var bookFloatOffset: CGFloat = 0
    @State private var selectedColorScale: CGFloat = 1.0
    @State private var saveButtonPressed = false
    
    // Haptic feedback
    private static let lightHaptic = UIImpactFeedbackGenerator(style: .light)
    private static let mediumHaptic = UIImpactFeedbackGenerator(style: .medium)
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                Color("PixelBg").ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // MARK: - Hero Book Preview Section
                        VStack(spacing: 16) {
                            // Floating Book Cover
                            BookCoverView(color: coverColor, size: 140)
                                .offset(y: bookFloatOffset)
                                .shadow(color: Color("PixelBorder").opacity(0.3), radius: 8, x: 0, y: 8)
                                .onAppear {
                                    withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                                        bookFloatOffset = -6
                                    }
                                }
                            
                            // Dynamic Title Display
                            VStack(spacing: 4) {
                                Text(title.isEmpty ? "新书标题" : title)
                                    .font(.pixel(20))
                                    .foregroundColor(title.isEmpty ? Color("PixelBorder").opacity(0.4) : Color("PixelBorder"))
                                    .lineLimit(1)
                                
                                Text(author.isEmpty ? "作者" : author)
                                    .font(.pixel(14))
                                    .foregroundColor(author.isEmpty ? Color("PixelBorder").opacity(0.3) : Color("PixelBorder").opacity(0.7))
                                    .lineLimit(1)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 24)
                        .pixelDoubleBorder(outerColor: .darkCoffee, innerColor: Color.white.opacity(0.2))
                        .background(Color.white)
                        .pixelHardShadow(offset: 4)
                        .padding(.horizontal, 16)
                        .padding(.top, 8)
                        
                        // MARK: - Book Info Section
                        VStack(alignment: .leading, spacing: 16) {
                            // Section Header
                            HStack(spacing: 8) {
                                Image(systemName: "book.closed.fill")
                                    .font(.system(size: 14))
                                    .foregroundColor(Color("PixelBlue"))
                                Text("书籍信息")
                                    .font(.pixel(16))
                                    .foregroundColor(Color("PixelBorder"))
                            }
                            
                            // Title Field
                            VStack(alignment: .leading, spacing: 6) {
                                Text("书名")
                                    .font(.pixel(12))
                                    .foregroundColor(Color("PixelBorder").opacity(0.7))
                                
                                TextField("输入书名", text: $title)
                                    .font(.pixel(18))
                                    .padding(12)
                                    .background(Color("PixelBg"))
                                    .pixelBorderSmall()
                            }
                            
                            // Author Field
                            VStack(alignment: .leading, spacing: 6) {
                                Text("作者")
                                    .font(.pixel(12))
                                    .foregroundColor(Color("PixelBorder").opacity(0.7))
                                
                                TextField("输入作者", text: $author)
                                    .font(.pixel(18))
                                    .padding(12)
                                    .background(Color("PixelBg"))
                                    .pixelBorderSmall()
                            }
                        }
                        .padding(16)
                        .pixelDoubleBorder(outerColor: .darkCoffee, innerColor: Color("PixelBlue").opacity(0.2))
                        .background(Color.white)
                        .pixelHardShadow(offset: 4)
                        .padding(.horizontal, 16)
                        
                        // MARK: - Cover Color Section
                        VStack(alignment: .leading, spacing: 16) {
                            // Section Header
                            HStack(spacing: 8) {
                                Image(systemName: "paintpalette.fill")
                                    .font(.system(size: 14))
                                    .foregroundColor(Color("PixelAccent"))
                                Text("封面颜色")
                                    .font(.pixel(16))
                                    .foregroundColor(Color("PixelBorder"))
                            }
                            
                            // Book Spine Color Picker
                            HStack(spacing: 12) {
                                ForEach(BookCoverColor.allCases, id: \.self) { color in
                                    BookSpineColorButton(
                                        color: color,
                                        isSelected: coverColor == color,
                                        action: {
                                            Self.lightHaptic.impactOccurred()
                                            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                                coverColor = color
                                            }
                                        }
                                    )
                                }
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .padding(16)
                        .pixelDoubleBorder(outerColor: .darkCoffee, innerColor: Color("PixelAccent").opacity(0.2))
                        .background(Color.white)
                        .pixelHardShadow(offset: 4)
                        .padding(.horizontal, 16)
                        
                        // MARK: - Reading Status Section
                        VStack(alignment: .leading, spacing: 16) {
                            // Section Header
                            HStack(spacing: 8) {
                                Image(systemName: "bookmark.fill")
                                    .font(.system(size: 14))
                                    .foregroundColor(Color("PixelGreen"))
                                Text("阅读状态")
                                    .font(.pixel(16))
                                    .foregroundColor(Color("PixelBorder"))
                            }
                            
                            // Status Buttons
                            HStack(spacing: 8) {
                                ForEach(ReadingStatus.allCases, id: \.self) { st in
                                    StatusButton(
                                        status: st,
                                        isSelected: status == st,
                                        action: {
                                            Self.mediumHaptic.impactOccurred()
                                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                                status = st
                                            }
                                        }
                                    )
                                }
                            }
                        }
                        .padding(16)
                        .pixelDoubleBorder(outerColor: .darkCoffee, innerColor: Color("PixelGreen").opacity(0.2))
                        .background(Color.white)
                        .pixelHardShadow(offset: 4)
                        .padding(.horizontal, 16)
                        
                        // MARK: - Rating Section
                        VStack(alignment: .leading, spacing: 16) {
                            // Section Header
                            HStack(spacing: 8) {
                                Image(systemName: "star.fill")
                                    .font(.system(size: 14))
                                    .foregroundColor(Color("PixelAccent"))
                                Text("评分（可选）")
                                    .font(.pixel(16))
                                    .foregroundColor(Color("PixelBorder"))
                            }
                            
                            // Star Rating
                            HStack(spacing: 16) {
                                ForEach(1...5, id: \.self) { index in
                                    StarButton(
                                        index: index,
                                        rating: rating,
                                        action: {
                                            Self.lightHaptic.impactOccurred()
                                            withAnimation(.spring(response: 0.25, dampingFraction: 0.5)) {
                                                rating = rating == index ? 0 : index
                                            }
                                        }
                                    )
                                }
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .padding(16)
                        .pixelDoubleBorder(outerColor: .darkCoffee, innerColor: Color("PixelAccent").opacity(0.2))
                        .background(Color.white)
                        .pixelHardShadow(offset: 4)
                        .padding(.horizontal, 16)
                        
                        // MARK: - Save Button
                        Button(action: saveBook) {
                            HStack(spacing: 10) {
                                if isSaving {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: Color("PixelBorder")))
                                        .scaleEffect(0.8)
                                } else {
                                    Image(systemName: "book.closed.fill")
                                        .font(.system(size: 16))
                                }
                                
                                Text(isSaving ? "保存中..." : "添加到书架")
                                    .font(.pixel(20))
                            }
                            .foregroundColor(Color("PixelBorder"))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                title.isEmpty ? Color("PixelAccent").opacity(0.5) : Color("PixelAccent")
                            )
                            .pixelBorderSmall()
                            .scaleEffect(saveButtonPressed ? 0.97 : 1.0)
                        }
                        .disabled(title.isEmpty || isSaving)
                        .simultaneousGesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged { _ in
                                    if !title.isEmpty {
                                        withAnimation(.easeInOut(duration: 0.1)) {
                                            saveButtonPressed = true
                                        }
                                    }
                                }
                                .onEnded { _ in
                                    withAnimation(.easeInOut(duration: 0.1)) {
                                        saveButtonPressed = false
                                    }
                                }
                        )
                        .padding(.horizontal, 16)
                        .padding(.top, 8)
                        
                        Spacer(minLength: 40)
                    }
                    .padding(.bottom, 20)
                }
            }
            .navigationTitle("添加新书")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(action: { dismiss() }) {
                        HStack(spacing: 4) {
                            Image(systemName: "xmark")
                            Text("取消")
                        }
                        .font(.pixel(14))
                        .foregroundColor(Color("PixelBorder"))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color.white)
                        .pixelBorderSmall()
                    }
                }
            }
        }
    }
    
    func saveBook() {
        Self.mediumHaptic.impactOccurred()
        isSaving = true
        
        // Convert ReadingStatus enum to status string expected by SwiftDataBookStore
        let statusString: String
        switch status {
        case .reading: statusString = "reading"
        case .finished: statusString = "finished"
        case .wantToRead: statusString = "wishlist"
        }
        
        bookStore.addBook(
            title: title,
            author: author,
            status: statusString,
            rating: rating,
            coverIcon: "book.fill",
            coverColor: coverColor.rawValue
        )
        dismiss()
    }
}

// MARK: - Book Spine Color Button

struct BookSpineColorButton: View {
    let color: BookCoverColor
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                // Mini Book Spine
                ZStack(alignment: .leading) {
                    // Book body
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color(hex: color.color))
                        .frame(width: 28, height: 40)
                    
                    // Spine highlight
                    Rectangle()
                        .fill(LinearGradient(
                            colors: [.white.opacity(0.4), .clear],
                            startPoint: .leading,
                            endPoint: .trailing
                        ))
                        .frame(width: 6, height: 40)
                    
                    // Decorative lines
                    VStack(spacing: 4) {
                        Rectangle()
                            .fill(Color.white.opacity(0.3))
                            .frame(width: 16, height: 2)
                        Rectangle()
                            .fill(Color.white.opacity(0.2))
                            .frame(width: 12, height: 2)
                    }
                    .padding(.leading, 6)
                    .padding(.top, 8)
                }
                .overlay(
                    RoundedRectangle(cornerRadius: 2)
                        .stroke(Color("PixelBorder"), lineWidth: isSelected ? 3 : 1.5)
                )
                .shadow(color: .black.opacity(0.2), radius: 0, x: 2, y: 2)
                .scaleEffect(isSelected ? 1.15 : 1.0)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Status Button

struct StatusButton: View {
    let status: ReadingStatus
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: status.icon)
                    .font(.system(size: 14, weight: isSelected ? .semibold : .regular))
                Text(status.rawValue)
                    .font(.pixel(14))
            }
            .foregroundColor(isSelected ? .white : Color(status.color))
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity)
            .background(isSelected ? Color(status.color) : Color.white)
            .pixelBorderSmall(color: Color(status.color))
            .scaleEffect(isSelected ? 1.02 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Star Button

struct StarButton: View {
    let index: Int
    let rating: Int
    let action: () -> Void
    
    private var isFilled: Bool {
        index <= rating
    }
    
    var body: some View {
        Button(action: action) {
            Image(systemName: isFilled ? "star.fill" : "star")
                .font(.system(size: 32))
                .foregroundColor(isFilled ? Color("PixelAccent") : Color.gray.opacity(0.3))
                .scaleEffect(isFilled ? 1.1 : 1.0)
                .animation(.spring(response: 0.25, dampingFraction: 0.5), value: isFilled)
        }
        .buttonStyle(PlainButtonStyle())
    }
}
