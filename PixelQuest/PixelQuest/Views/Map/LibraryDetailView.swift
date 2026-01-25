import SwiftUI

struct LibraryDetailView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var bookStore: SwiftDataBookStore
    @EnvironmentObject var localizationManager: LocalizationManager
    let location: Location
    
    @State private var showAddBook = false
    @State private var appearAnimation = false
    private let columns = 3
    
    // Haptic feedback
    private static let lightHaptic = UIImpactFeedbackGenerator(style: .light)
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Warm cream background
                Color("PixelBg").ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 0) {
                        // MARK: - Premium Header
                        VStack(spacing: 16) {
                            // Title Row
                            HStack(alignment: .center) {
                                VStack(alignment: .leading, spacing: 6) {
                                    HStack(spacing: 10) {
                                        // Decorative book stack icon
                                        ZStack {
                                            Image(systemName: "books.vertical.fill")
                                                .font(.system(size: 28))
                                                .foregroundColor(Color("PixelBlue"))
                                        }
                                        
                                        Text("library_my_books".localized)
                                            .font(.pixel(28))
                                            .foregroundColor(Color("PixelBorder"))
                                    }
                                    
                                    Text(String(format: "library_books_count".localized, bookStore.books.count))
                                        .font(.pixel(14))
                                        .foregroundColor(Color("PixelBorder").opacity(0.6))
                                }
                                Spacer()
                                
                                // Reading goal progress (decorative)
                                VStack(spacing: 4) {
                                    ZStack {
                                        Circle()
                                            .stroke(Color("PixelBorder").opacity(0.15), lineWidth: 4)
                                            .frame(width: 50, height: 50)
                                        
                                        Circle()
                                            .trim(from: 0, to: min(1, Double(bookStore.books.filter { $0.status == "finished" }.count) / max(1, Double(bookStore.books.count))))
                                            .stroke(Color("PixelGreen"), style: StrokeStyle(lineWidth: 4, lineCap: .round))
                                            .frame(width: 50, height: 50)
                                            .rotationEffect(.degrees(-90))
                                        
                                        Image(systemName: "book.closed.fill")
                                            .font(.system(size: 16))
                                            .foregroundColor(Color("PixelGreen"))
                                    }
                                    
                                    Text("完成率")
                                        .font(.pixel(10))
                                        .foregroundColor(Color("PixelBorder").opacity(0.5))
                                }
                            }
                            
                            // Reading Stats Row - Enhanced
                            HStack(spacing: 12) {
                                EnhancedStatBadge(
                                    icon: "book.fill",
                                    count: bookStore.books.filter { $0.status == "reading" }.count,
                                    label: "在读",
                                    color: Color("PixelBlue")
                                )
                                
                                EnhancedStatBadge(
                                    icon: "checkmark.circle.fill",
                                    count: bookStore.books.filter { $0.status == "finished" }.count,
                                    label: "已读",
                                    color: Color("PixelGreen")
                                )
                                
                                EnhancedStatBadge(
                                    icon: "bookmark.fill",
                                    count: bookStore.books.filter { $0.status == "wishlist" || $0.status == "want_to_read" }.count,
                                    label: "想读",
                                    color: Color("PixelAccent")
                                )
                            }
                        }
                        .padding(16)
                        .pixelDialogBorder()
                        .padding(.horizontal, 16)
                        .padding(.top, 16)
                        .padding(.bottom, 20)
                        
                        // MARK: - Bookshelf Layout
                        VStack(spacing: 24) {
                            let totalItems = bookStore.books.count + 1 // +1 for Add Button
                            let rowCount = max(1, Int(ceil(Double(totalItems) / Double(columns))))
                            
                            ForEach(0..<rowCount, id: \.self) { rowIndex in
                                // Books Row
                                HStack(alignment: .bottom, spacing: 16) {
                                    ForEach(0..<columns, id: \.self) { colIndex in
                                        let itemIndex = rowIndex * columns + colIndex
                                        
                                        if itemIndex == 0 {
                                            // First item is always Add Button
                                            Button(action: {
                                                Self.lightHaptic.impactOccurred()
                                                showAddBook = true
                                            }) {
                                                EnhancedAddBookCard()
                                            }
                                            .frame(maxWidth: .infinity)
                                        } else if itemIndex <= bookStore.books.count {
                                            // Real Book
                                            let book = bookStore.books[itemIndex - 1]
                                            NavigationLink(destination: BookDetailView(book: book)) {
                                                EnhancedBookCard(book: book)
                                            }
                                            .frame(maxWidth: .infinity)
                                            .opacity(appearAnimation ? 1 : 0)
                                            .offset(y: appearAnimation ? 0 : 20)
                                            .animation(
                                                .spring(response: 0.5, dampingFraction: 0.7)
                                                    .delay(Double(itemIndex) * 0.08),
                                                value: appearAnimation
                                            )
                                        } else {
                                            Spacer()
                                                .frame(maxWidth: .infinity)
                                        }
                                    }
                                }
                                .padding(.horizontal, 20)
                            }
                        }
                        
                        Spacer(minLength: 60)
                    }
                }
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { dismiss() }) {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.left")
                        Text("back".localized)
                    }
                    .font(.pixel(16))
                    .foregroundColor(Color("PixelBorder"))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color("PixelAccent"))
                    .overlay(
                        Rectangle()
                            .stroke(Color("PixelBorder"), lineWidth: 3)
                    )
                }
            }
        }
        .sheet(isPresented: $showAddBook) {
            AddBookView()
        }
        .toolbar(.hidden, for: .tabBar)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation {
                    appearAnimation = true
                }
            }
        }
    }
}

