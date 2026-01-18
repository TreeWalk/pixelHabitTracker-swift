import AppIntents

/// 支出分类枚举，用于快捷指令选择
@available(iOS 16.0, *)
enum ExpenseCategoryAppEnum: String, AppEnum {
    case food = "food"
    case transport = "transport"
    case shopping = "shopping"
    case entertainment = "entertainment"
    case bills = "bills"
    case health = "health"
    case education = "education"
    case giftOut = "gift_out"
    case otherOut = "other_out"
    
    static var typeDisplayRepresentation: TypeDisplayRepresentation {
        TypeDisplayRepresentation(name: "支出分类")
    }
    
    static var caseDisplayRepresentations: [ExpenseCategoryAppEnum: DisplayRepresentation] {
        [
            .food: DisplayRepresentation(title: "🍜 餐饮"),
            .transport: DisplayRepresentation(title: "🚗 交通"),
            .shopping: DisplayRepresentation(title: "🛒 购物"),
            .entertainment: DisplayRepresentation(title: "🎮 娱乐"),
            .bills: DisplayRepresentation(title: "📄 账单"),
            .health: DisplayRepresentation(title: "🏥 医疗"),
            .education: DisplayRepresentation(title: "📚 学习"),
            .giftOut: DisplayRepresentation(title: "🎁 礼物"),
            .otherOut: DisplayRepresentation(title: "📦 其他")
        ]
    }
    
    /// 转换为数据库使用的分类 ID
    var categoryId: String {
        self.rawValue
    }
    
    /// 分类的中文名称
    var displayName: String {
        switch self {
        case .food: return "餐饮"
        case .transport: return "交通"
        case .shopping: return "购物"
        case .entertainment: return "娱乐"
        case .bills: return "账单"
        case .health: return "医疗"
        case .education: return "学习"
        case .giftOut: return "礼物"
        case .otherOut: return "其他"
        }
    }
}
