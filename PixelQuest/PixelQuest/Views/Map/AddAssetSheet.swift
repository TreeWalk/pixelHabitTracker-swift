import SwiftUI

struct AddAssetSheet: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var financeStore: SwiftDataFinanceStore
    
    @State private var selectedType: String = "current"
    @State private var name: String = ""
    @State private var selectedIcon: String = "banknote.fill"
    @State private var selectedColor: String = "PixelGreen"
    @State private var balanceText: String = ""
    
    let assetTypes = [
        ("current", "asset_current", "banknote.fill", "PixelGreen"),
        ("investment", "asset_investment", "chart.line.uptrend.xyaxis", "PixelBlue"),
        ("liability", "asset_liability", "creditcard.fill", "PixelRed")
    ]
    
    let presetAssets: [(type: String, name: String, icon: String, color: String)] = [
        ("current", "现金", "banknote.fill", "PixelGreen"),
        ("current", "银行卡", "creditcard.fill", "PixelBlue"),
        ("current", "微信", "message.fill", "PixelGreen"),
        ("current", "支付宝", "bolt.circle.fill", "PixelBlue"),
        ("investment", "股票", "chart.line.uptrend.xyaxis", "PixelBlue"),
        ("investment", "基金", "chart.pie.fill", "PixelGreen"),
        ("investment", "定期存款", "building.columns.fill", "PixelAccent"),
        ("liability", "信用卡", "creditcard.fill", "PixelRed"),
        ("liability", "贷款", "dollarsign.circle.fill", "PixelRed")
    ]
    
    var filteredPresets: [(type: String, name: String, icon: String, color: String)] {
        presetAssets.filter { $0.type == selectedType }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color("PixelBg").ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // 类型选择
                        VStack(alignment: .leading, spacing: 8) {
                            Text("asset_type".localized)
                                .font(.pixel(14))
                                .foregroundColor(Color("PixelBorder").opacity(0.7))
                            
                            HStack(spacing: 10) {
                                ForEach(assetTypes, id: \.0) { type in
                                    Button(action: {
                                        selectedType = type.0
                                        selectedIcon = type.2
                                        selectedColor = type.3
                                    }) {
                                        VStack(spacing: 6) {
                                            Image(systemName: type.2)
                                                .font(.system(size: 20))
                                            Text(type.1.localized)
                                                .font(.pixel(12))
                                        }
                                        .foregroundColor(selectedType == type.0 ? .white : Color("PixelBorder"))
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 12)
                                        .background(selectedType == type.0 ? Color(type.3) : Color.white)
                                        .pixelBorderSmall(color: selectedType == type.0 ? Color(type.3) : Color("PixelBorder"))
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        
                        // 预设选项
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Presets")
                                .font(.pixel(14))
                                .foregroundColor(Color("PixelBorder").opacity(0.7))
                                .padding(.horizontal, 16)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 10) {
                                    ForEach(filteredPresets, id: \.name) { preset in
                                        Button(action: {
                                            name = preset.name
                                            selectedIcon = preset.icon
                                            selectedColor = preset.color
                                        }) {
                                            VStack(spacing: 4) {
                                                Image(systemName: preset.icon)
                                                    .font(.system(size: 24))
                                                    .foregroundColor(Color(preset.color))
                                                Text(preset.name)
                                                    .font(.pixel(10))
                                                    .foregroundColor(Color("PixelBorder"))
                                            }
                                            .frame(width: 70, height: 70)
                                            .background(Color.white)
                                            .pixelBorderSmall()
                                        }
                                    }
                                }
                                .padding(.horizontal, 16)
                            }
                        }
                        
                        // 自定义名称
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Name")
                                .font(.pixel(14))
                                .foregroundColor(Color("PixelBorder").opacity(0.7))
                            
                            TextField("Enter asset name", text: $name)
                                .font(.pixel(16))
                                .padding(12)
                                .background(Color.white)
                                .pixelBorderSmall()
                        }
                        .padding(.horizontal, 16)
                        
                        // 初始余额
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Initial Balance")
                                .font(.pixel(14))
                                .foregroundColor(Color("PixelBorder").opacity(0.7))
                            
                            TextField("0.00", text: $balanceText)
                                .font(.pixel(16))
                                .keyboardType(.decimalPad)
                                .padding(12)
                                .background(Color.white)
                                .pixelBorderSmall()
                        }
                        .padding(.horizontal, 16)
                        
                        // 添加按钮
                        Button(action: addAsset) {
                            Text("asset_add".localized)
                                .font(.pixel(20))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(Color("PixelBlue"))
                                .pixelBorderSmall(color: Color("PixelBlue"))
                        }
                        .disabled(!isValid())
                        .opacity(isValid() ? 1 : 0.5)
                        .padding(.horizontal, 16)
                    }
                    .padding(.vertical, 16)
                }
            }
            .navigationTitle("asset_add".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
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
    
    private func isValid() -> Bool {
        !name.isEmpty && Double(balanceText) != nil
    }
    
    private func addAsset() {
        guard let balance = Double(balanceText) else { return }
        let balanceInCents = Int(balance * 100)
        
        financeStore.addAsset(
            name: name,
            icon: selectedIcon,
            color: selectedColor,
            type: selectedType,
            balance: balanceInCents
        )
        
        dismiss()
    }
}