// MARK: - Enhanced Book Card

struct EnhancedBookCard: View {
    let book: BookEntryData
    @State private var isPressed = false
    
    private var readingStatus: ReadingStatus {
        switch book.status {
        case "reading": return .reading
        case "finished": return .finished
        default: return .wantToRead
        }
    }
    
    private var bookCoverColor: BookCoverColor {
        BookCoverColor(rawValue: book.coverColor) ?? .blue
    }
    
    var body: some View {
        VStack(spacing: 8) {
            // Book Cover with Status Badge
            ZStack(alignment: .topTrailing) {
                BookCoverView(color: bookCoverColor, size: 100)
                    .scaleEffect(isPressed ? 0.95 : 1.0)
                    .animation(.spring(response: 0.2, dampingFraction: 0.6), value: isPressed)
                
                // Status Badge
                if readingStatus == .reading {
                    ZStack {
                        Rectangle()
                            .fill(Color("PixelBlue"))
                            .frame(width: 22, height: 22)
                            .border(Color("PixelBorder"), width: 2)
                        
                        Image(systemName: "book.fill")
                            .font(.system(size: 11))
                            .foregroundColor(.white)
                    }
                    .offset(x: 8, y: -8)
                    .shadow(color: .black.opacity(0.3), radius: 0, x: 2, y: 2)
                }
                
                if readingStatus == .finished {
                    ZStack {
                        Rectangle()
                            .fill(Color("PixelGreen"))
                            .frame(width: 22, height: 22)
                            .border(Color("PixelBorder"), width: 2)
                        
                        Image(systemName: "checkmark")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.white)
                    }
                    .offset(x: 8, y: -8)
                    .shadow(color: .black.opacity(0.3), radius: 0, x: 2, y: 2)
                }
            }
            .background(
                Rectangle()
                    .fill(Color.black.opacity(0.25))
                    .offset(x: 4, y: 4)
            )
            
            // Title area - Enlarged and simplified (removed ratings)
            Text(book.title)
                .font(.pixel(16))
                .foregroundColor(Color("PixelBorder"))
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .frame(width: 90)
                .frame(height: 40, alignment: .top)
        }
        .frame(width: 100)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
    }
}

// MARK: - Enhanced Add Book Card

struct EnhancedAddBookCard: View {
    @State private var isAnimating = false
    @State private var glowOpacity: Double = 0.3
    
    // Match BookCoverView dimensions: size=100 means width=75, height=100
    private let bookWidth: CGFloat = 75
    private let bookHeight: CGFloat = 100
    
    var body: some View {
        VStack(spacing: 8) {
            // Book placeholder - matching BookCoverView structure
            ZStack(alignment: .leading) {
                // Pages effect (right side) - matching BookCoverView
                HStack(spacing: 0) {
                    Spacer()
                    VStack(spacing: 1) {
                        ForEach(0..<6, id: \.self) { _ in
                            Rectangle()
                                .fill(Color(hex: "#F5F0E6").opacity(0.5))
                                .frame(width: 4, height: bookHeight / 7)
                        }
                    }
                    .padding(.vertical, 4)
                    .padding(.trailing, 2)
                }
                .frame(width: bookWidth + 6, height: bookHeight)
                .background(Color(hex: "#E8E0D0").opacity(0.5))
                .overlay(
                    Rectangle()
                        .stroke(style: StrokeStyle(lineWidth: 2, dash: [6, 4]))
                        .foregroundColor(Color("PixelBorder").opacity(0.2))
                )
                .offset(x: 4)
                
                // Main book cover placeholder
                ZStack {
                    RoundedRectangle(cornerRadius: 0)
                        .fill(Color("PixelBg"))
                        .frame(width: bookWidth, height: bookHeight)
                        .overlay(
                            Rectangle()
                                .stroke(style: StrokeStyle(lineWidth: 2.5, dash: [6, 4]))
                                .foregroundColor(Color("PixelGreen").opacity(0.5))
                        )
                    
                    // Plus icon with pulse
                    VStack(spacing: 6) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 28))
                            .foregroundColor(Color("PixelGreen").opacity(0.7))
                            .scaleEffect(isAnimating ? 1.1 : 1.0)
                        
                        Text("添加")
                            .font(.pixel(12))
                            .foregroundColor(Color("PixelGreen").opacity(0.6))
                    }
                }
            }
            .background(
                Rectangle()
                    .fill(Color.black.opacity(0.15))
                    .offset(x: 4, y: 4)
            )
            
            // Label - Enlarged and simplified (removed rating placeholder)
            Text("library_add_book".localized)
                .font(.pixel(16))
                .foregroundColor(Color("PixelBorder").opacity(0.5))
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .frame(width: 90)
                .frame(height: 40, alignment: .top)
        }
        .frame(width: 100)
        .onAppear {
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                isAnimating = true
                glowOpacity = 0.5
            }
        }
    }
}

