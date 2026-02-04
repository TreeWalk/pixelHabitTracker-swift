import SwiftUI

// MARK: - HD Remastered Pixel Design System
// A warm, cozy design system blending pixel art with modern iOS fluidity
// Think "Stardew Valley UI" - smooth rounded corners, warm colors, pixel fonts

// MARK: - Pixel Design Tokens

/// Animation presets for pixel-style interactions
enum PixelAnimation {
    static let standard = Animation.spring(response: 0.3, dampingFraction: 0.7)
    static let quick = Animation.spring(response: 0.2, dampingFraction: 0.8)
}

/// Spacing scale for consistent layout
enum PixelSpacing {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 12
    static let lg: CGFloat = 16
    static let xl: CGFloat = 24
}

/// Corner radius presets - updated to 0 for square corners
enum PixelCornerRadius {
    static let none: CGFloat = 0
    static let sm: CGFloat = 0
    static let md: CGFloat = 0
    static let lg: CGFloat = 0
}

/// Border width presets
enum PixelBorder {
    static let thin: CGFloat = 2
    static let standard: CGFloat = 3
    static let thick: CGFloat = 4
}

/// Shadow offset for pixel-style hard shadows
enum PixelShadow {
    static let offset: CGFloat = 4
    static let small: CGFloat = 3
    static let large: CGFloat = 6
}

/// Shadow style presets
enum PixelShadowStyle {
    case hard      // 硬像素阴影 - 纯色偏移，无模糊
    case soft      // 软阴影 - 轻微模糊，用于浮层
    case none      // 无阴影
}

// MARK: - Color Extensions

extension Color {
    /// Dark Coffee - The primary warm dark brown for all borders/strokes
    /// Now references PixelBorder asset for consistency
    static let darkCoffee = Color("PixelBorder")

    /// Light Coffee - For unselected/secondary elements
    static let lightCoffee = Color("PixelBorder").opacity(0.6)

    /// Cream Background - Warm off-white
    /// Now references PixelBg asset for consistency
    static let creamBg = Color("PixelBg")

    /// Warm butter - for highlight cards
    static let warmButter = Color("PixelButter")

    /// Soft peach - for subscription cards
    static let softPeach = Color("PixelPeach")

    /// Soft mint - for recovery cards
    static let softMint = Color("PixelMint")
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
        cornerRadius: CGFloat = 0,
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
                Rectangle()
                    .fill(backgroundColor)
            )
            .clipShape(Rectangle())
            .overlay(
                Rectangle()
                    .stroke(borderColor, lineWidth: borderWidth)
            )
            // Hard pixel shadow - offset without blur
            .background(
                Rectangle()
                    .fill(shadowColor)
                    .offset(x: shadowOffset, y: shadowOffset)
            )
    }
}

