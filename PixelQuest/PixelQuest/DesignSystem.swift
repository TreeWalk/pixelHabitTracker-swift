import SwiftUI

// MARK: - HD Remastered Pixel Design System
// A warm, cozy design system blending pixel art with modern iOS fluidity
// Think "Stardew Valley UI" - smooth rounded corners, warm colors, pixel fonts

// MARK: - Color Extensions

extension Color {
    /// Dark Coffee - The primary warm dark brown for all borders/strokes
    static let darkCoffee = Color(red: 0.29, green: 0.23, blue: 0.20) // #4A3B32
    
    /// Light Coffee - For unselected/secondary elements
    static let lightCoffee = Color(red: 0.55, green: 0.45, blue: 0.38)
    
    /// Cream Background - Warm off-white
    static let creamBg = Color(red: 0.98, green: 0.96, blue: 0.93)
}

// MARK: - Typography (Hybrid Strategy)

extension Font {
    /// Pixel Header - VT323 for titles, stats, buttons
    static func pixelHeader(_ size: CGFloat) -> Font {
        .custom("VT323", size: size)
    }
    
    /// Modern Body - Rounded system font for user content (readability)
    static func modernBody(_ size: CGFloat = 16) -> Font {
        .system(size: size, design: .rounded)
    }
    
    /// Modern Body with weight
    static func modernBody(_ size: CGFloat = 16, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }
}

// MARK: - Cozy Border Modifier (Smooth Rounded)

struct CozyBorderModifier: ViewModifier {
    var backgroundColor: Color
    var borderColor: Color
    var borderWidth: CGFloat
    var cornerRadius: CGFloat
    var shadowColor: Color
    var shadowOffset: CGFloat
    
    init(
        backgroundColor: Color = .white,
        borderColor: Color = .darkCoffee,
        borderWidth: CGFloat = 3,
        cornerRadius: CGFloat = 12,
        shadowColor: Color = .darkCoffee.opacity(0.25),
        shadowOffset: CGFloat = 4
    ) {
        self.backgroundColor = backgroundColor
        self.borderColor = borderColor
        self.borderWidth = borderWidth
        self.cornerRadius = cornerRadius
        self.shadowColor = shadowColor
        self.shadowOffset = shadowOffset
    }
    
    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(backgroundColor)
            )
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(borderColor, lineWidth: borderWidth)
            )
            // Soft blur shadow instead of solid offset
            .shadow(color: shadowColor, radius: 8, x: 0, y: 4)
    }
}

extension View {
    /// Applies a cozy card style with warm colors and smooth corners
    func cozyCard(
        backgroundColor: Color = .white,
        borderColor: Color = .darkCoffee,
        borderWidth: CGFloat = 3,
        cornerRadius: CGFloat = 12,
        shadowColor: Color = .darkCoffee.opacity(0.2),
        shadowOffset: CGFloat = 4
    ) -> some View {
        self.modifier(CozyBorderModifier(
            backgroundColor: backgroundColor,
            borderColor: borderColor,
            borderWidth: borderWidth,
            cornerRadius: cornerRadius,
            shadowColor: shadowColor,
            shadowOffset: shadowOffset
        ))
    }
    
    /// Simple cozy border without shadow
    func cozyBorder(
        color: Color = .darkCoffee,
        lineWidth: CGFloat = 3,
        cornerRadius: CGFloat = 12
    ) -> some View {
        self
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(color, lineWidth: lineWidth)
            )
    }
}

// MARK: - Cozy Progress Bar (Block/Cell Style)

struct CozyProgressBar: View {
    var value: Double
    var maxValue: Double
    var totalBlocks: Int
    var filledColor: Color
    var emptyColor: Color
    var borderColor: Color
    var blockSpacing: CGFloat
    var height: CGFloat
    var cornerRadius: CGFloat
    
    init(
        value: Double,
        maxValue: Double = 100,
        totalBlocks: Int = 10,
        filledColor: Color = Color("PixelAccent"),
        emptyColor: Color = Color.gray.opacity(0.2),
        borderColor: Color = .darkCoffee,
        blockSpacing: CGFloat = 2,
        height: CGFloat = 14,
        cornerRadius: CGFloat = 4
    ) {
        self.value = value
        self.maxValue = maxValue
        self.totalBlocks = totalBlocks
        self.filledColor = filledColor
        self.emptyColor = emptyColor
        self.borderColor = borderColor
        self.blockSpacing = blockSpacing
        self.height = height
        self.cornerRadius = cornerRadius
    }
    