// MARK: - Enhanced Stat Badge

struct EnhancedStatBadge: View {
    let icon: String
    let count: Int
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            // Icon with count
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundColor(color)
                
                Text("\(count)")
                    .font(.pixel(18))
                    .foregroundColor(Color("PixelBorder"))
            }
            
            Text(label)
                .font(.pixel(12))
                .foregroundColor(Color("PixelBorder").opacity(0.6))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(color.opacity(0.08))
        .overlay(
            Rectangle()
                .stroke(color.opacity(0.25), lineWidth: 2)
        )
    }
}

// MARK: - Pixel Wooden Shelf

struct PixelWoodenShelf: View {
    var body: some View {
        VStack(spacing: 0) {
            // Main shelf surface
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color(hex: "#8B7355"),
                            Color(hex: "#6B5344"),
                            Color(hex: "#5D4636")
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(height: 8)
            
            // Shelf front edge (3D effect)
            Rectangle()
                .fill(Color(hex: "#4A3728"))
                .frame(height: 4)
            
            // Shelf shadow
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color.black.opacity(0.15),
                            Color.clear
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(height: 6)
        }
    }
}

// MARK: - Book Card (Legacy - kept for compatibility)

struct BookCard: View {
    let book: BookEntryData
    
    private var readingStatus: ReadingStatus {
        switch book.status {
        case "reading": return .reading
        case "finished": return .finished
        default: return .wantToRead
        }
    }
    
    // Get book cover color from stored value
    private var bookCoverColor: BookCoverColor {
        BookCoverColor(rawValue: book.coverColor) ?? .blue
    }
    
    var body: some View {
        VStack(spacing: 6) {
            // Book Cover with Hard Shadow
            ZStack(alignment: .bottomTrailing) {
                BookCoverView(color: bookCoverColor, size: 80)
                
                // Status Badge - Pixel Style (icons only)
                if readingStatus == .reading {
                    Image(systemName: "bookmark.fill")
                        .font(.system(size: 14))
                        .foregroundColor(Color("PixelRed"))
                        .offset(x: 2, y: -70)
                        .shadow(color: .black.opacity(0.4), radius: 0, x: 2, y: 2)
                }
                
                if readingStatus == .finished {
                    ZStack {
                        Rectangle()
                            .fill(Color("PixelGreen"))
                            .frame(width: 16, height: 16)
                            .border(Color("PixelBorder"), width: 2)
                        
                        Image(systemName: "checkmark")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white)
                    }
                    .offset(x: 6, y: 6)
                }
            }
            .background(
                Rectangle()
                    .fill(Color.black.opacity(0.25))
                    .offset(x: 4, y: 4)
            )
            
            // Title - bigger font, better alignment
            Text(book.title)
                .font(.pixel(14))
                .foregroundColor(Color("PixelBorder"))
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .frame(width: 80)
                .frame(minHeight: 36, alignment: .top)
            
            // Stars only (no status text)
            if book.rating > 0 {
                HStack(spacing: 1) {
                    ForEach(1...5, id: \.self) { index in
                        Image(systemName: index <= book.rating ? "star.fill" : "star")
                            .font(.system(size: 8))
                            .foregroundColor(index <= book.rating ? Color("PixelAccent") : Color.gray.opacity(0.3))
                    }
                }
            }
        }
        .frame(width: 80)
    }
}

// MARK: - Add Book Card (Legacy - kept for compatibility)

struct AddBookCard: View {
    @State private var isAnimating = false
    
