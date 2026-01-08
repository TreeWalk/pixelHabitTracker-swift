import Foundation
import SwiftData

@Model
class ItemData {
    @Attribute(.unique) var itemId: UUID
    var name: String
    var icon: String
    var rarity: String  // "Common", "Rare", "Epic", "Legendary"
    var itemDescription: String
    var price: Int  // 以分为单位
    var purchaseDate: Date
    var createdAt: Date
    
    init(name: String, icon: String, rarity: String, description: String, price: Int, purchaseDate: Date = Date()) {
        self.itemId = UUID()
        self.name = name
        self.icon = icon
        self.rarity = rarity
        self.itemDescription = description
        self.price = price
        self.purchaseDate = purchaseDate
        self.createdAt = Date()
    }
    
    // MARK: - Computed Properties
    
    var rarityEnum: ItemRarity {
        ItemRarity(rawValue: rarity) ?? .common
    }
    
    var rarityColor: String {
        rarityEnum.color
    }
    
    var formattedPrice: String {
        "¥\(price)"
    }
    
    var daysOwned: Int {
        max(1, Calendar.current.dateComponents([.day], from: purchaseDate, to: Date()).day ?? 1)
    }
    
    var dailyCost: Double {
        Double(price) / Double(daysOwned)
    }
    
    var formattedDailyCost: String {
        String(format: "¥%.2f/天", dailyCost)
    }
}

// MARK: - Item Rarity Enum

enum ItemRarity: String, CaseIterable, Codable {
    case common = "Common"
    case rare = "Rare"
    case epic = "Epic"
    case legendary = "Legendary"
    
    var color: String {
        switch self {
        case .common: return "PixelWood"      // 棕色，更明显
        case .rare: return "PixelBlue"        // 蓝色
        case .epic: return "PixelRed"         // 红色，替代不可见的紫色
        case .legendary: return "PixelAccent" // 金色
        }
    }
    
    var localizedName: String {
        switch self {
        case .common: return "items_rarity_common".localized
        case .rare: return "items_rarity_rare".localized
        case .epic: return "items_rarity_epic".localized
        case .legendary: return "items_rarity_legendary".localized
        }
    }
}
