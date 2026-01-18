import AppIntents
import SwiftData

/// 快速记账 Intent - 通过快捷指令快速添加支出记录
@available(iOS 16.0, *)
struct QuickExpenseIntent: AppIntent {
    static var title: LocalizedStringResource = "快速记账"
    static var description: IntentDescription = IntentDescription("快速记录一笔支出，无需打开 App")
    
    /// 是否在锁屏时也可以运行
    static var authenticationPolicy: IntentAuthenticationPolicy = .alwaysAllowed
    
    /// 支出金额（元）
    @Parameter(title: "金额（元）", description: "支出金额，单位为元")
    var amount: Double
    
    /// 支出分类
    @Parameter(title: "分类", description: "选择支出分类")
    var category: ExpenseCategoryAppEnum
    
    /// 可选备注
    @Parameter(title: "备注", description: "可选的备注信息")
    var note: String?
    
    /// 执行记账
    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        // 将金额转换为分（数据库存储单位）
        let amountInCents = Int(amount * 100)
        
        // 创建 ModelContainer（与主 App 使用相同的配置）
        let schema = Schema([
            FinanceEntryData.self,
            WalletData.self,
            WalletSnapshotData.self,
            AssetData.self,
            AssetSnapshotData.self,
            // 需要包含所有 Schema 以确保兼容
            QuestData.self,
            QuestLogData.self,
            ItemData.self,
            BookEntryData.self,
            SleepEntryData.self,
            ExerciseEntryData.self,
            LogEntryData.self
        ])
        
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        
        do {
            let container = try ModelContainer(for: schema, configurations: [modelConfiguration])
            let context = ModelContext(container)
            
            // 创建新的财务记录
            let entry = FinanceEntryData(
                amount: amountInCents,
                type: "expense",
                category: category.categoryId,
                note: note
            )
            
            context.insert(entry)
            try context.save()
            
            // 返回成功消息
            let formattedAmount = String(format: "%.2f", amount)
            return .result(dialog: "✅ 已记录：\(category.displayName) ¥\(formattedAmount)")
            
        } catch {
            return .result(dialog: "❌ 记账失败：\(error.localizedDescription)")
        }
    }
    
    /// 参数摘要（在快捷指令编辑器中显示）
    static var parameterSummary: some ParameterSummary {
        Summary("记录 \(\.$category) 支出 ¥\(\.$amount)") {
            \.$note
        }
    }
}
