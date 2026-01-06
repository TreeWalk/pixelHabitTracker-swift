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
                    // 热敏小票样式显示结果
                    ScrollView {
                        AssetUpdateReceipt(
                            oldSnapshot: oldSnapshot,
                            newSnapshot: new,
                            assets: financeStore.assets,
                            onDismiss: { dismiss() }
                        )
                        .padding()
                    }
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
        oldSnapshot = financeStore.latestAssetSnapshot
        
        for asset in financeStore.assets {
            if let balanceStr = assetBalances[asset.assetId],
               let value = Double(balanceStr) {
                financeStore.updateAsset(asset, balance: Int(value * 100))
            }
        }
        
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

// MARK: - Asset Update Receipt

struct AssetUpdateReceipt: View {
    let oldSnapshot: AssetSnapshotData?
    let newSnapshot: AssetSnapshotData
    let assets: [AssetData]
    let onDismiss: () -> Void
    
    @State private var showContent = false
    
    var body: some View {
        ThermalReceiptView(
            ticketNo: String(newSnapshot.snapshotId.uuidString.prefix(6)).uppercased(),
            date: newSnapshot.date,
            title: "asset_update".localized
        ) {
            if showContent {
                VStack(spacing: 12) {
                    // 资产变化列表
                    ForEach(assets) { asset in
                        assetChangeRow(asset: asset)
                    }
                    
                    ReceiptDivider()
                    
                    // 总计
                    ReceiptRow(
                        label: "asset_total_assets".localized,
                        value: "¥\(newSnapshot.formattedTotalAssets)",
                        valueColor: Color("PixelGreen"),
                        isBold: true
                    )
                    
                    ReceiptRow(
                        label: "asset_total_liabilities".localized,
                        value: "¥\(newSnapshot.formattedTotalLiabilities)",
                        valueColor: Color("PixelRed"),
                        isBold: true
                    )
                    
                    ReceiptDivider()
                    
                    // 净资产
                    HStack {
                        Text("asset_net_worth".localized)
                            .font(.pixel(20))
                            .foregroundColor(Color(red: 0.3, green: 0.25, blue: 0.2))
                        Spacer()
                        Text("¥\(newSnapshot.formattedNetWorth)")
                            .font(.pixel(24))
                            .fontWeight(.bold)
                            .foregroundColor(Color("PixelBlue"))
                    }
                    .padding(.vertical, 8)
                    
                    // 完成按钮
                    Button(action: onDismiss) {
                        Text("done".localized)
                            .font(.pixel(18))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color("PixelBlue"))
                            .pixelBorderSmall(color: Color("PixelBlue"))
                    }
                    .padding(.top, 8)
                }
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation(.easeOut(duration: 0.5)) {
                    showContent = true
                }
            }
        }
    }
    
    @ViewBuilder
    private func assetChangeRow(asset: AssetData) -> some View {
        let newBalance = newSnapshot.balance(for: asset.assetId)
        let oldBalance = oldSnapshot?.balance(for: asset.assetId) ?? 0
        let change = newBalance - oldBalance
        
        VStack(spacing: 4) {
            HStack {
                Image(systemName: asset.icon)
                    .font(.system(size: 14))
                    .foregroundColor(Color(asset.color))
                Text(asset.displayName)
                    .font(.pixel(14))
                    .foregroundColor(Color(red: 0.3, green: 0.25, blue: 0.2))
                Spacer()
            }
            
            HStack {
                Text("¥\(String(format: "%.2f", Double(oldBalance) / 100.0))")
                    .font(.pixel(12))
                    .foregroundColor(.secondary)
                
                Image(systemName: "arrow.right")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
                
                Text("¥\(String(format: "%.2f", Double(newBalance) / 100.0))")
                    .font(.pixel(14))
                    .foregroundColor(Color(red: 0.3, green: 0.25, blue: 0.2))
                
                Spacer()
                
                if change != 0 {
                    Text("\(change >= 0 ? "+" : "")¥\(String(format: "%.2f", Double(change) / 100.0))")
                        .font(.pixel(12))
                        .foregroundColor(change >= 0 ? Color("PixelGreen") : Color("PixelRed"))
                }
            }
        }
        .padding(.vertical, 4)
    }
}
