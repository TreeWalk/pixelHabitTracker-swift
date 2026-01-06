import SwiftUI

// MARK: - Thermal Receipt Style

struct ThermalReceiptView<Content: View>: View {
    let ticketNo: String
    let date: Date
    let title: String
    let content: Content
    
    init(ticketNo: String = UUID().uuidString.prefix(6).uppercased(),
         date: Date = Date(),
         title: String,
         @ViewBuilder content: () -> Content) {
        self.ticketNo = String(ticketNo)
        self.date = date
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // 小票纸张效果
            VStack(spacing: 16) {
                // 头部
                receiptHeader
                
                // 虚线分隔
                ThermalDashedLine()
                    .stroke(Color.brown.opacity(0.3), style: StrokeStyle(lineWidth: 1, dash: [4, 3]))
                    .frame(height: 1)
                
                // 内容区域
                content
                
                // 底部
                receiptFooter
            }
            .padding(20)
            .background(thermalPaperGradient)
            .clipShape(ReceiptShape())
            .overlay(
                ReceiptShape()
                    .stroke(Color.brown.opacity(0.2), lineWidth: 1)
            )
        }
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
    
    // 热敏纸渐变背景
    private var thermalPaperGradient: some ShapeStyle {
        LinearGradient(
            colors: [
                Color(red: 0.98, green: 0.96, blue: 0.94),
                Color(red: 0.96, green: 0.94, blue: 0.92)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }
    
    // 头部
    private var receiptHeader: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text("THERMAL")
                    .font(.pixel(24))
                    .fontWeight(.bold)
                    .foregroundColor(Color(red: 0.3, green: 0.25, blue: 0.2))
                
                Text("NO: \(ticketNo)")
                    .font(.pixel(14))
                    .foregroundColor(Color.brown.opacity(0.6))
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text(formatDate(date))
                    .font(.pixel(18))
                    .foregroundColor(Color(red: 0.3, green: 0.25, blue: 0.2))
                
                Text(formatTime(date))
                    .font(.pixel(18))
                    .foregroundColor(Color(red: 0.3, green: 0.25, blue: 0.2))
            }
        }
    }
    
    // 底部
    private var receiptFooter: some View {
        VStack(spacing: 12) {
            // 标题
            HStack {
                Text(title)
                    .font(.pixel(20))
                    .foregroundColor(Color(red: 0.3, green: 0.25, blue: 0.2))
                Spacer()
            }
            
            // 分隔线
            Rectangle()
                .fill(Color.brown.opacity(0.4))
                .frame(height: 2)
            
            // 条形码
            HStack {
                BarcodeView()
                    .frame(width: 120, height: 30)
                
                Spacer()
                
                Text("EOT")
                    .font(.pixel(14))
                    .foregroundColor(Color.brown.opacity(0.5))
            }
            
            // 撕裂线
            Text("--- TEAR HERE ---")
                .font(.pixel(12))
                .foregroundColor(Color.brown.opacity(0.4))
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yy/MM/dd"
        return formatter.string(from: date)
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
}

// MARK: - Thermal Dashed Line

struct ThermalDashedLine: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: 0, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.width, y: rect.midY))
        return path
    }
}

// MARK: - Barcode View

struct BarcodeView: View {
    var body: some View {
        HStack(spacing: 1) {
            ForEach(0..<30, id: \.self) { i in
                Rectangle()
                    .fill(Color(red: 0.2, green: 0.15, blue: 0.1))
                    .frame(width: CGFloat.random(in: 1...3))
            }
        }
    }
}

// MARK: - Triangular Tear Edge

// MARK: - Receipt Shape

struct ReceiptShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let triangleWidth: CGFloat = 12
        let triangleHeight: CGFloat = 6 // 保持扁平效果
        
        // 1. 从左上角开始
        path.move(to: CGPoint(x: 0, y: 0))
        
        // 2. 右上角
        path.addLine(to: CGPoint(x: rect.width, y: 0))
        
        // 3. 右下角 (垂直到底)
        // 这一步实现了"两边是直的"，直接画到最底部
        path.addLine(to: CGPoint(x: rect.width, y: rect.height))
        
        // 4. 底部锯齿边 (从右向左绘制)
        // 这次我们画的是"缺口"(valleys)，所以点是向上凹陷的
        let width = rect.width
        let count = max(1, round(width / triangleWidth))
        let step = width / CGFloat(count)
        
        for i in 0..<Int(count) {
            let currentX = width - CGFloat(i) * step
            
            // 向上凹陷的点 (Valley)
            path.addLine(to: CGPoint(x: currentX - step / 2, y: rect.height - triangleHeight))
            
            // 回到底部直线的点 (Tip)
            path.addLine(to: CGPoint(x: currentX - step, y: rect.height))
        }
        
        // 5. 回到左上角 (闭合)
        // 此时我们应该在 (0, height)，这保证了左边也是直的
        path.addLine(to: CGPoint(x: 0, y: 0))
        path.closeSubpath()
        
        return path
    }
}

// MARK: - Receipt Content Row

struct ReceiptRow: View {
    let label: String
    let value: String
    var valueColor: Color = Color(red: 0.3, green: 0.25, blue: 0.2)
    var isBold: Bool = false
    
    var body: some View {
        HStack {
            Text(label)
                .font(.pixel(isBold ? 16 : 14))
                .foregroundColor(Color.brown.opacity(0.7))
            Spacer()
            Text(value)
                .font(.pixel(isBold ? 16 : 14))
                .fontWeight(isBold ? .bold : .regular)
                .foregroundColor(valueColor)
        }
    }
}

// MARK: - Receipt Divider

struct ReceiptDivider: View {
    var body: some View {
        ThermalDashedLine()
            .stroke(Color.brown.opacity(0.3), style: StrokeStyle(lineWidth: 1, dash: [4, 3]))
            .frame(height: 1)
    }
}
