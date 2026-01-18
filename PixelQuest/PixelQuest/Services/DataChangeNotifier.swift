import Foundation

/// 跨组件数据变更通知管理器
/// 用于在 App Intents 与主 App 之间同步数据变更
final class DataChangeNotifier {

    // MARK: - Notification Names

    /// 财务数据变更通知
    static let financeDataDidChange = Notification.Name("com.pixelquest.financeDataDidChange")

    /// 任务数据变更通知
    static let questDataDidChange = Notification.Name("com.pixelquest.questDataDidChange")

    /// 通用数据变更通知（可用于其他模块扩展）
    static let dataDidChange = Notification.Name("com.pixelquest.dataDidChange")

    // MARK: - Post Notifications

    /// 发送财务数据变更通知
    /// - Parameter userInfo: 可选的附加信息（如变更类型、记录ID等）
    static func notifyFinanceDataChanged(userInfo: [String: Any]? = nil) {
        DispatchQueue.main.async {
            NotificationCenter.default.post(
                name: financeDataDidChange,
                object: nil,
                userInfo: userInfo
            )
        }
    }

    /// 发送任务数据变更通知
    static func notifyQuestDataChanged(userInfo: [String: Any]? = nil) {
        DispatchQueue.main.async {
            NotificationCenter.default.post(
                name: questDataDidChange,
                object: nil,
                userInfo: userInfo
            )
        }
    }

    /// 发送通用数据变更通知
    static func notifyDataChanged(userInfo: [String: Any]? = nil) {
        DispatchQueue.main.async {
            NotificationCenter.default.post(
                name: dataDidChange,
                object: nil,
                userInfo: userInfo
            )
        }
    }
}
