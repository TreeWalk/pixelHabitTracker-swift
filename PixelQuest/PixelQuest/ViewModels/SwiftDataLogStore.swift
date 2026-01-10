import Foundation
import SwiftData

@MainActor
class SwiftDataLogStore: ObservableObject {
    private var modelContext: ModelContext?
    
    @Published var logs: [LogEntryData] = []
    @Published var isLoading = false
    @Published var error: String?
    
    // MARK: - Configure
    
    func configure(modelContext: ModelContext) {
        self.modelContext = modelContext
        loadData()
    }
    
    // MARK: - Load Data
    
    private func loadData() {
        guard let context = modelContext else { return }
        
        do {
            let descriptor = FetchDescriptor<LogEntryData>(sortBy: [SortDescriptor(\.date, order: .reverse)])
            logs = try context.fetch(descriptor)
        } catch {
            self.error = "加载日志失败: \(error.localizedDescription)"
        }
    }
    
    // MARK: - Query
    
    func getLogs(locationId: Int) -> [LogEntryData] {
        logs.filter { $0.locationId == locationId }
    }
    
    // MARK: - CRUD Operations
    
    func addLog(locationId: Int, content: String) {
        guard let context = modelContext else { return }
        
        let log = LogEntryData(locationId: locationId, content: content)
        
        context.insert(log)
        logs.insert(log, at: 0)
        
        try? context.save()
    }
    
    func deleteLog(_ log: LogEntryData) {
        guard let context = modelContext else { return }
        
        context.delete(log)
        logs.removeAll { $0.date == log.date && $0.locationId == log.locationId }
        
        try? context.save()
    }
}
