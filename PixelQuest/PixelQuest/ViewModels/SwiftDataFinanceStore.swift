import Foundation
import SwiftData
import Combine

@MainActor
class SwiftDataFinanceStore: ObservableObject {
    private var modelContext: ModelContext?
    private var cancellables = Set<AnyCancellable>()

    @Published var wallets: [WalletData] = []
    @Published var snapshots: [WalletSnapshotData] = []
    @Published var entries: [FinanceEntryData] = []
    @Published var assets: [AssetData] = []
    @Published var assetSnapshots: [AssetSnapshotData] = []
    @Published var isLoading = false
    @Published var error: String?
    @Published var lastSaveError: Error?

    // 上次选择的分类
    @Published var lastExpenseCategory: String = "food"
    @Published var lastIncomeCategory: String = "salary"

    // MARK: - Initialization

    init() {
        setupNotificationObservers()
    }

    deinit {
        cancellables.removeAll()
    }

    /// 监听数据变更通知（来自 App Intents 等外部来源）
    private func setupNotificationObservers() {
        NotificationCenter.default.publisher(for: DataChangeNotifier.financeDataDidChange)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.reloadData()
            }
            .store(in: &cancellables)
    }

    /// 重新加载数据（供外部通知触发）
    func reloadData() {
        loadData()
    }

    // MARK: - Private Helpers

    /// 统一的保存方法，带错误处理
    private func saveContext() {
        guard let context = modelContext else { return }
        do {
            try context.save()
            lastSaveError = nil
        } catch {
            lastSaveError = error
            self.error = "保存失败: \(error.localizedDescription)"
            print("❌ SwiftDataFinanceStore 保存失败: \(error)")
        }
    }
    
    // MARK: - 配置 ModelContext
    
    func configure(modelContext: ModelContext) async {
        self.modelContext = modelContext
        loadData()
        initializeDefaultWallets()
    }
    
    private func loadData() {
        guard let context = modelContext else { return }
        
        do {
            let walletDescriptor = FetchDescriptor<WalletData>(sortBy: [SortDescriptor(\.order)])
            wallets = try context.fetch(walletDescriptor)
            
            let snapshotDescriptor = FetchDescriptor<WalletSnapshotData>(sortBy: [SortDescriptor(\.date, order: .reverse)])
            snapshots = try context.fetch(snapshotDescriptor)
            
            let entryDescriptor = FetchDescriptor<FinanceEntryData>(sortBy: [SortDescriptor(\.date, order: .reverse)])
            entries = try context.fetch(entryDescriptor)
            
            let assetDescriptor = FetchDescriptor<AssetData>(sortBy: [SortDescriptor(\.order)])
            assets = try context.fetch(assetDescriptor)
            
            let assetSnapshotDescriptor = FetchDescriptor<AssetSnapshotData>(sortBy: [SortDescriptor(\.date, order: .reverse)])
            assetSnapshots = try context.fetch(assetSnapshotDescriptor)
        } catch {
            print("Load data error: \(error)")
        }
    }
    
    private func initializeDefaultWallets() {
        guard let context = modelContext, wallets.isEmpty else { return }
        
        let defaults = [
            ("现金", "banknote.fill", "PixelGreen", 0),
            ("银行卡", "creditcard.fill", "PixelBlue", 1),
            ("微信", "message.fill", "PixelGreen", 2),
            ("支付宝", "bolt.circle.fill", "PixelBlue", 3)
        ]
        
        for (name, icon, color, order) in defaults {
            let wallet = WalletData(name: name, icon: icon, color: color, order: order)
            context.insert(wallet)
            wallets.append(wallet)
        }

        saveContext()
    }
    
    // MARK: - 计算属性
    
    var latestSnapshot: WalletSnapshotData? {
        snapshots.first
    }
    
    var totalBalance: Int {
        latestSnapshot?.totalBalance ?? 0
    }
    
    var formattedTotalBalance: String {
        String(format: "%.2f", Double(totalBalance) / 100.0)
    }
    
    var todayEntries: [FinanceEntryData] {
        let calendar = Calendar.current
        return entries.filter { calendar.isDateInToday($0.date) }
    }
    
    var monthIncome: Int {
        let calendar = Calendar.current
        guard let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: Date())) else { return 0 }
        return entries.filter { $0.date >= monthStart && $0.isIncome }.reduce(0) { $0 + $1.amount }
    }
    
    var monthExpense: Int {
        let calendar = Calendar.current
        guard let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: Date())) else { return 0 }
        return entries.filter { $0.date >= monthStart && $0.isExpense }.reduce(0) { $0 + $1.amount }
    }
    
    var monthNet: Int { monthIncome - monthExpense }
    
    // MARK: - 交易操作
    
    func addEntry(amount: Int, type: String, category: String, note: String? = nil) {
        guard let context = modelContext else { return }
        
        let entry = FinanceEntryData(amount: amount, type: type, category: category, note: note)
        context.insert(entry)
        entries.insert(entry, at: 0)
        
        if type == "expense" { lastExpenseCategory = category }
        else if type == "income" { lastIncomeCategory = category }

        saveContext()
    }

    func deleteEntry(_ entry: FinanceEntryData) {
        guard let context = modelContext else { return }
        context.delete(entry)
        entries.removeAll { $0.id == entry.id }
        saveContext()
    }
    
    // MARK: - 快照操作
    
    func createSnapshot(balances: [String: Int]) {
        guard let context = modelContext else { return }
        
        let snapshot = WalletSnapshotData()
        snapshot.balances = balances
        context.insert(snapshot)
        snapshots.insert(snapshot, at: 0)
        
        // 更新钱包时间
        for wallet in wallets {
            wallet.lastUpdated = Date()
        }

        saveContext()
    }
    
    func calculateDifference(from oldSnapshot: WalletSnapshotData?, to newSnapshot: WalletSnapshotData) -> (actual: Int, recorded: Int, diff: Int) {
        let actualChange: Int
        if let old = oldSnapshot {
            actualChange = newSnapshot.totalBalance - old.totalBalance
        } else {
            actualChange = newSnapshot.totalBalance
        }
        
        let startDate = oldSnapshot?.date ?? Date.distantPast
        let endDate = newSnapshot.date
        
        let recordedIncome = entries.filter { $0.date >= startDate && $0.date <= endDate && $0.isIncome }.reduce(0) { $0 + $1.amount }
        let recordedExpense = entries.filter { $0.date >= startDate && $0.date <= endDate && $0.isExpense }.reduce(0) { $0 + $1.amount }
        let recordedChange = recordedIncome - recordedExpense
        
        return (actual: actualChange, recorded: recordedChange, diff: actualChange - recordedChange)
    }
    
    // MARK: - 按日期分组
    
    func entriesGroupedByDate() -> [(date: Date, entries: [FinanceEntryData])] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: entries) { calendar.startOfDay(for: $0.date) }
        return grouped.sorted { $0.key > $1.key }.map { (date: $0.key, entries: $0.value) }
    }
    
    // MARK: - 资产管理
    
    var latestAssetSnapshot: AssetSnapshotData? {
        assetSnapshots.first
    }
    
    var totalAssets: Int {
        assets.filter { $0.type != "liability" }.reduce(0) { $0 + $1.currentBalance }
    }
    
    var totalLiabilities: Int {
        assets.filter { $0.type == "liability" }.reduce(0) { $0 + abs($1.currentBalance) }
    }
    
    var netWorth: Int {
        totalAssets - totalLiabilities
    }
    
    func assetsByType(_ type: String) -> [AssetData] {
        assets.filter { $0.type == type }.sorted { $0.order < $1.order }
    }
    
    func addAsset(name: String, icon: String, color: String, type: String, balance: Int) {
        guard let context = modelContext else { return }

        let order = assets.filter { $0.type == type }.count
        let asset = AssetData(name: name, icon: icon, color: color, type: type, order: order, currentBalance: balance)
        context.insert(asset)
        assets.append(asset)

        saveContext()
    }

    func updateAsset(_ asset: AssetData, balance: Int) {
        asset.currentBalance = balance
        asset.lastUpdated = Date()
        saveContext()
    }

    func deleteAsset(_ asset: AssetData) {
        guard let context = modelContext else { return }
        context.delete(asset)
        assets.removeAll { $0.assetId == asset.assetId }
        saveContext()
    }

    func createAssetSnapshot() {
        guard let context = modelContext else { return }

        var balances: [String: Int] = [:]
        for asset in assets {
            balances[asset.assetId.uuidString] = asset.currentBalance
        }

        let snapshot = AssetSnapshotData(
            balances: balances,
            totalAssets: totalAssets,
            totalLiabilities: totalLiabilities
        )
        context.insert(snapshot)
        assetSnapshots.insert(snapshot, at: 0)

        saveContext()
    }
    
    func calculateAssetChange(from oldSnapshot: AssetSnapshotData?, to newSnapshot: AssetSnapshotData) -> [(assetId: UUID, oldBalance: Int, newBalance: Int, change: Int)] {
        var changes: [(assetId: UUID, oldBalance: Int, newBalance: Int, change: Int)] = []
        
        for asset in assets {
            let newBalance = newSnapshot.balance(for: asset.assetId)
            let oldBalance = oldSnapshot?.balance(for: asset.assetId) ?? 0
            let change = newBalance - oldBalance
            changes.append((assetId: asset.assetId, oldBalance: oldBalance, newBalance: newBalance, change: change))
        }
        
        return changes
    }
}
