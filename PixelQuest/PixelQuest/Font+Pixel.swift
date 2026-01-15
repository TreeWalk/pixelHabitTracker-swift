import SwiftUI

extension Font {
    /// Pixel art style font - VT323
    /// Use this for all text to maintain the retro pixel aesthetic
    static func pixel(_ size: CGFloat) -> Font {
        // Many pixel fonts use the family name as the PostScript name
        .custom("VT323", size: size)
    }
    
    /// Pixel font with relative sizing for dynamic type support
    static func pixel(_ style: TextStyle) -> Font {
        .custom("VT323", size: pixelSize(for: style), relativeTo: style)
    }
    
    private static func pixelSize(for style: TextStyle) -> CGFloat {
        switch style {
        case .largeTitle: return 40
        case .title: return 32
        case .title2: return 28
        case .title3: return 24
        case .headline: return 20
        case .body: return 18
        case .callout: return 16
        case .subheadline: return 14
        case .footnote: return 12
        case .caption: return 11
        case .caption2: return 10
        @unknown default: return 18
        }
    }
}

// MARK: - Pixel Style Modifiers

extension View {
    /// Applies subtle text shadow for depth (reduced to avoid double-image effect)
    func pixelTextShadow(color: Color = Color("PixelBorder"), radius: CGFloat = 0, x: CGFloat = 1, y: CGFloat = 1) -> some View {
        self.shadow(color: color.opacity(0.15), radius: radius, x: x, y: y)
    }
    
    /// Applies pixel-style border
    func pixelBorder(color: Color = Color("PixelBorder"), lineWidth: CGFloat = 4) -> some View {
        self
            .overlay(
                Rectangle()
                    .stroke(color, lineWidth: lineWidth)
            )
    }
    
    /// Applies pixel-style small border
    func pixelBorderSmall(color: Color = Color("PixelBorder")) -> some View {
        self
            .overlay(
                Rectangle()
                    .stroke(color, lineWidth: 2)
            )
    }
}

// MARK: - Pixel UI Components

/// A retro-style pixel button
struct PixelButton<Content: View>: View {
    var action: () -> Void
    var backgroundColor: Color = Color("PixelAccent")
    var borderColor: Color = Color("PixelBorder")
    var content: Content
    
    init(backgroundColor: Color = Color("PixelAccent"), borderColor: Color = Color("PixelBorder"), action: @escaping () -> Void, @ViewBuilder content: () -> Content) {
        self.action = action
        self.backgroundColor = backgroundColor
        self.borderColor = borderColor
        self.content = content()
    }
    
    var body: some View {
        Button(action: action) {
            content
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(backgroundColor)
                .pixelBorderSmall(color: borderColor)
        }
        .buttonStyle(PixelButtonStyle())
    }
}

struct PixelButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .offset(y: configuration.isPressed ? 2 : 0)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.interactiveSpring(), value: configuration.isPressed)
    }
}

/// A retro-style pixel card/container
struct PixelCard<Content: View>: View {
    var backgroundColor: Color = .white
    var borderColor: Color = Color("PixelBorder")
    var showCorners: Bool = true
    var content: Content
    
    init(backgroundColor: Color = .white, borderColor: Color = Color("PixelBorder"), showCorners: Bool = true, @ViewBuilder content: () -> Content) {
        self.backgroundColor = backgroundColor
        self.borderColor = borderColor
        self.showCorners = showCorners
        self.content = content()
    }
    
    var body: some View {
        content
            .padding(12)
            .background(backgroundColor)
            .pixelBorderSmall(color: borderColor)
            .overlay(
                Group {
                    if showCorners {
                        PixelCorners(color: borderColor)
                    }
                }
            )
    }
}

/// A retro-style section header
struct PixelHeader: View {
    var title: String
    var subtitle: String?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title.uppercased())
                .font(.pixel(28))
                .foregroundColor(Color("PixelBorder"))
            
            if let subtitle = subtitle {
                Text(subtitle)
                    .font(.pixel(16))
                    .foregroundColor(Color("PixelAccent"))
            }
            
            Rectangle()
                .fill(Color("PixelAccent"))
                .frame(height: 4)
                .padding(.top, 4)
        }
        .padding(.horizontal)
        .padding(.top)
    }
}

// MARK: - Pixel Corner Decorations

struct PixelCorners: View {
    var color: Color = Color("PixelBorder")
    var size: CGFloat = 8
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Top-left corner
                Rectangle()
                    .fill(color)
                    .frame(width: size, height: size)
                    .position(x: size / 2, y: size / 2)
                
                // Top-right corner
                Rectangle()
                    .fill(color)
                    .frame(width: size, height: size)
                    .position(x: geometry.size.width - size / 2, y: size / 2)
                
                // Bottom-left corner
                Rectangle()
                    .fill(color)
                    .frame(width: size, height: size)
                    .position(x: size / 2, y: geometry.size.height - size / 2)
                
