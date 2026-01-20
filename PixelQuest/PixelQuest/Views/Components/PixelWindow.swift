import SwiftUI

// MARK: - Pixel Window System
/// 简洁的像素风格弹窗系统

struct PixelWindow<Content: View>: View {
    @Binding var isPresented: Bool
    var title: String
    var icon: String?
    var iconColor: Color = Color("PixelAccent")
    @ViewBuilder var content: () -> Content
    
    @State private var scale: CGFloat = 0.9
    @State private var opacity: Double = 0
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // 半透明遮罩
                if isPresented {
                    Color.black
                        .opacity(0.5)
                        .ignoresSafeArea()
                        .onTapGesture {
                            dismissWindow()
                        }
                }
                
                // 窗口主体
                if isPresented {
                    VStack(spacing: 0) {
                        // 标题栏
                        HStack(spacing: 6) {
                            if let icon = icon {
                                Image(systemName: icon)
                                    .font(.system(size: 14))
                                    .foregroundColor(iconColor)
                            }
                            Text(title)
                                .font(.pixel(14))
                                .foregroundColor(Color("PixelBorder"))
                                .lineLimit(1)
                            
                            Spacer()
                            
                            // 关闭按钮
                            Button(action: dismissWindow) {
                                Text("✕")
                                    .font(.pixel(14))
                                    .foregroundColor(Color("PixelBorder"))
                                    .frame(width: 24, height: 24)
                                    .background(Color("PixelAccent").opacity(0.3))
                                    .overlay(
                                        Rectangle()
                                            .stroke(Color("PixelBorder"), lineWidth: 2)
                                    )
                            }
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 8)
                        .background(Color("PixelBg"))
                        
                        // 分隔线
                        Rectangle()
                            .fill(Color("PixelBorder"))
                            .frame(height: 2)
                        
                        // 内容区
                        content()
                            .frame(maxWidth: .infinity)
                    }
                    .frame(width: min(geometry.size.width - 40, 320))
                    .fixedSize(horizontal: false, vertical: true)
                    .background(Color("PixelBg"))
                    .overlay(
                        Rectangle()
                            .stroke(Color("PixelBorder"), lineWidth: 3)
                    )
                    .scaleEffect(scale)
                    .opacity(opacity)
                    .onAppear {
                        withAnimation(.spring(response: 0.2, dampingFraction: 0.8)) {
                            scale = 1
                            opacity = 1
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
    
    private func dismissWindow() {
        withAnimation(.easeOut(duration: 0.1)) {
            scale = 0.9
            opacity = 0
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            isPresented = false
        }
    }
}

// MARK: - View Extension
extension View {
    func pixelWindow<Content: View>(
        isPresented: Binding<Bool>,
        title: String,
        icon: String? = nil,
        iconColor: Color = Color("PixelAccent"),
        @ViewBuilder content: @escaping () -> Content
    ) -> some View {
        ZStack {
            self
            
            PixelWindow(
                isPresented: isPresented,
                title: title,
                icon: icon,
                iconColor: iconColor,
                content: content
            )
        }
    }
}
