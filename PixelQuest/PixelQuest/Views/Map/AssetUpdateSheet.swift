import SwiftUI

struct AssetUpdateSheet: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var financeStore: SwiftDataFinanceStore
    
    @State private var assetBalances: [UUID: String] = [:]
    @State private var showResult = false
    @State private var oldSnapshot: AssetSnapshotData?
    @State private var newSnapshot: AssetSnapshotData?
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color("PixelBg").ignoresSafeArea()
                
                if showResult, let new = newSnapshot {
                    // POS 小票样式显示结果
                    AssetUpdateReceiptView(
                        oldSnapshot: oldSnapshot,
                        newSnapshot: new,
                        assets: financeStore.assets,
                        onDismiss: {
                            dismiss()
                        }
                    )
                } else {
                    // 输入界面
                    ScrollView {
                        VStack(spacing: 16) {
                            Text("asset_update_instruction".localized)
                                .font(.pixel(14))
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding()
                            
                            // 资产列表
                            ForEach(financeStore.assets) { asset in
                                AssetBalanceInput(
                                    asset: asset,
                                    balance: Binding(
                                        get: { assetBalances[asset.assetId] ?? "" },
                                        set: { assetBalances[asset.assetId] = $0 }
                                    ),
                                    currentBalance: asset.currentBalance
                                )
                                .padding(.horizontal, 16)
                            }
                            
                            // 确认按钮
                            Button(action: performUpdate) {
                                HStack {
                                    Image(systemName: "checkmark.circle.fill")
                                    Text("confirm".localized)
                                        .font(.pixel(20))
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(Color("PixelBlue"))
                                .pixelBorderSmall(color: Color("PixelBlue"))
                            }
                            .disabled(!isValid())
                            .opacity(isValid() ? 1 : 0.5)
                            .padding(.horizontal, 16)
                            .padding(.bottom, 16)
                        }
                        .padding(.top, 16)
                    }
                }
            }
            .navigationTitle("asset_update".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if !showResult {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("cancel".localized) {
                            dismiss()
                        }
                        .font(.pixel(16))
                        .foregroundColor(Color("PixelBorder"))
                    }
                }
            }
        }
        .onAppear {
            // 预填充当前余额
            for asset in financeStore.assets {
                let current = asset.currentBalance
                assetBalances[asset.assetId] = String(format: "%.2f", Double(current) / 100.0)
            }
        }
    }
    
    private func isValid() -> Bool {
        for asset in financeStore.assets {
            guard let balanceStr = assetBalances[asset.assetId],
                  let _ = Double(balanceStr) else {
                return false
            }
        }
        return true
    }
    
    private func performUpdate() {
        var balances: [String: Int] = [:]
        for asset in financeStore.assets {
            if let balanceStr = assetBalances[asset.assetId],
               let value = Double(balanceStr) {
                balances[asset.assetId.uuidString] = Int(value * 100)
                // 更新资产余额
                financeStore.updateAsset(asset, balance: Int(value * 100))
            }
        }
        
        oldSnapshot = financeStore.latestAssetSnapshot
        
        // 创建新快照
        financeStore.createAssetSnapshot()
        newSnapshot = financeStore.latestAssetSnapshot
        
        withAnimation {
            showResult = true
        }
    }
}

// MARK: - Asset Balance Input

struct AssetBalanceInput: View {
    let asset: AssetData
    @Binding var balance: String
    let currentBalance: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: asset.icon)
                    .foregroundColor(Color(asset.color))
                Text(asset.displayName)
                    .font(.pixel(16))
                    .foregroundColor(Color("PixelBorder"))
                Spacer()
                Text("Current: ¥\(String(format: "%.2f", Double(currentBalance) / 100.0))")
                    .font(.pixel(12))
                    .foregroundColor(.secondary)
            }
            
            TextField("0.00", text: $balance)
                .font(.pixel(16))
                .keyboardType(.decimalPad)
                .padding(12)
                .background(Color.white)
                .pixelBorderSmall()
        }
    }
}

// MARK: - Asset Update Receipt View

struct AssetUpdateReceiptView: View {
    let oldSnapshot: AssetSnapshotData?
    let newSnapshot: AssetSnapshotData
    let assets: [AssetData]
    let onDismiss: () -> Void
    