                // Bottom-right corner
                Rectangle()
                    .fill(color)
                    .frame(width: size, height: size)
                    .position(x: geometry.size.width - size / 2, y: geometry.size.height - size / 2)
            }
        }
    }
}

extension View {
    /// Adds pixel-style corner decorations
    func pixelCorners(color: Color = Color("PixelBorder"), size: CGFloat = 8) -> some View {
        self.overlay(
            PixelCorners(color: color, size: size)
        )
    }
}

// MARK: - Retro Dialog Border (Classic Pixel Game Style)

/// A classic pixel game dialog border with stepped corner decoration
struct RetroDialogBorder: View {
    var backgroundColor: Color = .white
    var borderColor: Color = Color("PixelBorder")
    var borderWidth: CGFloat = 3
    
    var body: some View {
        Canvas { context, size in
            let w = size.width
            let h = size.height
            let stepSize: CGFloat = 6
            let steps = 3
            let bw = borderWidth
            let half = bw / 2
            
            // 1. Fill background
            let bgRect = CGRect(x: 0, y: 0, width: w, height: h)
            context.fill(Path(bgRect), with: .color(backgroundColor))
            
            // 2. Draw main border (4 sides)
            // Top border
            var topPath = Path()
            topPath.move(to: CGPoint(x: 0, y: half))
            topPath.addLine(to: CGPoint(x: w, y: half))
            context.stroke(topPath, with: .color(borderColor), lineWidth: bw)
            
            // Left border
            var leftPath = Path()
            leftPath.move(to: CGPoint(x: half, y: 0))
            leftPath.addLine(to: CGPoint(x: half, y: h))
            context.stroke(leftPath, with: .color(borderColor), lineWidth: bw)
            
            // Right border (stops at step area)
            var rightPath = Path()
            rightPath.move(to: CGPoint(x: w - half, y: 0))
            rightPath.addLine(to: CGPoint(x: w - half, y: h - stepSize * CGFloat(steps)))
            context.stroke(rightPath, with: .color(borderColor), lineWidth: bw)
            
            // Bottom border (stops at step area)
            var bottomPath = Path()
            bottomPath.move(to: CGPoint(x: 0, y: h - half))
            bottomPath.addLine(to: CGPoint(x: w - stepSize * CGFloat(steps), y: h - half))
            context.stroke(bottomPath, with: .color(borderColor), lineWidth: bw)
            
            // 3. Draw stepped corner decoration (stair-step pattern)
            for i in 0..<steps {
                let stepX = w - stepSize * CGFloat(i + 1)
                let stepY = h - stepSize * CGFloat(steps - i)
                let nextStepY = h - stepSize * CGFloat(steps - i - 1)
                
                // Horizontal step line
                var hPath = Path()
                hPath.move(to: CGPoint(x: w - stepSize * CGFloat(i), y: stepY - half))
                hPath.addLine(to: CGPoint(x: stepX, y: stepY - half))
                context.stroke(hPath, with: .color(borderColor), lineWidth: bw)
                
                // Vertical step line
                var vPath = Path()
                vPath.move(to: CGPoint(x: stepX - half, y: stepY))
                vPath.addLine(to: CGPoint(x: stepX - half, y: nextStepY))
                context.stroke(vPath, with: .color(borderColor), lineWidth: bw)
            }
        }
    }
}

extension View {
    /// Applies classic pixel game dialog border with stepped corner decoration
    func pixelDialogBorder(
        backgroundColor: Color = .white,
        borderColor: Color = Color("PixelBorder"),
        borderWidth: CGFloat = 3
    ) -> some View {
        self
            .background(
                RetroDialogBorder(
                    backgroundColor: backgroundColor,
                    borderColor: borderColor,
                    borderWidth: borderWidth
                )
            )
    }
}

// MARK: - Dithered Background Pattern

struct DitheredBackground: View {
    var backgroundColor: Color = Color("PixelBg")
    var patternOpacity: Double = 0.1
    
    var body: some View {
        backgroundColor
            .overlay(
                Canvas { context, size in
                    // Create dithered pattern
                    for row in stride(from: 0, to: size.height, by: 4) {
                        for col in stride(from: 0, to: size.width, by: 4) {
                            // Checkerboard dither pattern
                            let isEvenRow = Int(row / 4) % 2 == 0
                            let isEvenCol = Int(col / 4) % 2 == 0
                            
                            if (isEvenRow && isEvenCol) || (!isEvenRow && !isEvenCol) {
                                let rect = CGRect(x: col, y: row, width: 2, height: 2)
                                context.fill(Path(rect), with: .color(.black.opacity(patternOpacity)))
                            }
                        }
                    }
                }
            )
    }
}

extension View {
    /// Applies dithered background pattern for pixel art aesthetic
    func ditheredBackground(color: Color = Color("PixelBg")) -> some View {
        self.background(DitheredBackground(backgroundColor: color))
    }
}
