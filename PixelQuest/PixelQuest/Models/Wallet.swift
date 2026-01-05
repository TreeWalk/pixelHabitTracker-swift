import Foundation

struct Wallet: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String          // 钱包名称
    var icon: String          // SF Symbol 图标名
    var color: String         // 主题色名称
    var order: Int            // 排序顺序
    var lastUpdated: Date     // 上次更新时间（用于核对）
    var userId: UUID?
    
    enum CodingKeys: String, CodingKey {
        case id, name, icon, color, order
        case lastUpdated = "last_updated"
        case userId = "user_id"
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
    
    // 默认钱包预设
    static let presets: [Wallet] = [
        Wallet(id: UUID(), name: "现金", icon: "banknote.fill", color: "PixelGreen", order: 0, lastUpdated: Date()),
        Wallet(id: UUID(), name: "银行卡", icon: "creditcard.fill", color: "PixelBlue", order: 1, lastUpdated: Date()),
        Wallet(id: UUID(), name: "微信", icon: "message.fill", color: "PixelGreen", order: 2, lastUpdated: Date()),
        Wallet(id: UUID(), name: "支付宝", icon: "bolt.circle.fill", color: "PixelBlue", order: 3, lastUpdated: Date()),
    ]
}