struct EditAssetSheet: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var financeStore: SwiftDataFinanceStore
    let asset: AssetData
    
    @State private var balanceText: String = ""
    @State private var showDeleteConfirm = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color("PixelBg").ignoresSafeArea()
                
                VStack(spacing: 20) {
                    // 资产信息
                    VStack(spacing: 12) {
                        Image(systemName: asset.icon)
                            .font(.system(size: 48))
                            .foregroundColor(Color(asset.color))
                        
                        Text(asset.displayName)
                            .font(.pixel(24))
                            .foregroundColor(Color("PixelBorder"))
                        
                        Text("Current: ¥\(asset.formattedBalance)")
                            .font(.pixel(16))
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.white)
                    .pixelBorderSmall()
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                    
                    // 更新余额
                    VStack(alignment: .leading, spacing: 8) {
                        Text("New Balance")
                            .font(.pixel(14))
                            .foregroundColor(Color("PixelBorder").opacity(0.7))
                        
                        TextField("0.00", text: $balanceText)
                            .font(.pixel(16))
                            .keyboardType(.decimalPad)
                            .padding(12)
                            .background(Color.white)
                            .pixelBorderSmall()
                    }
                    .padding(.horizontal, 16)
                    
                    // 更新按钮
                    Button(action: updateBalance) {
                        Text("Update")
                            .font(.pixel(20))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color("PixelBlue"))
                            .pixelBorderSmall(color: Color("PixelBlue"))
                    }
                    .disabled(balanceText.isEmpty || Double(balanceText) == nil)
                    .opacity(balanceText.isEmpty || Double(balanceText) == nil ? 0.5 : 1)
                    .padding(.horizontal, 16)
                    
                    Spacer()
                    
                    // 删除按钮
                    Button(action: { showDeleteConfirm = true }) {
                        Text("Delete Asset")
                            .font(.pixel(16))
                            .foregroundColor(Color("PixelRed"))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color.white)
                            .pixelBorderSmall(color: Color("PixelRed"))
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)
                }
            }
            .navigationTitle(asset.displayName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("cancel".localized) {
                        dismiss()
                    }
                    .font(.pixel(16))
                    .foregroundColor(Color("PixelBorder"))
                }
            }
            .alert("Delete Asset?", isPresented: $showDeleteConfirm) {
                Button("cancel".localized, role: .cancel) {}
                Button("delete".localized, role: .destructive) {
                    financeStore.deleteAsset(asset)
                    dismiss()
                }
            }
        }
        .onAppear {
            balanceText = String(format: "%.2f", Double(asset.currentBalance) / 100.0)
        }
    }
    
    private func updateBalance() {
        guard let balance = Double(balanceText) else { return }
        let balanceInCents = Int(balance * 100)
        financeStore.updateAsset(asset, balance: balanceInCents)
        dismiss()
    }
}