extension View {
    /// Applies a cozy card style with warm colors and smooth corners
    func cozyCard(
        backgroundColor: Color = .white,
        borderColor: Color = .darkCoffee,
        borderWidth: CGFloat = 3,
        cornerRadius: CGFloat = 0,
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
        cornerRadius: CGFloat = 0
    ) -> some View {
        self
            .clipShape(Rectangle())
            .overlay(
                Rectangle()
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
        cornerRadius: CGFloat = 0
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
                Rectangle()
                    .fill(index < filledBlocks ? filledColor : emptyColor)
            }
        }
        .frame(height: height)
        .padding(3)
        .background(Color.white)
        .clipShape(Rectangle())
        .overlay(
            Rectangle()
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
    var cornerRadius: CGFloat = 0
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
                Rectangle()
                    .fill(isChecked ? checkedColor : .white)
                    .frame(width: size, height: size)
                
                if isChecked {
                    Image(systemName: "checkmark")
                        .font(.system(size: size * 0.5, weight: .bold))
                        .foregroundColor(.white)
                }
            }
            .overlay(
                Rectangle()
                    .stroke(borderColor, lineWidth: 2.5)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Pixel Component Aliases (for semantic naming)
typealias PixelProgressBar = CozyProgressBar
typealias PixelCheckbox = CozyCheckbox

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
        HStack(spacing: 6) {
            ForEach(0..<tabs.count, id: \.self) { index in
                Button(action: {
                    Self.hapticGenerator.impactOccurred()
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedTab = index
                    }
                }) {
                    VStack(spacing: 6) {
                        Image(systemName: tabs[index].icon)
                            .font(.system(size: 21, weight: selectedTab == index ? .semibold : .regular))
                        
                        Text(tabs[index].label)
                            .font(.pixel(11))
                    }
                    .foregroundColor(selectedTab == index ? .darkCoffee : .lightCoffee)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        // Selected indicator - pixel style square
                        Group {
                            if selectedTab == index {
                                Rectangle()
                                    .fill(Color("PixelButter").opacity(0.8))
                            }
                        }
                    )
                }
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(Color.creamBg)
        .clipShape(Rectangle())
        .overlay(
            Rectangle()
                .stroke(Color.darkCoffee, lineWidth: 3)
        )
        // Hard pixel shadow
        .background(
            Rectangle()
                .fill(Color.darkCoffee.opacity(0.3))
                .offset(x: 4, y: 4)
        )
        .padding(.horizontal, 16)
    }
}

// MARK: - Subtle Noise Texture

struct SubtleNoiseOverlay: View {
    var opacity: Double = 0.02
    var useCheckerboard: Bool = false  // 棋盘格模式更像素化
    
    var body: some View {
        Canvas { context, size in
            if useCheckerboard {
                // 棋盘格抖动 - 更像素化的效果
                for y in stride(from: 0, to: size.height, by: 4) {
                    for x in stride(from: 0, to: size.width, by: 4) {
                        if (Int(x) + Int(y)) % 8 == 0 {
                            let rect = CGRect(x: x, y: y, width: 2, height: 2)
                            context.fill(Path(rect), with: .color(.black.opacity(opacity)))
                        }
                    }
                }
            } else {
                // 随机噪点模式
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
        }
        .allowsHitTesting(false)
    }
}

// View modifiers moved to Font+Pixel.swift for global visibility


// MARK: - Retro Stat Panel (Unified RPG Style)

struct RetroStatItem {
    let icon: String
    let value: String
    let label: String
    let color: Color
}

struct RetroReportPanel<Content: View>: View {
    let title: String
    let icon: String
    let accentColor: Color
    let content: Content
    
    init(title: String, icon: String, accentColor: Color, @ViewBuilder content: () -> Content) {
        self.title = title
        self.icon = icon
        self.accentColor = accentColor
        self.content = content()
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Panel Header
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundColor(accentColor)
                
                Text(title.uppercased())
                    .font(.pixel(16))
                    .foregroundColor(Color("PixelBorder"))
                
                Spacer()
                
                // Decorative dots
                HStack(spacing: 4) {
                    ForEach(0..<3, id: \.self) { _ in
                        Rectangle()
                            .fill(accentColor.opacity(0.3))
                            .frame(width: 4, height: 4)
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(accentColor.opacity(0.1))
            .overlay(
                Rectangle()
                    .stroke(Color("PixelBorder"), lineWidth: 2),
                alignment: .bottom
            )
            
            // Content
            content
                .padding(16)
                .background(Color.white)
        }
        .overlay(
            Rectangle()
                .stroke(Color("PixelBorder"), lineWidth: 2)
        )
        // Hard Shadow
        .background(
            Rectangle()
                .fill(Color("PixelBorder").opacity(0.15))
                .offset(x: 4, y: 4)
        )
    }
}

struct RetroStatPanel: View {
    let title: String
    let items: [RetroStatItem]
    let accentColor: Color
    
