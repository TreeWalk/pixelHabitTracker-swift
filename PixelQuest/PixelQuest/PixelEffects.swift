import SwiftUI

// MARK: - Pixel Effects System
// Advanced animation and particle effects for PixelQuest
// Enhances the retro pixel aesthetic with modern iOS fluidity

// MARK: - Animation Tokens Extension

extension PixelAnimation {
    /// Bounce animation for completion feedback
    static let bounce = Animation.interpolatingSpring(stiffness: 300, damping: 10)
    
    /// Pulse animation for attention-grabbing effects
    static let pulse = Animation.easeInOut(duration: 0.8).repeatForever(autoreverses: true)
    
    /// Shake animation for error feedback
    static let shake = Animation.spring(response: 0.2, dampingFraction: 0.3)
    
    /// Elastic spring for satisfying interactions
    static let elastic = Animation.interpolatingSpring(stiffness: 400, damping: 12)
    
    /// Delayed cascade for staggered animations
    static func cascade(index: Int, baseDelay: Double = 0.05) -> Animation {
        .spring(response: 0.4, dampingFraction: 0.7).delay(Double(index) * baseDelay)
    }
}

// MARK: - Pixel Particle System

/// Individual particle for the particle system
struct PixelParticle: Identifiable {
    let id = UUID()
    var position: CGPoint
    var velocity: CGVector
    var size: CGFloat
    var color: Color
    var opacity: Double
    var rotation: Double
    var lifetime: Double
    var age: Double = 0
}

/// Particle emitter types
enum ParticlePreset {
    case starBurst      // 星星爆发 - 任务完成
    case confetti       // 彩带飘落 - 等级提升
    case sparkle        // 闪光点 - 卡片高亮
    case energyWave     // 能量波 - 进度条满格
    case pixelDust      // 像素尘埃 - 物品删除
}

/// Pixel particle emitter view
struct PixelParticleEmitter: View {
    let preset: ParticlePreset
    let origin: CGPoint
    let isEmitting: Bool
    
    @State private var particles: [PixelParticle] = []
    @State private var timer: Timer?
    
    var body: some View {
        Canvas { context, size in
            for particle in particles {
                let rect = CGRect(
                    x: particle.position.x - particle.size / 2,
                    y: particle.position.y - particle.size / 2,
                    width: particle.size,
                    height: particle.size
                )
                
                context.opacity = particle.opacity * (1 - particle.age / particle.lifetime)
                context.fill(Path(rect), with: .color(particle.color))
            }
        }
        .allowsHitTesting(false)
        .onChange(of: isEmitting) { _, newValue in
            if newValue {
                emit()
            }
        }
        .onDisappear {
            timer?.invalidate()
        }
    }
    
    private func emit() {
        particles = generateParticles(for: preset)
        
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1/60, repeats: true) { _ in
            updateParticles()
        }
        
