import Foundation
import Supabase

@MainActor
class ItemStore: ObservableObject {
    @Published var items: [Item] = []
    @Published var isLoading = false
    @Published var error: String?
    
    // 本地默认数据（用于离线模式或初始化）
    private let defaultItems: [Item] = [
        Item(id: 1, name: "MacBook Pro", icon: "item_pc", rarity: .rare, description: "日常工作主力", price: 12999, purchaseDate: Calendar.current.date(byAdding: .day, value: -180, to: Date())!, userId: nil),
        Item(id: 2, name: "iPhone 15", icon: "item_phone", rarity: .epic, description: "随身携带", price: 7999, purchaseDate: Calendar.current.date(byAdding: .day, value: -90, to: Date())!, userId: nil),
        Item(id: 3, name: "Apple Watch", icon: "item_watch", rarity: .common, description: "运动追踪", price: 2999, purchaseDate: Calendar.current.date(byAdding: .day, value: -365, to: Date())!, userId: nil),
    ]
    
    init() {
        items = defaultItems
    }
    
    var totalValue: Int {
        items.reduce(0) { $0 + $1.price }
    }
    
    var averageDailyCost: Double {
        guard !items.isEmpty else { return 0 }
        let totalDailyCost = items.reduce(0.0) { total, item in
            let days = max(1, Calendar.current.dateComponents([.day], from: item.purchaseDate, to: Date()).day ?? 1)
            return total + Double(item.price) / Double(days)
        }
        return totalDailyCost / Double(items.count)
    }
    
    // MARK: - 从 Supabase 获取物品
    func fetchItems() async {
        isLoading = true
        error = nil
        
        do {
            let response: [Item] = try await supabase
                .from("items")
                .select()
                .order("id", ascending: true)
                .execute()
                .value
            
            items = response.isEmpty ? defaultItems : response
        } catch {
            self.error = "获取物品失败: \(error.localizedDescription)"
            print("Fetch items error: \(error)")
        }
        
        isLoading = false
    }
    
    // MARK: - 添加物品
    func addItem(name: String, icon: String, rarity: Item.Rarity, description: String, price: Int, purchaseDate: Date = Date()) async {
        let newItem = Item(
            id: Int(Date().timeIntervalSince1970),
            name: name,
            icon: icon,
            rarity: rarity,
            description: description,
            price: price,
            purchaseDate: purchaseDate,
            userId: supabase.auth.currentUser?.id
        )
        items.append(newItem)
        
        // 使用不含 ID 的 InsertItem
        let insertItem = InsertItem(
            name: name,
            icon: icon,
            rarity: rarity.rawValue,
            description: description,
            price: price,
            purchaseDate: purchaseDate,
            userId: supabase.auth.currentUser?.id
        )
        
        do {
            try await supabase.from("items").insert(insertItem).execute()
        } catch {
            print("Insert item error: \(error)")
        }
    }
    
    // MARK: - 删除物品
    func deleteItem(id: Int) async {
        items.removeAll { $0.id == id }
        
        do {
            try await supabase
                .from("items")
                .delete()
                .eq("id", value: id)
                .execute()
        } catch {
            print("Delete item error: \(error)")
        }
    }
    
    // MARK: - 本地方法（离线模式）
    func addItemLocally(name: String, icon: String, rarity: Item.Rarity, description: String, price: Int, purchaseDate: Date = Date()) {
        let newItem = Item(
            id: Int(Date().timeIntervalSince1970),
            name: name,
            icon: icon,
            rarity: rarity,
            description: description,
            price: price,
            purchaseDate: purchaseDate,
            userId: nil
        )
        items.append(newItem)
    }
    
    func deleteItemLocally(id: Int) {
        items.removeAll { $0.id == id }
    }
}
