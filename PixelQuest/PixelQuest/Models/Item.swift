import Foundation

struct Item: Identifiable, Codable, Hashable {
    let id: Int
    var name: String
    var icon: String
    var rarity: Rarity
    var description: String
    var price: Int
    var purchaseDate: Date
    var userId: UUID?
    
    enum CodingKeys: String, CodingKey {
        case id, name, icon, rarity, description, price
        case purchaseDate = "purchase_date"
        case userId = "user_id"
    }
    
    enum Rarity: String, CaseIterable, Codable {
        case common = "Common"
        case rare = "Rare"
        case epic = "Epic"
        case legendary = "Legendary"
        
        var color: String {
            switch self {
            case .common: return "gray"
            case .rare: return "PixelBlue"
            case .epic: return "purple"
            case .legendary: return "PixelAccent"
            }
        }
    }
}

// 用于插入数据库的结构（不包含 ID）
struct InsertItem: Codable {
    var name: String
    var icon: String
    var rarity: String
    var description: String
    var price: Int
    var purchaseDate: Date
    var userId: UUID?
    
    enum CodingKeys: String, CodingKey {
        case name, icon, rarity, description, price
        case purchaseDate = "purchase_date"
        case userId = "user_id"
    }
}