        // Stop after animation completes
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            timer?.invalidate()
            particles.removeAll()
        }
    }
    
    private func generateParticles(for preset: ParticlePreset) -> [PixelParticle] {
        switch preset {
        case .starBurst:
            return (0..<20).map { _ in
                let angle = Double.random(in: 0...(.pi * 2))
                let speed = Double.random(in: 100...200)
                return PixelParticle(
                    position: origin,
                    velocity: CGVector(dx: cos(angle) * speed, dy: sin(angle) * speed),
                    size: CGFloat.random(in: 4...8),
                    color: [Color.yellow, Color.orange, Color(hex: "#FFD700")].randomElement()!,
                    opacity: 1,
                    rotation: Double.random(in: 0...360),
                    lifetime: Double.random(in: 0.8...1.2)
                )
            }
            
        case .confetti:
            let colors: [Color] = [.red, .blue, .green, .yellow, .purple, .orange]
            return (0..<30).map { _ in
                PixelParticle(
                    position: CGPoint(x: CGFloat.random(in: 0...UIScreen.main.bounds.width), y: -20),
                    velocity: CGVector(dx: CGFloat.random(in: -30...30), dy: CGFloat.random(in: 80...150)),
                    size: CGFloat.random(in: 6...10),
                    color: colors.randomElement()!,
                    opacity: 1,
                    rotation: Double.random(in: 0...360),
                    lifetime: Double.random(in: 2...3)
                )
            }
            
        case .sparkle:
            return (0..<8).map { i in
                let angle = (Double(i) / 8) * (.pi * 2)
                let radius: CGFloat = 30
                return PixelParticle(
                    position: CGPoint(
                        x: origin.x + cos(angle) * radius,
                        y: origin.y + sin(angle) * radius
                    ),
                    velocity: .zero,
                    size: 4,
                    color: .white,
                    opacity: 0.8,
                    rotation: 0,
                    lifetime: 0.6
                )
            }
            
        case .energyWave:
            return (0..<12).map { i in
                let angle = (Double(i) / 12) * (.pi * 2)
                let speed = 60.0
                return PixelParticle(
                    position: origin,
                    velocity: CGVector(dx: cos(angle) * speed, dy: sin(angle) * speed),
                    size: 6,
                    color: Color(hex: "#00FFFF"),
                    opacity: 0.7,
                    rotation: 0,
                    lifetime: 0.5
                )
            }
            
        case .pixelDust:
            return (0..<15).map { _ in
                PixelParticle(
                    position: origin,
                    velocity: CGVector(
                        dx: CGFloat.random(in: -50...50),
                        dy: CGFloat.random(in: (-80)...(-20))
                    ),
                    size: CGFloat.random(in: 3...6),
                    color: Color.gray,
                    opacity: 0.6,
                    rotation: 0,
                    lifetime: Double.random(in: 0.5...1)
                )
            }
        }
    }
    
    private func updateParticles() {
        let dt = 1.0 / 60.0
        particles = particles.compactMap { particle in
            var p = particle
            p.position.x += p.velocity.dx * dt
            p.position.y += p.velocity.dy * dt
            p.velocity.dy += 200 * dt // Gravity
            p.age += dt
            
            if p.age >= p.lifetime {
                return nil
            }
            return p
        }
    }
}

// MARK: - Pixel Glow Border Effect

struct PixelGlowModifier: ViewModifier {
    let color: Color
    let isActive: Bool
    let intensity: CGFloat
    
    @State private var glowOpacity: Double = 0
    
    func body(content: Content) -> some View {
        content
            .overlay(
                Rectangle()
                    .stroke(color.opacity(glowOpacity), lineWidth: 4)
                    .blur(radius: 4)
            )
            .overlay(
                Rectangle()
                    .stroke(color.opacity(glowOpacity * 0.5), lineWidth: 2)
            )
            .onChange(of: isActive) { _, newValue in
                withAnimation(newValue ? PixelAnimation.pulse : .easeOut(duration: 0.3)) {
                    glowOpacity = newValue ? Double(intensity) : 0
                }
            }
    }
}

extension View {
    /// Adds a glowing border effect when active
    func pixelGlow(color: Color = .yellow, isActive: Bool, intensity: CGFloat = 0.8) -> some View {
        modifier(PixelGlowModifier(color: color, isActive: isActive, intensity: intensity))
    }
}

// MARK: - Shimmer Effect

struct PixelShimmerEffect: ViewModifier {
    let isActive: Bool
    
    @State private var shimmerOffset: CGFloat = -200
    
    func body(content: Content) -> some View {
        content
            .overlay(
                GeometryReader { geometry in
                    if isActive {
                        LinearGradient(
                            colors: [
                                .clear,
                                .white.opacity(0.3),
                                .clear
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                        .frame(width: 60)
                        .offset(x: shimmerOffset)
                        .onAppear {
                            withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                                shimmerOffset = geometry.size.width + 60
                            }
                        }
                    }
                }
                .clipped()
            )
    }
}

extension View {
    /// Adds a shimmer/shine effect across the view
    func pixelShimmer(isActive: Bool = true) -> some View {
        modifier(PixelShimmerEffect(isActive: isActive))
    }
}

// MARK: - Time-Based Dynamic Background

struct TimeBasedBackground: View {
    @State private var currentPeriod: DayPeriod = .day
    