    @State private var printedLines: Int = 0
    private let totalLines = 20
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // POS 小票样式
                VStack(spacing: 4) {
                    // 标题
                    Text("※ \("asset_update".localized.uppercased()) ※")
                        .font(.system(size: 16, design: .monospaced))
                        .fontWeight(.bold)
                        .padding(.top, 20)
                    
                    Text(Date().formatted(date: .long, time: .shortened))
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundColor(.secondary)
                        .padding(.bottom, 10)
                    
                    Divider()
                    
                    // 资产变化列表
                    ForEach(assets) { asset in
                        let newBalance = newSnapshot.balance(for: asset.assetId)
                        let oldBalance = oldSnapshot?.balance(for: asset.assetId) ?? 0
                        let change = newBalance - oldBalance
                        
                        if printedLines >= assets.firstIndex(where: { $0.assetId == asset.assetId }) ?? 0 {
                            VStack(spacing: 4) {
                                HStack {
                                    Text(asset.displayName)
                                        .font(.system(size: 14, design: .monospaced))
                                    Spacer()
                                }
                                
                                HStack {
                                    Text("Old:")
                                        .font(.system(size: 12, design: .monospaced))
                                        .foregroundColor(.secondary)
                                    Text("¥\(String(format: "%.2f", Double(oldBalance) / 100.0))")
                                        .font(.system(size: 12, design: .monospaced))
                                    Spacer()
                                }
                                
                                HStack {
                                    Text("New:")
                                        .font(.system(size: 12, design: .monospaced))
                                        .foregroundColor(.secondary)
                                    Text("¥\(String(format: "%.2f", Double(newBalance) / 100.0))")
                                        .font(.system(size: 12, design: .monospaced))
                                        .fontWeight(.bold)
                                    Spacer()
                                }
                                
                                HStack {
                                    Text("Change:")
                                        .font(.system(size: 12, design: .monospaced))
                                        .foregroundColor(.secondary)
                                    Text("\(change >= 0 ? "+" : "")¥\(String(format: "%.2f", Double(change) / 100.0))")
                                        .font(.system(size: 12, design: .monospaced))
                                        .foregroundColor(change >= 0 ? Color("PixelGreen") : Color("PixelRed"))
                                    Spacer()
                                }
                            }
                            .padding(.vertical, 8)
                        }
                    }
                    
                    if printedLines >= assets.count {
                        Divider()
                        
                        // 总计
                        HStack {
                            Text("asset_total_assets".localized)
                                .font(.system(size: 14, design: .monospaced))
                            Spacer()
                            Text("¥\(newSnapshot.formattedTotalAssets)")
                                .font(.system(size: 14, design: .monospaced))
                                .fontWeight(.bold)
                        }
                        .padding(.vertical, 4)
                        
                        HStack {
                            Text("asset_total_liabilities".localized)
                                .font(.system(size: 14, design: .monospaced))
                            Spacer()
                            Text("¥\(newSnapshot.formattedTotalLiabilities)")
                                .font(.system(size: 14, design: .monospaced))
                                .fontWeight(.bold)
                                .foregroundColor(Color("PixelRed"))
                        }
                        .padding(.vertical, 4)
                        
                        Divider()
                        
                        HStack {
                            Text("asset_net_worth".localized)
                                .font(.system(size: 16, design: .monospaced))
                                .fontWeight(.bold)
                            Spacer()
                            Text("¥\(newSnapshot.formattedNetWorth)")
                                .font(.system(size: 16, design: .monospaced))
                                .fontWeight(.bold)
                                .foregroundColor(Color("PixelBlue"))
                        }
                        .padding(.vertical, 8)
                        
                        Divider()
                        
                        Text("reconcile_thank_you".localized)
                            .font(.system(size: 12, design: .monospaced))
                            .padding(.top, 10)
                        
                        Text("reconcile_slogan".localized)
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundColor(.secondary)
                            .padding(.bottom, 10)
                        
                        Text("reconcile_tear_here".localized)
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundColor(.secondary)
                            .padding(.vertical, 10)
                        
                        // 完成按钮
                        Button(action: onDismiss) {
                            Text("reconcile_got_it".localized)
                                .font(.pixel(20))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(Color("PixelBlue"))
                                .pixelBorderSmall(color: Color("PixelBlue"))
                        }
                        .padding(.top, 10)
                    }
                }
                .padding()
                .frame(maxWidth: 400)
                .background(Color.white)
                .pixelBorderSmall()
                .padding()
            }
        }
        .onAppear {
            animatePrint()
        }
    }
    
    private func animatePrint() {
        for i in 0...totalLines {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.05) {
                printedLines = i
            }
        }
    }
}
