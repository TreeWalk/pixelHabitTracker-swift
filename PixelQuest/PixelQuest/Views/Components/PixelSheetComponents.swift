import SwiftUI

// MARK: - Pixel Overlay System
/// 完全自定义的像素风格弹出层系统，替代 iOS 原生 Sheet

// MARK: - Pixel Drawer (底部抽屉)
/// 像素风格的底部抽屉弹出层
struct PixelDrawer<Content: View>: View {
    @Binding var isPresented: Bool
    var title: String
    var icon: String?
    var iconColor: Color = Color("PixelAccent")
    var height: CGFloat = 0.6 // 屏幕高度比例
    @ViewBuilder var content: () -> Content
    
    @State private var offset: CGFloat = 1000
    @State private var dragOffset: CGFloat = 0
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .bottom) {
                // 半透明遮罩
                if isPresented {
                    Color.black
                        .opacity(0.5)
                        .ignoresSafeArea()
                        .onTapGesture {
                            dismissDrawer()
                        }
                        .transition(.opacity)
                }
                
                // 抽屉主体
                if isPresented {
                    VStack(spacing: 0) {
                        // 像素风格顶部边框
                        PixelDrawerTopBorder()
                        
                        // 像素风格把手
                        PixelDrawerHandle()
                            .gesture(
                                DragGesture()
                                    .onChanged { value in
                                        if value.translation.height > 0 {
                                            dragOffset = value.translation.height
                                        }
                                    }
                                    .onEnded { value in
                                        if value.translation.height > 100 {
                                            dismissDrawer()
                                        } else {
                                            withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                                                dragOffset = 0
                                            }
                                        }
                                    }
                            )
                        
                        // 标题栏
                        HStack {
                            HStack(spacing: 8) {
                                if let icon = icon {
                                    Image(systemName: icon)
                                        .font(.system(size: 20))
                                        .foregroundColor(iconColor)
                                }
                                Text(title)
                                    .font(.pixel(20))
                                    .foregroundColor(Color("PixelBorder"))
                            }
                            Spacer()
                            PixelCloseButton {
                                dismissDrawer()
                            }
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 12)
                        
                        // 分隔线
                        Rectangle()
                            .fill(Color("PixelBorder").opacity(0.3))
                            .frame(height: 2)
                            .padding(.horizontal)
                        
                        // 内容区
                        content()
                    }
                    .frame(height: geometry.size.height * height)
                    .background(
                        PixelDrawerBackground()
                    )
                    .offset(y: offset + dragOffset)
                    .transition(.move(edge: .bottom))
                    .onAppear {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                            offset = 0
                        }
                    }
                }
            }
        }
        .ignoresSafeArea()
    }
    
    private func dismissDrawer() {
        withAnimation(.spring(response: 0.25, dampingFraction: 0.9)) {
            offset = 1000
            dragOffset = 0
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            isPresented = false
        }
    }
}

// MARK: - Pixel Drawer Handle
struct PixelDrawerHandle: View {
    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<3, id: \.self) { _ in
                Rectangle()
                    .fill(Color("PixelBorder").opacity(0.4))
                    .frame(width: 16, height: 4)
            }
        }
        .padding(.vertical, 12)
    }
}

// MARK: - Pixel Drawer Top Border
/// 像素风格的顶部阶梯边框
struct PixelDrawerTopBorder: View {
    var body: some View {
        GeometryReader { geometry in
            let blockSize: CGFloat = 6
            let borderColor = Color("PixelBorder")
            
            ZStack {
                // 左侧阶梯
                HStack(spacing: 0) {
                    VStack(alignment: .leading, spacing: 0) {
                        Rectangle()
                            .fill(borderColor)
                            .frame(width: blockSize, height: blockSize)
                        Rectangle()
                            .fill(borderColor)
                            .frame(width: blockSize * 2, height: blockSize)
                        Rectangle()
                            .fill(borderColor)
                            .frame(width: blockSize * 3, height: blockSize)
                    }
                    Spacer()
                }
                
                // 右侧阶梯
                HStack(spacing: 0) {
                    Spacer()
                    VStack(alignment: .trailing, spacing: 0) {
                        Rectangle()
                            .fill(borderColor)
                            .frame(width: blockSize, height: blockSize)
                        Rectangle()
                            .fill(borderColor)
                            .frame(width: blockSize * 2, height: blockSize)
                        Rectangle()
                            .fill(borderColor)
                            .frame(width: blockSize * 3, height: blockSize)
                    }
                }
                
                // 顶部横线
                VStack {
                    Rectangle()
                        .fill(borderColor)
                        .frame(height: 3)
                    Spacer()
                }
            }
        }
        .frame(height: 18)
    }
}

// MARK: - Pixel Drawer Background
/// 像素风格的抽屉背景
struct PixelDrawerBackground: View {
    var body: some View {
        ZStack {
            // 主背景
            Color("PixelBg")
            
            // 左右边框
            HStack {
                Rectangle()
                    .fill(Color("PixelBorder"))
                    .frame(width: 3)
                Spacer()
                Rectangle()
                    .fill(Color("PixelBorder"))
                    .frame(width: 3)
            }
        }
    }
}