    enum DayPeriod {
        case dawn      // 5-9
        case day       // 9-17
        case dusk      // 17-20
        case night     // 20-5
        
        var gradient: [Color] {
            switch self {
            case .dawn:
                return [Color(hex: "#FFE5B4"), Color(hex: "#FFDAB9"), Color(hex: "#FFE4E1")]
            case .day:
                return [Color(hex: "#87CEEB"), Color(hex: "#B0E0E6"), Color(hex: "#F0F8FF")]
            case .dusk:
                return [Color(hex: "#DDA0DD"), Color(hex: "#FFA07A"), Color(hex: "#FFB6C1")]
            case .night:
                return [Color(hex: "#191970"), Color(hex: "#483D8B"), Color(hex: "#2F2F4F")]
            }
        }
        
        var particleColor: Color {
            switch self {
            case .dawn: return .orange.opacity(0.3)
            case .day: return .white.opacity(0.5)
            case .dusk: return .yellow.opacity(0.4)
            case .night: return .white.opacity(0.8)
            }
        }
    }
    
    var body: some View {
        ZStack {
            // Gradient background
            LinearGradient(
                colors: currentPeriod.gradient,
                startPoint: .top,
                endPoint: .bottom
            )
            
            // Floating particles based on time
            FloatingParticlesView(color: currentPeriod.particleColor, count: currentPeriod == .night ? 30 : 10)
            
            // Subtle noise overlay for pixel feel
            SubtleNoiseOverlay(opacity: 0.03, useCheckerboard: true)
        }
        .ignoresSafeArea()
        .onAppear {
            updatePeriod()
        }
    }
    
    private func updatePeriod() {
        let hour = Calendar.current.component(.hour, from: Date())
        
        switch hour {
        case 5..<9:
            currentPeriod = .dawn
        case 9..<17:
            currentPeriod = .day
        case 17..<20:
            currentPeriod = .dusk
        default:
            currentPeriod = .night
        }
    }
}

/// Floating particles for ambient background effect
struct FloatingParticlesView: View {
    let color: Color
    let count: Int
    
    @State private var positions: [CGPoint] = []
    @State private var opacities: [Double] = []
    
    var body: some View {
        GeometryReader { geometry in
            Canvas { context, size in
                let particleCount = min(count, positions.count)
                for i in 0..<particleCount {
                    let rect = CGRect(
                        x: positions[i].x,
                        y: positions[i].y,
                        width: 3,
                        height: 3
                    )
                    context.opacity = opacities.indices.contains(i) ? opacities[i] : 0.5
                    context.fill(Path(rect), with: .color(color))
                }
            }
            .onAppear {
                positions = (0..<count).map { _ in
                    CGPoint(
                        x: CGFloat.random(in: 0...geometry.size.width),
                        y: CGFloat.random(in: 0...geometry.size.height)
                    )
                }
                opacities = (0..<count).map { _ in Double.random(in: 0.3...0.8) }
                
                // Twinkle animation
                withAnimation(.easeInOut(duration: 2).repeatForever()) {
                    opacities = opacities.map { _ in Double.random(in: 0.2...1.0) }
                }
            }
        }
        .allowsHitTesting(false)
    }
}

// MARK: - Pixel Toast Notification

struct PixelToast: View {
    let message: String
    let icon: String
    let color: Color
    @Binding var isShowing: Bool
    
