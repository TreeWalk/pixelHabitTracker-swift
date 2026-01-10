import Foundation

@MainActor
class FinanceStore: ObservableObject {
    @Published var wallets: [Wallet] = []
    @Published var snapshots: [WalletSnapshot] = []
    @Published var entries: [FinanceEntry] = []
    @Published var isLoading = false
    @Published var error: String?
    
    // 上次选择的分类（记住用户习惯）
    @Published var lastExpenseCategory: String = "food"
    @Published var lastIncomeCategory: String = "salary"
    
    // MARK: - 计算属性
    
    // 最新快照
    var latestSnapshot: WalletSnapshot? {
        snapshots.sorted { $0.date > $1.date }.first
    }
    
    // 总余额（来自最新快照）
    var totalBalance: Int {
        latestSnapshot?.totalBalance ?? 0
    }
    
    // 格式化总余额
    var formattedTotalBalance: String {
        let yuan = Double(totalBalance) / 100.0
        return String(format: "%.2f", yuan)
    }
    
    // 今日记录
    var todayEntries: [FinanceEntry] {
        let calendar = Calendar.current
        return entries.filter { calendar.isDateInToday($0.date) }
            .sorted { $0.date > $1.date }
    }
    
    // 按日期分组的记录
    func entriesGroupedByDate() -> [(date: Date, entries: [FinanceEntry])] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: entries.sorted { $0.date > $1.date }) { entry in
            calendar.startOfDay(for: entry.date)
        }
        return grouped.sorted { $0.key > $1.key }.map { (date: $0.key, entries: $0.value) }
    }
    
    // 本月统计
    var monthIncome: Int {
        let calendar = Calendar.current
        let now = Date()
        guard let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: now)) else {
            return 0
        }
        return entries.filter { $0.date >= monthStart && $0.type == .income }
            .reduce(0) { $0 + $1.amount }
    }
    
    var monthExpense: Int {
        let calendar = Calendar.current
        let now = Date()
        guard let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: now)) else {
            return 0
        }
        return entries.filter { $0.date >= monthStart && $0.type == .expense }
            .reduce(0) { $0 + $1.amount }
    }
    
    var monthNet: Int {
        monthIncome - monthExpense
    }
    
    // MARK: - 初始化
    
    init() {
        // 初始化默认钱包
        if wallets.isEmpty {
            wallets = Wallet.presets
        }
    }
    
    // MARK: - 钱包操作
    
    func addWallet(name: String, icon: String, color: String) {
        let wallet = Wallet(
            id: UUID(),
            name: name,
            icon: icon,
            color: color,
            order: wallets.count,
            lastUpdated: Date(),
            userId: nil
        )
        wallets.append(wallet)
    }
    
    func updateWallet(_ wallet: Wallet) {
        if let index = wallets.firstIndex(where: { $0.id == wallet.id }) {
            wallets[index] = wallet
        }
    }
    
    func deleteWallet(id: UUID) {
        wallets.removeAll { $0.id == id }
    }
    
    // MARK: - 交易操作
    
    func addEntry(
        amount: Int,
        type: FinanceType,
        category: String,
        note: String? = nil
    ) {
        let entry = FinanceEntry(
            id: UUID(),
            amount: amount,
            type: type,
            category: category,
            note: note,
            date: Date(),
            userId: nil
        )
        
        entries.insert(entry, at: 0)
        
        // 记住分类选择
        if type == .expense {
            lastExpenseCategory = category
        } else if type == .income {
            lastIncomeCategory = category
        }
    }
    
    func deleteEntry(id: UUID) {
        entries.removeAll { $0.id == id }
    }
    
    // MARK: - 快照与核对
    
    func createSnapshot(balances: [UUID: Int]) {
        let balancesDict = balances.reduce(into: [String: Int]()) { result, item in
            result[item.key.uuidString] = item.value
        }
        
        let snapshot = WalletSnapshot(
            id: UUID(),
            date: Date(),
            balances: balancesDict,
            userId: nil
        )
        
        snapshots.insert(snapshot, at: 0)
        
        // 更新钱包的 lastUpdated 时间
        for i in 0..<wallets.count {
            wallets[i].lastUpdated = Date()
        }
    }
    
    // 计算两个快照之间的差值
    func calculateDifference(from oldSnapshot: WalletSnapshot?, to newSnapshot: WalletSnapshot) -> (actual: Int, recorded: Int, diff: Int) {
        let actualChange: Int
        if let old = oldSnapshot {
            actualChange = newSnapshot.totalBalance - old.totalBalance
        } else {
            actualChange = newSnapshot.totalBalance
        }
        
        // 计算记录变化
        let startDate = oldSnapshot?.date ?? Date.distantPast
        let endDate = newSnapshot.date
        
        let recordedIncome = entries.filter { $0.date >= startDate && $0.date <= endDate && $0.type == .income }
            .reduce(0) { $0 + $1.amount }
        let recordedExpense = entries.filter { $0.date >= startDate && $0.date <= endDate && $0.type == .expense }
            .reduce(0) { $0 + $1.amount }
        let recordedChange = recordedIncome - recordedExpense
        
        let difference = actualChange - recordedChange
        
        return (actual: actualChange, recorded: recordedChange, diff: difference)
    }
}
