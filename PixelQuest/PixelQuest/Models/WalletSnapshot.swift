import Foundation

struct WalletSnapshot: Identifiable, Codable, Hashable {
    let id: UUID
    var date: Date                      // 快照时间
    var balances: [String: Int]         // 钱包ID → 余额（分）
    var userId: UUID?
    
    enum CodingKeys: String, CodingKey {
        case id, date, balances
        case userId = "user_id"
    }
    
    init(id: UUID = UUID(), date: Date = Date(), balances: [String: Int] = [:], userId: UUID? = nil) {
        self.id = id
        self.date = date
        self.balances = balances
        self.userId = userId
    }
    
    // 总余额
    var totalBalance: Int {
        balances.values.reduce(0, +)
    }
    
    // 格式化总余额
    var formattedTotalBalance: String {
        let yuan = Double(totalBalance) / 100.0
        return String(format: "%.2f", yuan)
    }
    
    // 获取特定钱包余额
    func balance(for walletId: UUID) -> Int {
        balances[walletId.uuidString] ?? 0
    }
    
    // 格式化特定钱包余额
    func formattedBalance(for walletId: UUID) -> String {
        let balance = balance(for: walletId)
        let yuan = Double(balance) / 100.0
        return String(format: "%.2f", yuan)
    }
}
