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

// MARK: - Five Element Card (Enhanced Pixel Style)
struct FiveElementCard: View {
    let element: ElementType
    let title: String
    let value: Double
    let maxValue: Double
    let label: String
    var onDetailTap: (() -> Void)? = nil
    
    @State private var isExpanded: Bool = false
    @State private var isPressed: Bool = false
    @State private var isGlowing: Bool = false
    @State private var showParticles: Bool = false
    @State private var previousValue: Double = 0
    
    // Static haptic generators
    private static let lightHaptic: UIImpactFeedbackGenerator = {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.prepare()
        return generator
    }()
    
    private static let mediumHaptic: UIImpactFeedbackGenerator = {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.prepare()
        return generator
    }()
    
    private var progress: Double {
        min(1, max(0, value / maxValue))
    }
    
    var body: some View {
        ZStack {
            // Main card content
            VStack(alignment: .leading, spacing: 12) {
                // Header
                HStack(alignment: .center, spacing: 12) {
                    // Pixel icon with scale animation
                    Image(element.pixelIcon)
                        .resizable()
                        .interpolation(.none)
                        .scaledToFit()
                        .frame(width: 36, height: 36)
                        .scaleEffect(isPressed ? 0.9 : 1.0)
                        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
                    
                    // Content
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text(title)
                                .font(.pixel(18))
                                .foregroundColor(Color("PixelBorder"))
                            
                            Spacer()
                            
                            Text(label)
                                .font(.pixel(12))
                                .foregroundStyle(Color("PixelBorder").opacity(0.7))
                        }
                        
                        // Animated progress bar
                        AnimatedProgressFill(
                            progress: progress,
                            maxBlocks: 10,
                            blockColor: element.color,
                            emptyColor: element.color.opacity(0.15)
                        )
                        .frame(height: 14)
                        .padding(3)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 4, style: .continuous)
                                .stroke(Color.darkCoffee.opacity(0.5), lineWidth: 2)
                        )
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                        isExpanded.toggle()
                    }
                    Self.lightHaptic.impactOccurred()
                }
                .onLongPressGesture(minimumDuration: 0.3, pressing: { pressing in
                    withAnimation(.spring(response: 0.2, dampingFraction: 0.7)) {
                        isPressed = pressing
                        if pressing {
                            Self.mediumHaptic.impactOccurred()
                        }
                    }
                }) {
                    // Long press completed - toggle glow
                    withAnimation(.easeInOut(duration: 0.3)) {
                        isGlowing.toggle()
                    }
                }
                
                // Expanded content
                if isExpanded {
                    VStack(alignment: .leading, spacing: 8) {
                        Rectangle()
                            .fill(Color.darkCoffee.opacity(0.15))
                            .frame(height: 2)
                        
                        Button(action: {
                            Self.lightHaptic.impactOccurred()
                            onDetailTap?()
                        }) {
                            HStack {
                                Text("recent_records".localized)
                                    .font(.pixel(12))
                                    .foregroundColor(Color.darkCoffee.opacity(0.7))
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundColor(Color.darkCoffee.opacity(0.5))
                            }
                        }
                        .disabled(onDetailTap == nil)
                    }
                    .transition(.opacity.combined(with: .move(edge: .top)))
                    .padding(.top, 4)
                }
            }
            .padding()
            .pixelDoubleBorder(
                outerColor: .darkCoffee,
                innerColor: element.color.opacity(0.3),
                outerWidth: 3,
                innerWidth: 2,
                innerPadding: 4
            )
            .background(Color.white)
            .pixelHardShadow(color: Color.darkCoffee.opacity(0.25), offset: 5)
            .pixelGlow(color: element.color, isActive: isGlowing, intensity: 0.6)
            .scaleEffect(isPressed ? 0.98 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isPressed)
            
            // Particle effect overlay (when progress reaches max)
            if showParticles {
                GeometryReader { geometry in
                    PixelParticleEmitter(
                        preset: .sparkle,
                        origin: CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2),
                        isEmitting: showParticles
                    )
                }
                .allowsHitTesting(false)
            }
        }
        .onChange(of: value) { oldValue, newValue in
            // Trigger particle effect when reaching max
            if newValue >= maxValue && oldValue < maxValue {
                showParticles = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    showParticles = false
                }
            }
            previousValue = oldValue
        }
    }
}

#Preview {
    VStack(spacing: 12) {
        FiveElementCard(element: .fire, title: "Strength", value: 75, maxValue: 100, label: "120 min")
        FiveElementCard(element: .wood, title: "Intellect", value: 45, maxValue: 100, label: "3 本在读")
        FiveElementCard(element: .water, title: "Health", value: 100, maxValue: 100, label: "VIT 100")
    }
    .padding()
    .background(Color("PixelBg"))
}