    var body: some View {
        VStack(spacing: 6) {
            // Book silhouette - matching BookCard dimensions
            ZStack {
                // Main book outline
                Rectangle()
                    .fill(Color("PixelBg"))
                    .frame(width: 60, height: 80)
                    .overlay(
                        Rectangle()
                            .stroke(style: StrokeStyle(lineWidth: 2, dash: [4, 3]))
                            .foregroundColor(Color("PixelBorder").opacity(0.3))
                    )
                
                // Plus icon
                Image(systemName: "plus")
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(Color("PixelGreen").opacity(0.6))
                    .scaleEffect(isAnimating ? 1.08 : 1.0)
                    .animation(
                        .easeInOut(duration: 1.2).repeatForever(autoreverses: true),
                        value: isAnimating
                    )
            }
            .background(
                Rectangle()
                    .fill(Color.black.opacity(0.1))
                    .offset(x: 4, y: 4)
            )
            
            // Label - matching BookCard title style
            Text("library_add_book".localized)
                .font(.pixel(14))
                .foregroundColor(Color("PixelBorder").opacity(0.5))
                .frame(width: 80)
                .frame(minHeight: 36, alignment: .top)
        }
        .frame(width: 80)
        .onAppear {
            isAnimating = true
        }
    }
}

// MARK: - Reading Stat Badge (Legacy)

struct ReadingStatBadge: View {
    let icon: String
    let count: Int
    let label: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundColor(color)
            
            Text("\(count)")
                .font(.pixel(14))
                .foregroundColor(Color("PixelBorder"))
            
            Text(label)
                .font(.pixel(10))
                .foregroundColor(Color("PixelBorder").opacity(0.6))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(color.opacity(0.1))
        .overlay(
            Rectangle()
                .stroke(color.opacity(0.3), lineWidth: 2)
        )
    }
}

// MARK: - Wooden Shelf Component (Legacy)

struct WoodenShelf: View {
    var body: some View {
        VStack(spacing: 0) {
            // Main shelf line
            Rectangle()
                .fill(Color("PixelBorder"))
                .frame(height: 4)
            
            // Shelf shadow
            Rectangle()
                .fill(Color("PixelBorder").opacity(0.2))
                .frame(height: 3)
        }
        .padding(.horizontal, 16)
    }
}

// MARK: - Book Cover View

struct BookCoverView: View {
    let color: BookCoverColor
    let size: CGFloat
    
    // Computed gradient colors based on the base color
    private var gradientColors: [Color] {
        let baseColor = Color(hex: color.color)
        return [
            baseColor.opacity(0.9),
            baseColor,
            baseColor.adjustBrightness(by: -0.15)
        ]
    }
    
    var body: some View {
        ZStack(alignment: .leading) {
            // Book pages effect (right side)
            HStack(spacing: 0) {
                Spacer()
                VStack(spacing: 1) {
                    ForEach(0..<6, id: \.self) { _ in
                        Rectangle()
                            .fill(Color(hex: "#F5F0E6"))
                            .frame(width: 4, height: size / 7)
                    }
                }
                .padding(.vertical, 4)
                .padding(.trailing, 2)
            }
            .frame(width: size * 0.75 + 6, height: size)
            .background(Color(hex: "#E8E0D0"))
            .overlay(
                Rectangle()
                    .stroke(Color(hex: "#8B7355"), lineWidth: 2)
            )
            .offset(x: 4)
            
            // Main book cover with gradient
            ZStack {
                // Gradient background
                Rectangle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: gradientColors),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: size * 0.75, height: size)
                
                // Spine highlight (left edge)
                HStack(spacing: 0) {
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    .white.opacity(0.4),
                                    .white.opacity(0.1),
                                    .clear
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: 10)
                    Spacer()
                }
                .frame(width: size * 0.75, height: size)
                
                // Decorative lines (title area simulation)
                VStack(spacing: 6) {
                    Rectangle()
                        .fill(Color.white.opacity(0.3))
                        .frame(width: size * 0.5, height: 3)
                    Rectangle()
                        .fill(Color.white.opacity(0.25))
                        .frame(width: size * 0.35, height: 3)
                    Spacer()
                    
                    // Bottom decoration
                    Rectangle()
                        .fill(Color.black.opacity(0.15))
                        .frame(width: size * 0.4, height: 2)
                }
                .padding(.vertical, 14)
                .frame(width: size * 0.75, height: size)
                
                // Inner shadow at top
                VStack {
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [.black.opacity(0.1), .clear],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(height: 8)
                    Spacer()
                }
                .frame(width: size * 0.75, height: size)
            }
            .frame(width: size * 0.75, height: size)
            .overlay(
                Rectangle()
                    .stroke(Color(hex: "#3D3229"), lineWidth: 3)
            )
        }
    }
}

// MARK: - Color Brightness Extension

extension Color {
    func adjustBrightness(by amount: Double) -> Color {
        // Simple brightness adjustment by blending with black or white
        if amount > 0 {
            return self.opacity(1 - amount)
        } else {
            return self
        }
    }
}

// MARK: - Color Extension

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
