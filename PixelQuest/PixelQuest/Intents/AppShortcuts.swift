import AppIntents

/// App Shortcuts 提供者 - 注册快捷指令和 Siri 短语
@available(iOS 16.0, *)
struct AppShortcuts: AppShortcutsProvider {
    
    /// 定义应用提供的快捷指令
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: QuickExpenseIntent(),
            phrases: [
                "用 \(.applicationName) 记账",
                "\(.applicationName) 快速记账",
                "用 \(.applicationName) 记一笔",
                "\(.applicationName) 记录支出",
                "Record expense with \(.applicationName)"
            ],
            shortTitle: "快速记账",
            systemImageName: "yensign.circle.fill"
        )
    }
}
