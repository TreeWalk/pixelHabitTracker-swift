import Foundation
import SwiftData

@Model
class AssetData {
    @Attribute(.unique) var assetId: UUID
    var name: String
    var icon: String
    var color: String
    var type: String  // "current", "investment", "liability"
    var order: Int
    var currentBalance: Int  // 以分为单位
    var lastUpdated: Date
    
    init(name: String, icon: String, color: String, type: String, order: Int, currentBalance: Int = 0) {
        self.assetId = UUID()
        self.name = name
        self.icon = icon
        self.color = color
        self.type = type
        self.order = order
        self.currentBalance = currentBalance
        self.lastUpdated = Date()
    }
    
    var displayName: String {
        switch name {
        case "现金": return "wallet_cash".localized
        case "银行卡": return "wallet_bank".localized
        case "微信": return "wallet_wechat".localized
        case "支付宝": return "wallet_alipay".localized
        case "股票": return "asset_stocks".localized
        case "基金": return "asset_funds".localized
        case "定期存款": return "asset_fixed_deposit".localized
        case "信用卡": return "asset_credit_card".localized
        case "贷款": return "asset_loan".localized
        default: return name
        }
    }
    
    var isLiability: Bool {
        type == "liability"
    }
    
    var formattedBalance: String {
        let yuan = Double(abs(currentBalance)) / 100.0
        let sign = isLiability ? "-" : ""
        return String(format: "%@%.2f", sign, yuan)
    }
}

@Model
class AssetSnapshotData {
    @Attribute(.unique) var snapshotId: UUID
    var date: Date
    var balances: [String: Int]  // assetId.uuidString -> balance
    var totalAssets: Int
    var totalLiabilities: Int
    var netWorth: Int
    
    init(balances: [String: Int] = [:], totalAssets: Int = 0, totalLiabilities: Int = 0) {
        self.snapshotId = UUID()
        self.date = Date()
        self.balances = balances
        self.totalAssets = totalAssets
        self.totalLiabilities = totalLiabilities
        self.netWorth = totalAssets - totalLiabilities
    }
    
    func balance(for assetId: UUID) -> Int {
        balances[assetId.uuidString] ?? 0
    }
    
    func formattedBalance(for assetId: UUID) -> String {
        let balance = self.balance(for: assetId)
        return String(format: "%.2f", Double(balance) / 100.0)
    }
    
    var formattedTotalAssets: String {
        String(format: "%.2f", Double(totalAssets) / 100.0)
    }
    
    var formattedTotalLiabilities: String {
        String(format: "%.2f", Double(totalLiabilities) / 100.0)
    }
    
    var formattedNetWorth: String {
        String(format: "%.2f", Double(netWorth) / 100.0)
    }
}
