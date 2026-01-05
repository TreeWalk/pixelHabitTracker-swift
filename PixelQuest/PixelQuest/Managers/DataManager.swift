import Foundation
import SwiftData

@MainActor
class DataManager {
    static let shared = DataManager()
    
    // MARK: - Quest 默认数据
    static let defaultQuests: [(title: String, xp: Int, type: String)] = [
        ("Drink Water", 50, "health"),
        ("Read Book", 100, "intellect"),
        ("Exercise", 150, "strength"),
        ("Meditate", 50, "spirit"),
        ("Code", 200, "skill"),
        ("Walk Dog", 75, "strength")
    ]
    
    // MARK: - Wallet 默认数据
    static let defaultWallets: [(name: String, icon: String, color: String, order: Int)] = [
        ("现金", "banknote.fill", "PixelGreen", 0),
        ("银行卡", "creditcard.fill", "PixelBlue", 1),
        ("微信", "message.fill", "PixelGreen", 2),
        ("支付宝", "bolt.circle.fill", "PixelBlue", 3)
    ]
    
    // MARK: - 初始化默认数据
    func initializeDefaultData(modelContext: ModelContext) {
        // 检查是否需要初始化 Quest
        let questDescriptor = FetchDescriptor<QuestData>()
        if let count = try? modelContext.fetchCount(questDescriptor), count == 0 {
            for quest in Self.defaultQuests {
                let questData = QuestData(title: quest.title, xp: quest.xp, type: quest.type)
                modelContext.insert(questData)
            }
        }
        
        // 检查是否需要初始化 Wallet
        let walletDescriptor = FetchDescriptor<WalletData>()
        if let count = try? modelContext.fetchCount(walletDescriptor), count == 0 {
            for wallet in Self.defaultWallets {
                let walletData = WalletData(name: wallet.name, icon: wallet.icon, color: wallet.color, order: wallet.order)
                modelContext.insert(walletData)
            }
        }
        
        try? modelContext.save()
    }
}