    private var filledBlocks: Int {
        let percentage = min(1, max(0, value / maxValue))
        return Int(round(percentage * Double(totalBlocks)))
    }
    
    var body: some View {
        HStack(spacing: blockSpacing) {
            ForEach(0..<totalBlocks, id: \.self) { index in
                RoundedRectangle(cornerRadius: 2, style: .continuous)
                    .fill(index < filledBlocks ? filledColor : emptyColor)
            }
        }
        .frame(height: height)
        .padding(3)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .stroke(borderColor, lineWidth: 2)
        )
    }
}

// MARK: - Cozy Checkbox

struct CozyCheckbox: View {
    @Binding var isChecked: Bool
    var size: CGFloat = 26
    var checkedColor: Color = Color("PixelAccent")
    var borderColor: Color = .darkCoffee
    var cornerRadius: CGFloat = 6
    var onToggle: (() -> Void)? = nil
    
    // Static haptic generator
    private static let hapticGenerator: UIImpactFeedbackGenerator = {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.prepare()
        return generator
    }()
    
    var body: some View {
        Button(action: {
            Self.hapticGenerator.impactOccurred()
            isChecked.toggle()
            onToggle?()
        }) {
            ZStack {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(isChecked ? checkedColor : .white)
                    .frame(width: size, height: size)
                
                if isChecked {
                    Image(systemName: "checkmark")
                        .font(.system(size: size * 0.5, weight: .bold))
                        .foregroundColor(.white)
                }
            }
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(borderColor, lineWidth: 2.5)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Custom Floating Tab Bar

struct FloatingTabBar: View {
    @Binding var selectedTab: Int
    
    private let tabs: [(icon: String, label: String)] = [
        ("person.crop.circle", "Dashboard"),
        ("scroll.fill", "Actions"),
        ("shippingbox.fill", "Assets"),
        ("map.fill", "World")
    ]
    
    // Static haptic generator
    private static let hapticGenerator: UIImpactFeedbackGenerator = {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.prepare()
        return generator
    }()
    
    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<tabs.count, id: \.self) { index in
                Button(action: {
                    Self.hapticGenerator.impactOccurred()
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedTab = index
                    }
                }) {
                    VStack(spacing: 4) {
                        Image(systemName: tabs[index].icon)
                            .font(.system(size: 20, weight: selectedTab == index ? .semibold : .regular))
                        
                        Text(tabs[index].label)
                            .font(.pixel(10))
                    }
                    .foregroundColor(selectedTab == index ? .darkCoffee : .lightCoffee)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(
                        // Selected indicator
                        Group {
                            if selectedTab == index {
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(Color.darkCoffee.opacity(0.12))
                            }
                        }
                    )
                }
            }
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 4)
        .background(Color.creamBg)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.darkCoffee, lineWidth: 3)
        )
        // Soft blur shadow
        .shadow(color: Color.darkCoffee.opacity(0.2), radius: 10, x: 0, y: 4)
        .padding(.horizontal, 16)
    }
}

// MARK: - Subtle Noise Texture

struct SubtleNoiseOverlay: View {
    var opacity: Double = 0.02
    
    var body: some View {
        Canvas { context, size in
            for y in stride(from: 0, to: size.height, by: 3) {
                for x in stride(from: 0, to: size.width, by: 3) {
                    let noise = (sin(x * 12.9898 + y * 78.233) * 43758.5453).truncatingRemainder(dividingBy: 1)
                    if noise > 0.6 {
                        let rect = CGRect(x: x, y: y, width: 2, height: 2)
                        context.fill(Path(rect), with: .color(.black.opacity(opacity)))
                    }
                }
            }
        }
        .allowsHitTesting(false)
    }
}

// MARK: - Previews

#Preview("CozyProgressBar") {
    VStack(spacing: 20) {
        CozyProgressBar(value: 75, maxValue: 100, filledColor: Color("PixelRed"))
        CozyProgressBar(value: 50, maxValue: 100, filledColor: Color("PixelGreen"))
        CozyProgressBar(value: 30, maxValue: 100, filledColor: Color("PixelBlue"))
    }
    .padding()
    .background(Color.creamBg)
}

#Preview("CozyCard") {
    VStack {
        Text("Cozy Card Style")
            .font(.pixelHeader(20))
            .padding()
            .cozyCard()
    }
    .padding()
    .background(Color.creamBg)
}

#Preview("FloatingTabBar") {
    struct TabBarPreview: View {
        @State private var selected = 0
        var body: some View {
            VStack {
                Spacer()
                FloatingTabBar(selectedTab: $selected)
            }
            .background(Color.creamBg)
        }
    }
    return TabBarPreview()
}
