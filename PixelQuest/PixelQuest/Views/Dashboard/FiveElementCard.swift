import SwiftUI

// MARK: - Element Type
enum ElementType: String, CaseIterable {
    case fire, wood, water, metal, earth
    
    var name: String {
        switch self {
        case .fire: return "🔥"
        case .wood: return "📚"
        case .water: return "💧"
        case .metal: return "💰"
        case .earth: return "⚡"
        }
    }
    
    var icon: String {
        switch self {
        case .fire: return "flame.fill"
        case .wood: return "book.fill"
        case .water: return "drop.fill"
        case .metal: return "yensign.circle.fill"
        case .earth: return "bolt.fill"
        }
    }
    
    var pixelIcon: String {
        switch self {
        case .fire: return "pixel_strength"
        case .wood: return "pixel_book"
        case .water: return "pixel_sleep"
        case .metal: return "pixel_money"
        case .earth: return "pixel_todo"
        }
    }
    
    var color: Color {
        switch self {
        case .fire: return Color("PixelRed")
        case .wood: return Color("PixelGreen")
        case .water: return Color("PixelBlue")
        case .metal: return Color("PixelAccent")
        case .earth: return Color("PixelWood")
        }
    }
}

// MARK: - Five Element Card (Pixel Style)
struct FiveElementCard: View {
    let element: ElementType
    let title: String
    let value: Double
    let maxValue: Double
    let label: String
    var onDetailTap: (() -> Void)? = nil
    
    @State private var isExpanded: Bool = false
    
    // Static haptic generator
    private static let hapticGenerator: UIImpactFeedbackGenerator = {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.prepare()
        return generator
    }()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack(alignment: .center, spacing: 12) {
                // Pixel icon - no background container
                Image(element.pixelIcon)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 36, height: 36)
                
                // Content
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(element.name)
                            .font(.pixel(20))
                            .foregroundColor(element.color)
                        
                        Text(title)
                            .font(.pixel(14))
                            .foregroundColor(Color("PixelBorder"))
                        
                        Spacer()
                        
                        Text(label)
                            .font(.pixel(12))
                            .foregroundStyle(Color("PixelBorder").opacity(0.7))
                    }
                    
                    // Pixel progress bar (square edges)
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Rectangle()
                                .fill(element.color.opacity(0.2))
                            
                            Rectangle()
                                .fill(element.color)
                                .frame(width: max(0, geo.size.width * min(1, value / max(1, maxValue))))
                        }
                        .overlay(
                            Rectangle()
                                .stroke(element.color.opacity(0.5), lineWidth: 2)
                        )
                    }
                    .frame(height: 10)
                }
            }
            .contentShape(Rectangle())
            .onTapGesture {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                    isExpanded.toggle()
                }
                Self.hapticGenerator.impactOccurred()
            }
            
            // Expanded content
            if isExpanded {
                VStack(alignment: .leading, spacing: 8) {
                    Rectangle()
                        .fill(Color("PixelBorder").opacity(0.2))
                        .frame(height: 2)
                    
                    Button(action: {
                        onDetailTap?()
                    }) {
                        HStack {
                            Text("recent_records".localized)
                                .font(.pixel(12))
                                .foregroundColor(Color("PixelBorder").opacity(0.7))
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(Color("PixelBorder").opacity(0.5))
                        }
                    }
                    .disabled(onDetailTap == nil)
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
                .padding(.top, 4)
            }
        }
        .padding()
        .background(Color.white)
        .overlay(
            Rectangle()
                .stroke(Color("PixelBorder"), lineWidth: 3)
        )
    }
}

#Preview {
    VStack(spacing: 12) {
        FiveElementCard(element: .fire, title: "Strength", value: 75, maxValue: 100, label: "120 min")
        FiveElementCard(element: .wood, title: "Intellect", value: 45, maxValue: 100, label: "3 本在读")
        FiveElementCard(element: .water, title: "Health", value: 60, maxValue: 100, label: "VIT 60")
    }
    .padding()
    .background(Color("PixelBg"))
}
