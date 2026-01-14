import Foundation
import SwiftData

@MainActor
class SwiftDataItemStore: ObservableObject {
    private var modelContext: ModelContext?
    
    @Published var items: [ItemData] = []
    @Published var isLoading = false
    @Published var error: String?
    
    // MARK: - 配置 ModelContext

    func configure(modelContext: ModelContext) async {
        self.modelContext = modelContext
        loadData()
    }
    
    // MARK: - 加载数据
    
    private func loadData() {
        guard let context = modelContext else { return }
        
        do {
            let descriptor = FetchDescriptor<ItemData>(sortBy: [SortDescriptor(\.createdAt, order: .reverse)])
            items = try context.fetch(descriptor)
            
            // 如果没有数据，初始化默认物品
            if items.isEmpty {
                initializeDefaultItems()
            }
        } catch {
            self.error = "加载物品失败: \(error.localizedDescription)"
            print("Load items error: \(error)")
        }
    }
    
    // MARK: - 初始化默认物品
    
    private func initializeDefaultItems() {
        guard let context = modelContext else { return }
        
        let defaults = [
            ("MacBook Pro", "item_pc", "Rare", "日常工作主力", 12999, -180),
            ("iPhone 15", "item_phone", "Epic", "随身携带", 7999, -90),
            ("Apple Watch", "item_watch", "Common", "运动追踪", 2999, -365),
        ]
        
        for (name, icon, rarity, desc, price, daysAgo) in defaults {
            let date = Calendar.current.date(byAdding: .day, value: daysAgo, to: Date()) ?? Date()
            let item = ItemData(name: name, icon: icon, rarity: rarity, description: desc, price: price, purchaseDate: date)
            context.insert(item)
            items.append(item)
        }
        
        try? context.save()
    }
    
    // MARK: - Computed Properties
    
    var totalValue: Int {
        items.reduce(0) { $0 + $1.price }
    }
    
    var formattedTotalValue: String {
        "¥\(totalValue)"
    }
    
    var averageDailyCost: Double {
        guard !items.isEmpty else { return 0 }
        return items.reduce(0.0) { $0 + $1.dailyCost } / Double(items.count)
    }
    
    var formattedAverageDailyCost: String {
        String(format: "¥%.2f/天", averageDailyCost)
    }
    
    // MARK: - CRUD 操作
    
    func addItem(name: String, icon: String, rarity: ItemRarity, description: String, price: Int, purchaseDate: Date = Date()) {
        guard let context = modelContext else { return }
        
        let item = ItemData(
            name: name,
            icon: icon,
            rarity: rarity.rawValue,
            description: description,
            price: price,
            purchaseDate: purchaseDate
        )
        
        context.insert(item)
        items.insert(item, at: 0)
        
        try? context.save()
    }
    
    func deleteItem(_ item: ItemData) {
        guard let context = modelContext else { return }
        
        context.delete(item)
        items.removeAll { $0.itemId == item.itemId }
        
        try? context.save()
    }
    
    func updateItem(_ item: ItemData, name: String, icon: String, rarity: ItemRarity, description: String, price: Int, purchaseDate: Date) {
        item.name = name
        item.icon = icon
        item.rarity = rarity.rawValue
        item.itemDescription = description
        item.price = price
        item.purchaseDate = purchaseDate
        
        try? modelContext?.save()
    }
    
    // MARK: - 按稀有度分组
    
    var itemsByRarity: [ItemRarity: [ItemData]] {
        Dictionary(grouping: items) { $0.rarityEnum }
    }
    
    func items(for rarity: ItemRarity) -> [ItemData] {
        items.filter { $0.rarityEnum == rarity }
    }
}
