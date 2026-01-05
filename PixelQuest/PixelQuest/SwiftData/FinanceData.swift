import Foundation
import SwiftData

@Model
final class WalletData {
    var walletId: UUID // 添加独立的 UUID 用于引用
    var name: String
    var icon: String
    var color: String
    var order: Int
    var lastUpdated: Date
    
    init(name: String, icon: String, color: String, order: Int, lastUpdated: Date = Date()) {
        self.walletId = UUID()
        self.name = name
        self.icon = icon
        self.color = color
        self.order = order
        self.lastUpdated = lastUpdated
    }
    
    // 本地化显示名称
    var displayName: String {
        switch name {
        case "现金":
            return "wallet_cash".localized
        case "银行卡":
            return "wallet_bank".localized
        case "微信":
            return "wallet_wechat".localized
        case "支付宝":
            return "wallet_alipay".localized
        default:
            return name
        }
    }
}

@Model
final class WalletSnapshotData {
    var date: Date
    var balancesJSON: String // JSON string of [walletId: balance]
    
    init(date: Date = Date(), balancesJSON: String = "{}") {
        self.date = date
        self.balancesJSON = balancesJSON
    }
    
    // Helper to get/set balances
    var balances: [String: Int] {
        get {
            guard let data = balancesJSON.data(using: .utf8),
                  let dict = try? JSONDecoder().decode([String: Int].self, from: data) else {
                return [:]
            }
            return dict
        }
        set {
            if let data = try? JSONEncoder().encode(newValue),
               let json = String(data: data, encoding: .utf8) {
                balancesJSON = json
            }
        }
    }
    
    var totalBalance: Int {
        balances.values.reduce(0, +)
    }
    
    var formattedTotalBalance: String {
        String(format: "%.2f", Double(totalBalance) / 100.0)
    }
    
    func balance(for walletId: UUID) -> Int {
        balances[walletId.uuidString] ?? 0
    }
    
    func formattedBalance(for walletId: UUID) -> String {
        String(format: "%.2f", Double(balance(for: walletId)) / 100.0)
    }
}

@Model
final class FinanceEntryData {
    var amount: Int // 分为单位
    var type: String // income, expense
    var category: String
    var note: String?
    var date: Date
    
    init(amount: Int, type: String, category: String, note: String? = nil, date: Date = Date()) {
        self.amount = amount
        self.type = type
        self.category = category
        self.note = note
        self.date = date
    }
    
    var isIncome: Bool { type == "income" }
    var isExpense: Bool { type == "expense" }
}