    var body: some View {
        RetroReportPanel(title: title, icon: "chart.bar.fill", accentColor: accentColor) {
            HStack(spacing: 0) {
                ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                    VStack(spacing: 6) {
                        Image(systemName: item.icon)
                            .font(.system(size: 20))
                            .foregroundColor(item.color)
                        
                        Text(item.value)
                            .font(.pixel(22))
                            .foregroundColor(item.color)
                        
                        Text(item.label)
                            .font(.pixel(12))
                            .foregroundColor(Color("PixelBorder").opacity(0.7))
                    }
                    .frame(maxWidth: .infinity)
                    
                    if index < items.count - 1 {
                        Rectangle()
                            .fill(Color("PixelBorder").opacity(0.1))
                            .frame(width: 2)
                            .padding(.vertical, 8)
                    }
                }
            }
            .padding(-16) // Neutralize the padding from RetroReportPanel for stat items
        }
    }
}


// MARK: - Pixel Ring Progress (圆环进度指示器)

struct PixelRingProgress: View {
    let progress: Double // 0.0 to 1.0
    let icon: String
    let accentColor: Color
    var size: CGFloat = 60
    var lineWidth: CGFloat = 6
    var segments: Int = 16 // Number of segments in the ring
    
    var body: some View {
        ZStack {
            // Background ring (unfilled segments)
            ForEach(0..<segments, id: \.self) { index in
                PixelRingSegment(
                    index: index,
                    total: segments,
                    isFilled: false,
                    color: accentColor.opacity(0.15),
                    lineWidth: lineWidth
                )
            }
            
            // Foreground ring (filled segments)
            let filledCount = Int(progress * Double(segments))
            ForEach(0..<filledCount, id: \.self) { index in
                PixelRingSegment(
                    index: index,
                    total: segments,
                    isFilled: true,
                    color: accentColor,
                    lineWidth: lineWidth
                )
            }
            
            // Center icon
            Image(systemName: icon)
                .font(.system(size: size * 0.35, weight: .bold))
                .foregroundColor(accentColor)
        }
        .frame(width: size, height: size)
    }
}

struct PixelRingSegment: View {
    let index: Int
    let total: Int
    let isFilled: Bool
    let color: Color
    let lineWidth: CGFloat
    
    var body: some View {
        let startAngle = Angle(degrees: Double(index) / Double(total) * 360 - 90)
        let endAngle = Angle(degrees: Double(index + 1) / Double(total) * 360 - 90 - 2) // Gap between segments
        
        Path { path in
            path.addArc(
                center: CGPoint(x: lineWidth * 5, y: lineWidth * 5),
                radius: lineWidth * 4,
                startAngle: startAngle,
                endAngle: endAngle,
                clockwise: false
            )
        }
        .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .butt))
        .frame(width: lineWidth * 10, height: lineWidth * 10)
    }
}


// MARK: - Pixel Heatmap (热力图)

struct PixelHeatmapData: Identifiable {
    let id = UUID()
    let date: Date
    let value: Double // 0.0 to 1.0 intensity
}

struct PixelHeatmap: View {
    let data: [PixelHeatmapData]
    let accentColor: Color
    var columns: Int = 7 // Days per row (week)
    var rows: Int = 5 // Weeks to show
    var cellSize: CGFloat = 12
    var spacing: CGFloat = 3
    
    var body: some View {
        VStack(alignment: .trailing, spacing: spacing) {
            ForEach(0..<rows, id: \.self) { row in
                HStack(spacing: spacing) {
                    ForEach(0..<columns, id: \.self) { col in
                        let index = row * columns + col
                        let intensity = index < data.count ? data[index].value : 0
                        
                        Rectangle()
                            .fill(cellColor(for: intensity))
                            .frame(width: cellSize, height: cellSize)
                            .overlay(
                                Rectangle()
                                    .stroke(Color("PixelBorder").opacity(0.1), lineWidth: 1)
                            )
                    }
                }
            }
        }
    }
    