// MARK: - Pixel Close Button
struct PixelCloseButton: View {
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text("✕")
                .font(.pixel(18))
                .foregroundColor(Color("PixelBorder"))
                .frame(width: 32, height: 32)
                .background(Color("PixelAccent"))
                .overlay(
                    Rectangle()
                        .stroke(Color("PixelBorder"), lineWidth: 2)
                )
        }
    }
}

// MARK: - Pixel Dialog (中央对话框)
/// RPG 风格的中央对话框
struct PixelDialog<Content: View>: View {
    @Binding var isPresented: Bool
    var title: String
    var width: CGFloat = 320
    @ViewBuilder var content: () -> Content
    
    @State private var scale: CGFloat = 0.8
    @State private var opacity: Double = 0
    
    var body: some View {
        ZStack {
            // 半透明遮罩
            if isPresented {
                Color.black
                    .opacity(0.5)
                    .ignoresSafeArea()
                    .onTapGesture {
                        dismissDialog()
                    }
            }
            
            // 对话框
            if isPresented {
                VStack(spacing: 0) {
                    // 标题栏
                    HStack {
                        Text(title.uppercased())
                            .font(.pixel(18))
                            .foregroundColor(Color("PixelBorder"))
                        Spacer()
                        PixelCloseButton {
                            dismissDialog()
                        }
                    }
                    .padding()
                    .background(Color("PixelAccent").opacity(0.3))
                    
                    Rectangle()
                        .fill(Color("PixelBorder"))
                        .frame(height: 3)
                    
                    // 内容区
                    content()
                }
                .frame(width: width)
                .background(Color("PixelBg"))
                .overlay(
                    Rectangle()
                        .stroke(Color("PixelBorder"), lineWidth: 4)
                )
                // 阶梯角装饰
                .overlay(
                    PixelDialogCorners()
                )
                .scaleEffect(scale)
                .opacity(opacity)
                .onAppear {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                        scale = 1
                        opacity = 1
                    }
                }
            }
        }
    }
    
    private func dismissDialog() {
        withAnimation(.easeOut(duration: 0.15)) {
            scale = 0.8
            opacity = 0
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            isPresented = false
        }
    }
}

