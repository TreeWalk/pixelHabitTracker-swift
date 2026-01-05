import SwiftUI

struct ReconcileSheet: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var financeStore: SwiftDataFinanceStore
    
    @State private var walletBalances: [UUID: String] = [:]
    @State private var showResult = false
    @State private var reconcileResult: (actual: Int, recorded: Int, diff: Int)?
    @State private var oldSnapshot: WalletSnapshotData?
    @State private var newSnapshot: WalletSnapshotData?
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color("PixelBg").ignoresSafeArea()
                
                if showResult, let result = reconcileResult, let newSnap = newSnapshot {
                    // POS 发票样式结果
                    POSReceiptView(
                        oldSnapshot: oldSnapshot,
                        newSnapshot: newSnap,
                        result: result,
                        wallets: financeStore.wallets,
                        onDismiss: {
                            dismiss()
                        }
                    )
                } else {
                    // 输入余额界面
                    ScrollView {
                        VStack(spacing: 16) {
                            Text("reconcile_enter_balance".localized)
                                .font(.pixel(18))
                                .foregroundColor(Color("PixelBorder"))
                                .padding(.top)
                            
                            ForEach(financeStore.wallets) { wallet in
                                WalletBalanceInput(
                                    wallet: wallet,
                                    balance: Binding(
                                        get: { walletBalances[wallet.walletId] ?? "" },
                                        set: { walletBalances[wallet.walletId] = $0 }
                                    ),
                                    currentBalance: financeStore.latestSnapshot?.balance(for: wallet.walletId) ?? 0
                                )
                            }
                            
                            // 新总额
                            if !walletBalances.isEmpty {
                                HStack {
                                    Text("reconcile_new_total".localized + ":")
                                        .font(.pixel(16))
                                    Spacer()
                                    Text("¥\(calculateNewTotal())")
                                        .font(.pixel(20))
                                        .foregroundColor(Color("PixelAccent"))
                                }
                                .padding()
                                .background(Color.white)
                                .pixelBorderSmall()
                            }
                            
                            // 确认按钮
                            Button(action: performReconcile) {
                                Text("reconcile_confirm".localized)
                                    .font(.pixel(20))
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                                    .background(Color("PixelBlue"))
                                    .pixelBorderSmall(color: Color("PixelBlue"))
                            }
                            .disabled(!isValid())
                            .opacity(isValid() ? 1 : 0.5)
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("reconcile_title".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if !showResult {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("cancel".localized) {
                            dismiss()
                        }
                        .font(.pixel(16))
                    }
                }
            }
        }
        .onAppear {
            // 预填充当前余额
            for wallet in financeStore.wallets {
                let current = financeStore.latestSnapshot?.balance(for: wallet.walletId) ?? 0
                walletBalances[wallet.walletId] = String(format: "%.2f", Double(current) / 100.0)
            }
        }
    }
    
    private func calculateNewTotal() -> String {
        var total = 0
        for (_, balanceStr) in walletBalances {
            if let value = Double(balanceStr) {
                total += Int(value * 100)
            }
        }
        return String(format: "%.2f", Double(total) / 100.0)
    }
    
    private func isValid() -> Bool {
        for wallet in financeStore.wallets {
            guard let balanceStr = walletBalances[wallet.walletId],
                  let _ = Double(balanceStr) else {
                return false
            }
        }
        return true
    }
    
    private func performReconcile() {
        var balances: [String: Int] = [:]
        for wallet in financeStore.wallets {
            if let balanceStr = walletBalances[wallet.walletId],
               let value = Double(balanceStr) {
                balances[wallet.walletId.uuidString] = Int(value * 100)
            }
        }
        
        oldSnapshot = financeStore.latestSnapshot
        financeStore.createSnapshot(balances: balances)
        newSnapshot = financeStore.latestSnapshot
        
        if let newSnap = newSnapshot {
            reconcileResult = financeStore.calculateDifference(from: oldSnapshot, to: newSnap)
            
            withAnimation {
                showResult = true
            }
        }
    }
}

// MARK: - Wallet Balance Input

struct WalletBalanceInput: View {
    let wallet: WalletData
    @Binding var balance: String
    let currentBalance: Int
    