    private func cellColor(for intensity: Double) -> Color {
        if intensity <= 0 {
            return Color("PixelBorder").opacity(0.05)
        } else if intensity < 0.25 {
            return accentColor.opacity(0.2)
        } else if intensity < 0.5 {
            return accentColor.opacity(0.4)
        } else if intensity < 0.75 {
            return accentColor.opacity(0.7)
        } else {
            return accentColor
        }
    }
}


// MARK: - Retro Bar Chart

struct RetroChartData: Identifiable {
    let id = UUID()
    let label: String
    let value: Double
    let color: Color
    let isToday: Bool
}

struct RetroBarChart: View {
    let data: [RetroChartData]
    let maxValue: Double
    let accentColor: Color
    
    var body: some View {
        HStack(alignment: .bottom, spacing: 12) {
            // Y-Axis Labels
            VStack(alignment: .trailing, spacing: 0) {
                let labels = [12, 8, 4]
                ForEach(labels, id: \.self) { label in
                    Text("\(label)h")
                        .font(.pixel(10))
                        .foregroundColor(Color("PixelBorder").opacity(0.4))
                        .frame(height: 100 / (maxValue / Double(label)), alignment: .bottom)
                    if label != 4 { Spacer() }
                }
            }
            .frame(height: 100)
            .padding(.bottom, 20) // Align with bars, excluding labels
            
            ZStack {
                // Background Dot Grid
                VStack(spacing: 24) {
                    ForEach(0..<5) { _ in
                        HStack(spacing: 24) {
                            ForEach(0..<8) { _ in
                                Circle()
                                    .fill(Color("PixelBorder").opacity(0.05))
                                    .frame(width: 2, height: 2)
                            }
                        }
                    }
                }
                
                // Horizontal Guide Lines
                VStack(spacing: 0) {
                    ForEach(0..<3) { _ in
                        Spacer()
                        Divider()
                            .background(Color("PixelBorder").opacity(0.1))
                    }
                }
                .frame(height: 100)
                .padding(.bottom, 20)
                
                HStack(alignment: .bottom, spacing: 12) {
                    ForEach(data) { item in
                        VStack(spacing: 8) {
                            // Segmented Bar
                            GeometryReader { geometry in
                                VStack(spacing: 2) {
                                    Spacer(minLength: 0)
                                    
                                    let barHeight = maxValue > 0 ? (item.value / maxValue) * geometry.size.height : 0
                                    let segmentCount = Int(barHeight / 6)
                                    
                                    ForEach(0..<max(0, segmentCount), id: \.self) { i in
                                        Rectangle()
                                            .fill(item.value > 0 ? item.color : Color("PixelBorder").opacity(0.1))
                                            .frame(height: 4)
                                            .overlay(
                                                Rectangle()
                                                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                            )
                                    }
                                    
                                    if segmentCount == 0 && item.value > 0 {
                                        Rectangle()
                                            .fill(item.color)
                                            .frame(height: 2)
                                    }
                                }
                            }
                            .frame(height: 100)
                            
                            // Label
                            Text(item.label)
                                .font(.pixel(12))
                                .foregroundColor(item.isToday ? accentColor : Color("PixelBorder").opacity(0.6))
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
            }
            .padding(16)
            .background(
                ZStack {
                    Color.white
                    // Dithered-style accent background
                    accentColor.opacity(0.03)
                    
                    // Subtle diagonal stripe pattern
                    GeometryReader { geo in
                        Path { path in
                            let step: CGFloat = 10
                            for x in stride(from: 0, through: geo.size.width + geo.size.height, by: step) {
                                path.move(to: CGPoint(x: x, y: 0))
                                path.addLine(to: CGPoint(x: x - geo.size.height, y: geo.size.height))
                            }
                        }
                        .stroke(accentColor.opacity(0.02), lineWidth: 1)
                    }
                }
            )
            .overlay(
                Rectangle()
                    .stroke(Color("PixelBorder"), lineWidth: 2)
            )
        }
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
