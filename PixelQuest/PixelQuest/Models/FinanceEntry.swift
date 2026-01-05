import Foundation

enum FinanceType: String, Codable, CaseIterable {
    case income = "income"
    case expense = "expense"
    case transfer = "transfer"
    
    var displayName: String {
        switch self {
        case .income: return "收入"
        case .expense: return "支出"
        case .transfer: return "转账"
        }
    }
}

struct FinanceCategory: Identifiable, Hashable {
    let id: String
    let name: String
    let icon: String
    let type: FinanceType
    
    static let incomeCategories: [FinanceCategory] = [
        FinanceCategory(id: "salary", name: "工资", icon: "briefcase.fill", type: .income),
        FinanceCategory(id: "bonus", name: "奖金", icon: "star.fill", type: .income),
        FinanceCategory(id: "investment", name: "投资", icon: "chart.line.uptrend.xyaxis", type: .income),
        FinanceCategory(id: "gift_in", name: "礼金", icon: "gift.fill", type: .income),
        FinanceCategory(id: "refund", name: "退款", icon: "arrow.uturn.backward.circle.fill", type: .income),
        FinanceCategory(id: "other_in", name: "其他", icon: "ellipsis.circle.fill", type: .income),
    ]
    
    static let expenseCategories: [FinanceCategory] = [
        FinanceCategory(id: "food", name: "餐饮", icon: "fork.knife", type: .expense),
        FinanceCategory(id: "transport", name: "交通", icon: "car.fill", type: .expense),
        FinanceCategory(id: "shopping", name: "购物", icon: "cart.fill", type: .expense),
        FinanceCategory(id: "entertainment", name: "娱乐", icon: "gamecontroller.fill", type: .expense),
        FinanceCategory(id: "bills", name: "账单", icon: "doc.text.fill", type: .expense),
        FinanceCategory(id: "health", name: "医疗", icon: "cross.case.fill", type: .expense),
        FinanceCategory(id: "education", name: "学习", icon: "book.fill", type: .expense),
        FinanceCategory(id: "gift_out", name: "礼物", icon: "gift.fill", type: .expense),
        FinanceCategory(id: "other_out", name: "其他", icon: "ellipsis.circle.fill", type: .expense),
    ]
    
    static func categories(for type: FinanceType) -> [FinanceCategory] {
        switch type {
        case .income: return incomeCategories
        case .expense: return expenseCategories
        case .transfer: return []
        }
    }
}

struct FinanceEntry: Identifiable, Codable, Hashable {
    let id: UUID
    var amount: Int           // 金额（分），正数
    var type: FinanceType     // 类型
    var category: String      // 分类ID
    var note: String?         // 备注
    var date: Date            // 日期
    var userId: UUID?
    
    enum CodingKeys: String, CodingKey {
        case id, amount, type, category, note, date
        case userId = "user_id"
    }
    
    // 格式化金额显示
    var formattedAmount: String {
        let yuan = Double(amount) / 100.0
        return String(format: "%.2f", yuan)
    }
    
    // 带符号的金额
    var signedAmountText: String {
        let yuan = Double(amount) / 100.0
        switch type {
        case .income:
            return String(format: "+%.2f", yuan)
        case .expense:
            return String(format: "-%.2f", yuan)
        case .transfer:
            return String(format: "%.2f", yuan)
        }
    }
    
    // 获取分类信息
    var categoryInfo: FinanceCategory? {
        let allCategories = FinanceCategory.incomeCategories + FinanceCategory.expenseCategories
        return allCategories.first { $0.id == category }
    }
    
    // 格式化日期
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
}

// 用于插入的结构
struct InsertFinanceEntry: Codable {
    var amount: Int
    var type: String
    var category: String
    var walletId: UUID
    var toWalletId: UUID?
    var note: String?
    var date: Date
    var userId: UUID?
    
    enum CodingKeys: String, CodingKey {
        case amount, type, category, note, date
        case walletId = "wallet_id"
        case toWalletId = "to_wallet_id"
        case userId = "user_id"
    }
}
