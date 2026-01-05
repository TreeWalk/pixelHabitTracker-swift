import Foundation

struct Location: Identifiable {
    let id: Int
    var name: String
    var icon: String
    var banner: String?
    var type: String
    var desc: String
    var unlocked: Bool
}