    var body: some View {
        HStack {
            Image(systemName: wallet.icon)
                .font(.system(size: 20))
                .foregroundColor(Color(wallet.color))
            
            Text(wallet.displayName)
                .font(.pixel(16))
                .foregroundColor(Color("PixelBorder"))
            
            Spacer()
            
            TextField("0.00", text: $balance)
                .font(.pixel(18))
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .frame(width: 120)
        }
        .padding(12)
        .background(Color.white)
        .pixelBorderSmall()
    }
}

// MARK: - POS Receipt View

struct POSReceiptView: View {
    let oldSnapshot: WalletSnapshotData?
    let newSnapshot: WalletSnapshotData
    let result: (actual: Int, recorded: Int, diff: Int)
    let wallets: [WalletData]
    let onDismiss: () -> Void
    
    @State private var printedLines: Int = 0
    @State private var isPrinting = true
    
    // 计算总行数
    private var totalLines: Int {
        var lines = 8 // 顶部区域（PIXEL QUEST + 日期 + 虚线 + 序列号 + 分隔线）
        lines += wallets.count
        lines += 1 // 分隔线
        lines += oldSnapshot != nil ? 2 : 1 // 新旧总额
        lines += 1 // 双线
        lines += 2 // 实际变化 + 记录变化
        lines += 1 // 分隔线
        lines += 3 // 差值标题 + 金额 + 状态
        lines += 1 // 分隔线
        lines += 3 // 底部信息 + 撕纸线
        return lines
    }
    
    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 0) {
                    // POS 发票样式
                    VStack(spacing: 0) {
                        // 顶部 Header - 左右布局
                        PrintableLine(index: 0, currentLine: printedLines) {
                            HStack(alignment: .top) {
                                Text("PIXEL\nQUEST")
                                    .font(.system(size: 20, weight: .bold, design: .monospaced))
                                    .foregroundColor(Color("PixelBorder"))
                                    .multilineTextAlignment(.leading)
                                
                                Spacer()
                                
                                VStack(alignment: .trailing, spacing: 2) {
                                    Text(formatDate(newSnapshot.date))
                                        .font(.system(size: 11, design: .monospaced))
                                    Text(formatTime(newSnapshot.date))
                                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                                }
                                .foregroundColor(.secondary)
                            }
                            .padding(.top, 12)
                        }
                        
                        PrintableLine(index: 1, currentLine: printedLines) {
                            Text("reconcile_receipt_title".localized)
                                .font(.pixel(13))
                                .foregroundColor(.secondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.top, 4)
                        }
                        
                        // 序列号
                        PrintableLine(index: 2, currentLine: printedLines) {
                            Text("NO: \(formatSerialNumber())")
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundColor(.secondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.top, 2)
                        }
                        
                        // 虚线分隔
                        PrintableLine(index: 3, currentLine: printedLines) {
                            DottedLine()
                                .padding(.vertical, 8)
                        }
                        
                        // 各钱包余额
                        ForEach(Array(wallets.enumerated()), id: \.element.id) { idx, wallet in
                            PrintableLine(index: 4 + idx, currentLine: printedLines) {
                                HStack(spacing: 6) {
                                    Image(systemName: wallet.icon)
                                        .font(.system(size: 14))
                                        .foregroundColor(Color(wallet.color))
                                        .frame(width: 20)
                                    
                                    Text(wallet.displayName)
                                        .font(.pixel(14))
                                        .foregroundColor(Color("PixelBorder"))
                                    
                                    Spacer()
                                    
                                    Text("¥\(newSnapshot.formattedBalance(for: wallet.walletId))")
                                        .font(.system(size: 14, design: .monospaced))
                                        .foregroundColor(Color("PixelBorder"))
                                }
                                .padding(.vertical, 4)
                            }
                        }
                        
                        let walletEndIndex = 4 + wallets.count
                        
                        PrintableLine(index: walletEndIndex, currentLine: printedLines) {
                            SolidLine()
                                .padding(.vertical, 6)
                        }
                        
                        PrintableLine(index: walletEndIndex + 1, currentLine: printedLines) {
                            HStack {
                                Text("reconcile_new_balance".localized)
                                    .font(.pixel(15))
                                    .foregroundColor(Color("PixelBorder"))
                                Spacer()
                                Text("¥\(newSnapshot.formattedTotalBalance)")
                                    .font(.system(size: 18, weight: .bold, design: .monospaced))
                                    .foregroundColor(Color("PixelAccent"))
                            }
                            .padding(.vertical, 4)
                        }
                        
                        if let old = oldSnapshot {
                            PrintableLine(index: walletEndIndex + 2, currentLine: printedLines) {
                                HStack {
                                    Text("reconcile_old_balance".localized)
                                        .font(.pixel(14))
                                        .foregroundColor(.secondary)
                                    Spacer()
                                    Text("¥\(old.formattedTotalBalance)")
                                        .font(.system(size: 15, design: .monospaced))
                                        .foregroundColor(.secondary)
                                }
                                .padding(.vertical, 4)
                            }
                        }
                        
                        let doubleLineIndex = walletEndIndex + (oldSnapshot != nil ? 3 : 2)
                        
                        PrintableLine(index: doubleLineIndex, currentLine: printedLines) {
                            DoubleLine()
                                .padding(.vertical, 6)
                        }
                        
                        PrintableLine(index: doubleLineIndex + 1, currentLine: printedLines) {
                            HStack {
                                Text("reconcile_actual_change".localized)
                                    .font(.pixel(14))
                                Spacer()
                                Text(formatAmount(result.actual, showSign: true))
                                    .font(.system(size: 15, weight: .semibold, design: .monospaced))
                                    .foregroundColor(result.actual >= 0 ? Color("PixelGreen") : Color("PixelRed"))
                            }
                            .padding(.vertical, 4)
                        }
                        
                        PrintableLine(index: doubleLineIndex + 2, currentLine: printedLines) {
                            HStack {
                                Text("reconcile_recorded_change".localized)
                                    .font(.pixel(14))
                                Spacer()
                                Text(formatAmount(result.recorded, showSign: true))
                                    .font(.system(size: 15, weight: .semibold, design: .monospaced))
                                    .foregroundColor(result.recorded >= 0 ? Color("PixelGreen") : Color("PixelRed"))
                            }
                            .padding(.vertical, 4)
                        }
                        
                        PrintableLine(index: doubleLineIndex + 3, currentLine: printedLines) {
                            SolidLine()
                                .padding(.vertical, 6)
                        }
                        
                        // 差值高亮区域
                        PrintableLine(index: doubleLineIndex + 4, currentLine: printedLines) {
                            VStack(spacing: 8) {
                                Text("reconcile_difference".localized)
                                    .font(.pixel(13))
                                    .foregroundColor(.secondary)
                                
                                Text(formatAmount(abs(result.diff), showSign: false))
                                    .font(.system(size: 32, weight: .bold, design: .monospaced))
                                    .foregroundColor(result.diff == 0 ? Color("PixelGreen") : Color("PixelRed"))
                                
                                HStack(spacing: 6) {
                                    if result.diff == 0 {
                                        Image(systemName: "checkmark.circle.fill")
                                            .font(.system(size: 16))
                                            .foregroundColor(Color("PixelGreen"))
                                        Text("reconcile_matched".localized)
                                            .font(.pixel(15))
                                            .foregroundColor(Color("PixelGreen"))
                                    } else {
                                        Image(systemName: "exclamationmark.triangle.fill")
                                            .font(.system(size: 16))
                                            .foregroundColor(Color("PixelRed"))
                                        Text("reconcile_discrepancy".localized)
                                            .font(.pixel(15))
                                            .foregroundColor(Color("PixelRed"))
                                    }
                                }
                            }
                            .padding(.vertical, 12)
                            .frame(maxWidth: .infinity)
                            .background(
                                (result.diff == 0 ? Color("PixelGreen") : Color("PixelRed"))
                                    .opacity(0.08)
                            )
                        }
                        
                        PrintableLine(index: doubleLineIndex + 5, currentLine: printedLines) {
                            SolidLine()
                                .padding(.vertical, 6)
                        }
                        
                        PrintableLine(index: doubleLineIndex + 6, currentLine: printedLines) {
                            Text("reconcile_thank_you".localized)
                                .font(.pixel(12))
                                .foregroundColor(Color("PixelBorder"))
                                .padding(.top, 6)
                        }
                        
                        PrintableLine(index: doubleLineIndex + 7, currentLine: printedLines) {
                            Text("reconcile_slogan".localized)
                                .font(.system(size: 10, design: .monospaced))
                                .foregroundColor(.secondary)
                                .italic()
                                .padding(.vertical, 4)
                        }
                        
                        PrintableLine(index: doubleLineIndex + 8, currentLine: printedLines) {
                            Text("reconcile_tear_here".localized)
                                .font(.system(size: 9, weight: .medium, design: .monospaced))
                                .foregroundColor(.secondary)
                                .tracking(2)
                                .padding(.top, 8)
                                .padding(.bottom, 4)
                        }
                        
                        // 撕纸边缘效果
                        if printedLines >= totalLines {
                            TornPaperEdge()
                                .transition(.move(edge: .top).combined(with: .opacity))
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 16)
                    .background(
                        ZStack {
                            Color.white
                            
                            // 轻微边框
                            RoundedRectangle(cornerRadius: 0)
                                .strokeBorder(Color("PixelBorder").opacity(0.15), lineWidth: 1)
                        }
                    )
                    .padding(20)
                }
            }
            
            // 知道了按钮
            Button(action: onDismiss) {
                Text("reconcile_got_it".localized)
                    .font(.pixel(20))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color("PixelAccent"))
                    .pixelBorderSmall(color: Color("PixelAccent"))
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
            .opacity(printedLines >= totalLines ? 1 : 0.5)
            .disabled(printedLines < totalLines)
        }
        .background(Color("PixelBg"))
        .onAppear {
            startPrinting()
        }
    }
    
    private func formatSerialNumber() -> String {
        let timestamp = Int(newSnapshot.date.timeIntervalSince1970)
        return String(format: "%06d", timestamp % 1000000)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yy"
        return formatter.string(from: date)
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
    
    private func startPrinting() {
        printedLines = 0
        isPrinting = true
        
        // 逐行打印动画
        for i in 0...totalLines {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.08) {
                withAnimation(.easeOut(duration: 0.1)) {
                    printedLines = i
                }
                
                // 打印音效（轻微震动）
                if i < totalLines {
                    let generator = UIImpactFeedbackGenerator(style: .light)
                    generator.impactOccurred(intensity: 0.3)
                }
                
                if i == totalLines {
                    isPrinting = false
                    // 打印完成，稍重的震动
                    let generator = UIImpactFeedbackGenerator(style: .medium)
                    generator.impactOccurred()
                }
            }
        }
    }
    
    private func formatAmount(_ amount: Int, showSign: Bool) -> String {
        let yuan = Double(amount) / 100.0
        if showSign {
            return String(format: amount >= 0 ? "+¥%.2f" : "-¥%.2f", abs(yuan))
        }
        return String(format: "¥%.2f", yuan)
    }
}

