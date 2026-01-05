import Foundation
import SwiftData

@Model
final class ItemData {
    var name: String
    var icon: String
    var rarity: String // common, rare, epic, legendary
    var itemDescription: String
    var price: Int
    var purchaseDate: Date
    
    init(name: String, icon: String, rarity: String, itemDescription: String, price: Int, purchaseDate: Date = Date()) {
        self.name = name
        self.icon = icon
        self.rarity = rarity
        self.itemDescription = itemDescription
        self.price = price
        self.purchaseDate = purchaseDate
    }
}