// MARK: - Pixel Dialog Corners
struct PixelDialogCorners: View {
    var body: some View {
        GeometryReader { geometry in
            let blockSize: CGFloat = 6
            let borderColor = Color("PixelBorder")
            
            ZStack {
                // 右下角阶梯
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        VStack(alignment: .trailing, spacing: 0) {
                            HStack(spacing: 0) {
                                Rectangle()
                                    .fill(borderColor)
                                    .frame(width: blockSize, height: blockSize)
                            }
                            HStack(spacing: 0) {
                                Rectangle()
                                    .fill(borderColor)
                                    .frame(width: blockSize, height: blockSize)
                                Rectangle()
                                    .fill(borderColor)
                                    .frame(width: blockSize, height: blockSize)
                            }
                            HStack(spacing: 0) {
                                Rectangle()
                                    .fill(borderColor)
                                    .frame(width: blockSize, height: blockSize)
                                Rectangle()
                                    .fill(borderColor)
                                    .frame(width: blockSize, height: blockSize)
                                Rectangle()
                                    .fill(borderColor)
                                    .frame(width: blockSize, height: blockSize)
                            }
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Pixel Confirm Dialog
/// 像素风格的确认对话框
struct PixelConfirmDialog: View {
    @Binding var isPresented: Bool
    var title: String = "确认"
    var message: String
    var confirmText: String = "确定"
    var cancelText: String = "取消"
    var isDestructive: Bool = false
    var onConfirm: () -> Void
    
    @State private var scale: CGFloat = 0.8
    @State private var opacity: Double = 0
    
    var body: some View {
        ZStack {
            // 半透明遮罩
            if isPresented {
                Color.black
                    .opacity(0.5)
                    .ignoresSafeArea()
                    .onTapGesture {
                        dismissDialog()
                    }
            }
            
            // 对话框
            if isPresented {
                VStack(spacing: 0) {
                    // 标题栏
                    HStack {
                        if isDestructive {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(Color("PixelRed"))
                        }
                        Text(title.uppercased())
                            .font(.pixel(18))
                            .foregroundColor(isDestructive ? Color("PixelRed") : Color("PixelBorder"))
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color("PixelBg"))
                    
                    Rectangle()
                        .fill(Color("PixelBorder"))
                        .frame(height: 3)
                    
                    // 内容
                    Text(message)
                        .font(.pixel(16))
                        .foregroundColor(Color("PixelBorder"))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 20)
                        .frame(maxWidth: .infinity)
                        .background(Color.white)
                    
                    Rectangle()
                        .fill(Color("PixelBorder"))
                        .frame(height: 3)
                    
                    // 按钮区
                    HStack(spacing: 12) {
                        // 取消按钮
                        Button(action: dismissDialog) {
                            Text(cancelText)
                                .font(.pixel(16))
                                .foregroundColor(Color("PixelBorder"))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(Color.white)
                                .overlay(
                                    Rectangle()
                                        .stroke(Color("PixelBorder"), lineWidth: 2)
                                )
                        }
                        
                        // 确认按钮
                        Button(action: {
                            dismissDialog()
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                onConfirm()
                            }
                        }) {
                            Text(confirmText)
                                .font(.pixel(16))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(isDestructive ? Color("PixelRed") : Color("PixelAccent"))
                                .overlay(
                                    Rectangle()
                                        .stroke(isDestructive ? Color("PixelRed") : Color("PixelBorder"), lineWidth: 2)
                                )
                        }
                    }
                    .padding()
                    .background(Color("PixelBg"))
                }
                .frame(width: 300)
                .overlay(
                    Rectangle()
                        .stroke(Color("PixelBorder"), lineWidth: 4)
                )
                .overlay(
                    PixelDialogCorners()
                )
                .scaleEffect(scale)
                .opacity(opacity)
                .onAppear {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                        scale = 1
                        opacity = 1
                    }
                }
            }
        }
    }
    
    private func dismissDialog() {
        withAnimation(.easeOut(duration: 0.15)) {
            scale = 0.8
            opacity = 0
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            isPresented = false
        }
    }
}

// MARK: - View Extension for Pixel Overlays
extension View {
    /// 添加像素风格底部抽屉
    func pixelDrawer<Content: View>(
        isPresented: Binding<Bool>,
        title: String,
        icon: String? = nil,
        iconColor: Color = Color("PixelAccent"),
        height: CGFloat = 0.6,
        @ViewBuilder content: @escaping () -> Content
    ) -> some View {
        ZStack {
            self
            
            PixelDrawer(
                isPresented: isPresented,
                title: title,
                icon: icon,
                iconColor: iconColor,
                height: height,
                content: content
            )
        }
    }
    
    /// 添加像素风格中央对话框
    func pixelDialog<Content: View>(
        isPresented: Binding<Bool>,
        title: String,
        width: CGFloat = 320,
        @ViewBuilder content: @escaping () -> Content
    ) -> some View {
        ZStack {
            self
            
            PixelDialog(
                isPresented: isPresented,
                title: title,
                width: width,
                content: content
            )
        }
    }
    
    /// 添加像素风格确认对话框
    func pixelConfirmDialog(
        isPresented: Binding<Bool>,
        title: String = "确认",
        message: String,
        confirmText: String = "确定",
        cancelText: String = "取消",
        isDestructive: Bool = false,
        onConfirm: @escaping () -> Void
    ) -> some View {
        ZStack {
            self
            
            PixelConfirmDialog(
                isPresented: isPresented,
                title: title,
                message: message,
                confirmText: confirmText,
                cancelText: cancelText,
                isDestructive: isDestructive,
                onConfirm: onConfirm
            )
        }
    }
}

// MARK: - Previews

#Preview("Pixel Drawer") {
    struct PreviewWrapper: View {
        @State private var showDrawer = true
        
        var body: some View {
            ZStack {
                Color("PixelBg").ignoresSafeArea()
                
                Button("Show Drawer") {
                    showDrawer = true
                }
                .font(.pixel(20))
            }
            .pixelDrawer(
                isPresented: $showDrawer,
                title: "快速记录睡眠",
                icon: "moon.zzz.fill",
                iconColor: Color("PixelBlue"),
                height: 0.5
            ) {
                VStack {
                    Text("Sheet Content Here")
                        .font(.pixel(16))
                        .foregroundColor(Color("PixelBorder"))
                        .padding()
                    
                    Spacer()
                    
                    Button(action: {}) {
                        Text("记录睡眠 ✓")
                            .font(.pixel(20))
                            .foregroundColor(Color("PixelBorder"))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color("PixelAccent"))
                            .overlay(
                                Rectangle()
                                    .stroke(Color("PixelBorder"), lineWidth: 2)
                            )
                    }
                    .padding()
                }
            }
        }
    }
    
    return PreviewWrapper()
}

#Preview("Pixel Confirm Dialog") {
    struct PreviewWrapper: View {
        @State private var showDialog = true
        
        var body: some View {
            ZStack {
                Color("PixelBg").ignoresSafeArea()
                
                Button("Show Dialog") {
                    showDialog = true
                }
                .font(.pixel(20))
            }
            .pixelConfirmDialog(
                isPresented: $showDialog,
                title: "删除物品",
                message: "确定要删除 \"MacBook Pro\" 吗？\n此操作无法撤销。",
                confirmText: "🗑️ 删除",
                cancelText: "取消",
                isDestructive: true,
                onConfirm: {}
            )
        }
    }
    
    return PreviewWrapper()
}
