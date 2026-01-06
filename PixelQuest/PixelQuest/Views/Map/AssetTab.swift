import SwiftUI

struct AssetTab: View {
    @ObservedObject var financeStore: SwiftDataFinanceStore
    let contentWidth: CGFloat
    let onAssetUpdate: () -> Void
    
    @State private var showAddAsset = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // 净资产卡片
                NetWorthCard(
                    totalAssets: financeStore.totalAssets,
                    totalLiabilities: financeStore.totalLiabilities,
                    netWorth: financeStore.netWorth,
                    lastUpdated: financeStore.latestAssetSnapshot?.date
                )
                .frame(width: contentWidth)
                .padding(.top, 16)
                
                // 资产更新按钮
                Button(action: onAssetUpdate) {
                    HStack {
                        Image(systemName: "arrow.triangle.2.circlepath")
                        Text("asset_update".localized)
                            .font(.pixel(20))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color("PixelBlue"))
                    .pixelBorderSmall(color: Color("PixelBlue"))
                }
                .frame(width: contentWidth)
                
                // 流动资金
                AssetSection(
                    title: "asset_current".localized,
                    icon: "banknote.fill",
                    color: Color("PixelGreen"),
                    assets: financeStore.assetsByType("current"),
                    contentWidth: contentWidth
                )
                
                // 投资理财
                AssetSection(
                    title: "asset_investment".localized,
                    icon: "chart.line.uptrend.xyaxis",
                    color: Color("PixelBlue"),
                    assets: financeStore.assetsByType("investment"),
                    contentWidth: contentWidth
                )
                
                // 负债
                AssetSection(
                    title: "asset_liability".localized,
                    icon: "creditcard.fill",
                    color: Color("PixelRed"),
                    assets: financeStore.assetsByType("liability"),
                    contentWidth: contentWidth
                )
                
                // 添加资产按钮
                Button(action: { showAddAsset = true }) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("asset_add".localized)
                            .font(.pixel(18))
                    }
                    .foregroundColor(Color("PixelBorder"))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color("PixelAccent"))
                    .pixelBorderSmall()
                }
                .frame(width: contentWidth)
                .padding(.bottom, 16)
            }
        }
        .sheet(isPresented: $showAddAsset) {
            AddAssetSheet()
        }
    }
}

// MARK: - Net Worth Card

struct NetWorthCard: View {
    let totalAssets: Int
    let totalLiabilities: Int
    let netWorth: Int
    let lastUpdated: Date?
    
    var body: some View {
        VStack(spacing: 12) {
            // 净资产
            VStack(spacing: 4) {
                Text("asset_net_worth".localized)
                    .font(.pixel(14))
                    .foregroundColor(Color("PixelBorder").opacity(0.7))
                Text("¥\(String(format: "%.2f", Double(netWorth) / 100.0))")
                    .font(.pixel(32))
                    .foregroundColor(Color("PixelBlue"))
            }
            
            Divider()
            
            // 总资产和总负债
            HStack(spacing: 20) {
                VStack(spacing: 4) {
                    Text("asset_total_assets".localized)
                        .font(.pixel(12))
                        .foregroundColor(.secondary)
                    Text("¥\(String(format: "%.2f", Double(totalAssets) / 100.0))")
                        .font(.pixel(18))
                        .foregroundColor(Color("PixelGreen"))
                }
                .frame(maxWidth: .infinity)
                
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 1, height: 40)
                
                VStack(spacing: 4) {
                    Text("asset_total_liabilities".localized)
                        .font(.pixel(12))
                        .foregroundColor(.secondary)
                    Text("¥\(String(format: "%.2f", Double(totalLiabilities) / 100.0))")
                        .font(.pixel(18))
                        .foregroundColor(Color("PixelRed"))
                }
                .frame(maxWidth: .infinity)
            }
            
            if let date = lastUpdated {
                Text("finance_last_reconcile".localized + ": \(formatDate(date))")
                    .font(.pixel(10))
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color.white)
        .pixelBorderSmall()
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Asset Section

struct AssetSection: View {
    let title: String
    let icon: String
    let color: Color
    let assets: [AssetData]
    let contentWidth: CGFloat
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 标题
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(color)
                Rectangle()
                    .fill(color)
                    .frame(width: 4, height: 20)
                Text(title)
                    .font(.pixel(20))
                    .foregroundColor(Color("PixelBorder"))
                Spacer()
            }
            .padding(.horizontal, 16)
            
            // 资产列表
            if assets.isEmpty {
                Text("finance_no_records".localized)
                    .font(.pixel(14))
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.white.opacity(0.5))
                    .pixelBorderSmall()
                    .padding(.horizontal, 16)
            } else {
                ForEach(assets) { asset in
                    AssetRow(asset: asset)
                        .padding(.horizontal, 16)
                }
            }
        }
    }
}

// MARK: - Asset Row

struct AssetRow: View {
    let asset: AssetData
    @EnvironmentObject var financeStore: SwiftDataFinanceStore
    @State private var showEdit = false
    
    var body: some View {
        Button(action: { showEdit = true }) {
            HStack(spacing: 12) {
                // 图标
                Image(systemName: asset.icon)
                    .font(.system(size: 20))
                    .foregroundColor(Color(asset.color))
                    .frame(width: 40, height: 40)
                    .background(Color(asset.color).opacity(0.1))
                    .pixelBorderSmall(color: Color(asset.color).opacity(0.3))
                
                // 名称
                Text(asset.displayName)
                    .font(.pixel(16))
                    .foregroundColor(Color("PixelBorder"))
                
                Spacer()
                
                // 余额
                Text("¥\(asset.formattedBalance)")
                    .font(.pixel(18))
                    .foregroundColor(asset.isLiability ? Color("PixelRed") : Color("PixelGreen"))
            }
            .padding(12)
            .background(Color.white)
            .pixelBorderSmall()
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showEdit) {
            EditAssetSheet(asset: asset)
        }
    }
}
