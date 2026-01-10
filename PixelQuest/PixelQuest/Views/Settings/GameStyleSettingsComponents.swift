import SwiftUI

// MARK: - Nintendo Style Card Component
/// 圆润的游戏风格卡片组件，带弹跳动画效果
struct NintendoStyleCard<Content: View>: View {
    let content: Content
    var backgroundColor: Color = .white
    var shadowColor: Color = .black.opacity(0.1)
    
    @State private var isPressed = false
    
    init(
        backgroundColor: Color = .white,
        shadowColor: Color = .black.opacity(0.1),
        @ViewBuilder content: () -> Content
    ) {
        self.content = content()
        self.backgroundColor = backgroundColor
        self.shadowColor = shadowColor
    }
    
    var body: some View {
        content
            .background(backgroundColor)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: shadowColor, radius: 8, x: 0, y: 4)
            .scaleEffect(isPressed ? 0.97 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isPressed)
    }
}

// MARK: - Element Card Component
/// 五行元素卡片，带图标和进度指示
struct ElementCard: View {
    let element: FiveElement
    let value: Int
    let description: String
    var compact: Bool = false
    
    var body: some View {
        VStack(spacing: compact ? 8 : 12) {
            // 元素图标
            ZStack {
                Circle()
                    .fill(element.color.opacity(0.15))
                    .frame(width: compact ? 44 : 56, height: compact ? 44 : 56)
                
                Image(systemName: element.icon)
                    .font(.system(size: compact ? 20 : 26))
                    .foregroundColor(element.color)
            }
            
            // 元素名称
            Text(element.chineseName)
                .font(.pixel(compact ? 18 : 24))
                .foregroundColor(Color("PixelBorder"))
            
            // 数值
            Text("\(value)")
                .font(.pixel(compact ? 16 : 20))
                .foregroundColor(element.color)
            
            // 描述
            if !compact {
                Text(description)
                    .font(.pixel(11))
                    .foregroundColor(.gray)
                    .lineLimit(1)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(compact ? 12 : 16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: element.color.opacity(0.2), radius: 8, x: 0, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(element.color.opacity(0.3), lineWidth: 2)
        )
    }
}

// MARK: - Five Element Type
/// 五行元素枚举定义
enum FiveElement: String, CaseIterable {
    case fire = "fire"
    case wood = "wood"
    case water = "water"
    case metal = "metal"
    case earth = "earth"
    
    var chineseName: String {
        switch self {
        case .fire: return "火"
        case .wood: return "木"
        case .water: return "水"
        case .metal: return "金"
        case .earth: return "土"
        }
    }
    
    var englishName: String {
        switch self {
        case .fire: return "Fire"
        case .wood: return "Wood"
        case .water: return "Water"
        case .metal: return "Metal"
        case .earth: return "Earth"
        }
    }
    
    var icon: String {
        switch self {
        case .fire: return "flame.fill"
        case .wood: return "leaf.fill"
        case .water: return "drop.fill"
        case .metal: return "circle.hexagongrid.fill"
        case .earth: return "mountain.2.fill"
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

// MARK: - Animated Settings Row
/// 带动画效果的设置行组件
struct AnimatedSettingsRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    var subtitle: String? = nil
    var showChevron: Bool = true
    let action: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
            // 触觉反馈
            let feedback = UIImpactFeedbackGenerator(style: .light)
            feedback.impactOccurred()
            action()
        }) {
            HStack(spacing: 16) {
                // 图标
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(iconColor.opacity(0.15))
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: icon)
                        .font(.system(size: 20))
                        .foregroundColor(iconColor)
                }
                
                // 文本
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.pixel(16))
                        .foregroundColor(Color("PixelBorder"))
                    
                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(.pixel(12))
                            .foregroundColor(.gray)
                    }
                }
                
                Spacer()
                
                // 箭头
                if showChevron {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.gray)
                }
            }
            .padding(12)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(BounceButtonStyle())
    }
}

// MARK: - Game Style Toggle
/// 游戏风格开关组件
struct GameStyleToggle: View {
    let icon: String
    let iconColor: Color
    let title: String
    @Binding var isOn: Bool
    
    var body: some View {
        HStack(spacing: 16) {
            // 图标
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(iconColor.opacity(0.15))
                    .frame(width: 44, height: 44)
                
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(iconColor)
            }
            
            // 标题
            Text(title)
                .font(.pixel(16))
                .foregroundColor(Color("PixelBorder"))
            
            Spacer()
            
            // 自定义开关
            Toggle("", isOn: $isOn)
                .labelsHidden()
                .tint(Color("PixelBlue"))
        }
        .padding(12)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Bounce Button Style
/// 弹跳按钮样式
struct BounceButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

// MARK: - Section Header
/// 分区标题组件
struct GameSectionHeader: View {
    let title: String
    var icon: String? = nil
    var iconColor: Color = Color("PixelAccent")
    
    var body: some View {
        HStack(spacing: 8) {
            if let icon = icon {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundColor(iconColor)
            }
            
            Text(title)
                .font(.pixel(14))
                .foregroundColor(.gray)
            
            Spacer()
        }
        .padding(.horizontal, 4)
        .padding(.top, 8)
    }
}

// MARK: - Preview
#Preview {
    ScrollView {
        VStack(spacing: 16) {
            // Element Cards
            HStack(spacing: 12) {
                ElementCard(element: .fire, value: 42, description: "From exercise", compact: true)
                ElementCard(element: .water, value: 35, description: "From sleep", compact: true)
            }
            
            // Settings Rows
            VStack(spacing: 8) {
                AnimatedSettingsRow(
                    icon: "globe",
                    iconColor: .blue,
                    title: "Language",
                    subtitle: "English"
                ) {}
                
                AnimatedSettingsRow(
                    icon: "bell.fill",
                    iconColor: .orange,
                    title: "Notifications"
                ) {}
            }
            
            // Toggle
            GameStyleToggle(
                icon: "speaker.wave.2.fill",
                iconColor: .purple,
                title: "Sound Effects",
                isOn: .constant(true)
            )
        }
        .padding()
    }
    .background(Color("PixelBg"))
}