// MARK: - Printable Line

struct PrintableLine<Content: View>: View {
    let index: Int
    let currentLine: Int
    let content: () -> Content
    
    var body: some View {
        if index <= currentLine {
            content()
                .transition(.asymmetric(
                    insertion: .move(edge: .top).combined(with: .opacity),
                    removal: .opacity
                ))
        }
    }
}

// MARK: - Torn Paper Edge

struct TornPaperEdge: View {
    var body: some View {
        VStack(spacing: 0) {
            // 撕纸锯齿边缘
            HStack(spacing: 0) {
                ForEach(0..<20, id: \.self) { _ in
                    ZigzagShape()
                        .fill(Color("PixelBorder").opacity(0.3))
                        .frame(width: 12, height: 8)
                }
            }
            
            // 撕痕效果
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color("PixelBorder").opacity(0.1),
                            Color.clear
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(height: 4)
        }
    }
}

// MARK: - Zigzag Shape

struct ZigzagShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: 0, y: 0))
        path.addLine(to: CGPoint(x: rect.width / 2, y: rect.height))
        path.addLine(to: CGPoint(x: rect.width, y: 0))
        return path
    }
}

// MARK: - Dashed Line

struct DashedLine: View {
    var body: some View {
        Text("─────────────────────")
            .font(.pixel(12))
            .foregroundColor(.secondary)
            .padding(.vertical, 4)
    }
}

// MARK: - Dotted Line

struct DottedLine: View {
    var body: some View {
        HStack(spacing: 2) {
            ForEach(0..<40, id: \.self) { _ in
                Circle()
                    .fill(Color("PixelBorder").opacity(0.3))
                    .frame(width: 2, height: 2)
            }
        }
    }
}

// MARK: - Solid Line

struct SolidLine: View {
    var body: some View {
        Rectangle()
            .fill(Color("PixelBorder").opacity(0.3))
            .frame(height: 1)
    }
}

// MARK: - Double Line

struct DoubleLine: View {
    var body: some View {
        VStack(spacing: 2) {
            SolidLine()
            SolidLine()
        }
    }
}