    var body: some View {
        if isShowing {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(color)
                
                Text(message)
                    .font(.pixel(16))
                    .foregroundColor(.darkCoffee)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(Color.white)
            .pixelDoubleBorder(outerColor: .darkCoffee, innerColor: color.opacity(0.3))
            .pixelHardShadow(color: .darkCoffee.opacity(0.25), offset: 4)
            .transition(.move(edge: .top).combined(with: .opacity))
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                    withAnimation(.spring()) {
                        isShowing = false
                    }
                }
            }
        }
    }
}

// MARK: - Animated Progress Fill

struct AnimatedProgressFill: View {
    let progress: Double
    let maxBlocks: Int
    let blockColor: Color
    let emptyColor: Color
    
    @State private var animatedBlocks: Int = 0
    
    private var targetBlocks: Int {
        Int(round(progress * Double(maxBlocks)))
    }
    
    var body: some View {
        HStack(spacing: 2) {
            ForEach(0..<maxBlocks, id: \.self) { index in
                Rectangle()
                    .fill(index < animatedBlocks ? blockColor : emptyColor)
                    .frame(height: 14)
                    .scaleEffect(index < animatedBlocks ? 1.0 : 0.9)
                    .animation(
                        .spring(response: 0.3, dampingFraction: 0.6)
                        .delay(Double(index) * 0.05),
                        value: animatedBlocks
                    )
            }
        }
        .onChange(of: progress) { _, _ in
            animateProgress()
        }
        .onAppear {
            animateProgress()
        }
    }
    
    private func animateProgress() {
        // Reset and animate
        animatedBlocks = 0
        
        for i in 0..<targetBlocks {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.08) {
                withAnimation(.spring(response: 0.2, dampingFraction: 0.7)) {
                    animatedBlocks = i + 1
                }
            }
        }
    }
}

// MARK: - Shake Effect Modifier

struct ShakeEffect: GeometryEffect {
    var amount: CGFloat = 5
    var shakesPerUnit: CGFloat = 3
    var animatableData: CGFloat
    
    func effectValue(size: CGSize) -> ProjectionTransform {
        ProjectionTransform(
            CGAffineTransform(translationX: amount * sin(animatableData * .pi * shakesPerUnit), y: 0)
        )
    }
}

extension View {
    /// Applies a shake animation
    func shake(trigger: Bool) -> some View {
        modifier(ShakeModifier(trigger: trigger))
    }
}

struct ShakeModifier: ViewModifier {
    let trigger: Bool
    @State private var shakeAmount: CGFloat = 0
    
    func body(content: Content) -> some View {
        content
            .modifier(ShakeEffect(animatableData: shakeAmount))
            .onChange(of: trigger) { _, _ in
                withAnimation(.spring(response: 0.2, dampingFraction: 0.3)) {
                    shakeAmount = 1
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    shakeAmount = 0
                }
            }
    }
}

// Note: Color.init(hex:) is defined in LibraryDetailView.swift

// MARK: - Previews

#Preview("Particle Effects") {
    struct ParticlePreview: View {
        @State private var emit = false
        
        var body: some View {
            ZStack {
                Color.creamBg
                
                PixelParticleEmitter(
                    preset: .starBurst,
                    origin: CGPoint(x: 200, y: 400),
                    isEmitting: emit
                )
                
                Button("Emit!") {
                    emit = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        emit = false
                    }
                }
                .font(.pixel(20))
                .padding()
                .cozyCard()
            }
        }
    }
    return ParticlePreview()
}

#Preview("Time Background") {
    TimeBasedBackground()
}

#Preview("Glow Effect") {
    struct GlowPreview: View {
        @State private var isGlowing = false
        
        var body: some View {
            VStack {
                Text("Long Press Me")
                    .font(.pixel(20))
                    .padding()
                    .background(Color.white)
                    .pixelBorder()
                    .pixelGlow(color: .yellow, isActive: isGlowing)
                    .onLongPressGesture(minimumDuration: 0.3) {
                        isGlowing.toggle()
                    }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.creamBg)
        }
    }
    return GlowPreview()
}
