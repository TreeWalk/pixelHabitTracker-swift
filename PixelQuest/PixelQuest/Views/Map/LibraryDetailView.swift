import SwiftUI

struct LibraryDetailView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var bookStore: BookStore
    @EnvironmentObject var localizationManager: LocalizationManager
    let location: Location
    
    @State private var showAddBook = false
    
    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]
    
    var body: some View {
        GeometryReader { geometry in
            let contentWidth = geometry.size.width - 32
            
            ZStack {
                Color("PixelBg").ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Banner
                        if let banner = location.banner {
                            Image(banner)
                                .resizable()
                                .interpolation(.none)
                                .aspectRatio(contentMode: .fill)
                                .frame(width: contentWidth, height: 180)
                                .clipped()
                                .pixelBorderSmall()
                        }
                        
                        // Section Title
                        HStack(spacing: 8) {
                            Image(systemName: "books.vertical.fill")
                                .font(.system(size: 18))
                                .foregroundColor(Color("PixelBlue"))
                            Rectangle()
                                .fill(Color("PixelBlue"))
                                .frame(width: 4, height: 20)
                            Text("library_my_books".localized)
                                .font(.pixel(20))
                                .foregroundColor(Color("PixelBorder"))
                            Spacer()
                            
                            Text(String(format: "library_books_count".localized, bookStore.books.count))
                                .font(.pixel(14))
                                .foregroundColor(Color("PixelBorder").opacity(0.7))
                        }
                        .frame(width: contentWidth, alignment: .leading)
                        
                        // Book Grid
                        LazyVGrid(columns: columns, spacing: 12) {
                            // Add Book Card
                            Button(action: { showAddBook = true }) {
                                AddBookCard()
                            }
                            
                            // Book Cards
                            ForEach(bookStore.books) { book in
                                NavigationLink(destination: BookDetailView(book: book)) {
                                    BookCard(book: book)
                                }
                            }
                        }
                        .frame(width: contentWidth)
                    }
                    .frame(width: geometry.size.width)
                    .padding(.vertical, 16)
                }
            }
        }
        .navigationTitle(location.name)
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
                    .pixelBorderSmall()
                }
            }
        }
        .sheet(isPresented: $showAddBook) {
            AddBookView()
        }
        .onAppear {
            Task {
                await bookStore.fetchBooks()
            }
        }
    }
}

// MARK: - Book Card

struct BookCard: View {
    let book: BookEntry
    
    var body: some View {
        VStack(spacing: 8) {
            // Book Cover
            BookCoverView(color: book.coverColor, size: 80)
            
            // Title
            Text(book.title)
                .font(.pixel(14))
                .foregroundColor(Color("PixelBorder"))
                .lineLimit(2)
                .multilineTextAlignment(.center)
            
            // Rating
            if book.rating > 0 {
                HStack(spacing: 2) {
                    ForEach(1...5, id: \.self) { index in
                        Image(systemName: index <= book.rating ? "star.fill" : "star")
                            .font(.system(size: 10))
                            .foregroundColor(index <= book.rating ? Color("PixelAccent") : Color.gray.opacity(0.3))
                    }
                }
            }
            
            // Status
            HStack(spacing: 4) {
                Image(systemName: book.status.icon)
                    .font(.system(size: 10))
                Text(book.status.rawValue)
                    .font(.pixel(10))
            }
            .foregroundColor(Color(book.status.color))
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color.white)
        .pixelBorderSmall()
    }
}

// MARK: - Add Book Card

struct AddBookCard: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "plus.circle.fill")
                .font(.system(size: 40))
                .foregroundColor(Color("PixelBlue"))
            
            Text("library_add_book".localized)
                .font(.pixel(14))
                .foregroundColor(Color("PixelBorder"))
        }
        .padding()
        .frame(maxWidth: .infinity)
        .frame(minHeight: 160)
        .background(Color.white.opacity(0.5))
        .pixelBorderSmall(color: Color("PixelBlue").opacity(0.5))
    }
}

// MARK: - Book Cover View

struct BookCoverView: View {
    let color: BookCoverColor
    let size: CGFloat
    
    var body: some View {
        ZStack {
            // Book shape
            RoundedRectangle(cornerRadius: 4)
                .fill(Color(hex: color.color))
                .frame(width: size * 0.7, height: size)
            
            // Spine decoration
            Rectangle()
                .fill(Color.white.opacity(0.2))
                .frame(width: 4, height: size - 8)
                .offset(x: -size * 0.25)
            
            // Book title placeholder lines
            VStack(spacing: 4) {
                Rectangle()
                    .fill(Color.white.opacity(0.3))
                    .frame(width: size * 0.4, height: 3)
                Rectangle()
                    .fill(Color.white.opacity(0.3))
                    .frame(width: size * 0.3, height: 3)
            }
        }
        .shadow(color: Color.black.opacity(0.1), radius: 2, x: 2, y: 2)
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
