import Foundation
import Supabase

@MainActor
class LogStore: ObservableObject {
    @Published var logs: [Int: [LogEntry]] = [:]
    @Published var isLoading = false
    @Published var error: String?
    
    // MARK: - 从 Supabase 获取日志
    func fetchLogs(locationId: Int) async {
        isLoading = true
        error = nil
        
        do {
            let response: [LogEntry] = try await supabase
                .from("logs")
                .select()
                .eq("location_id", value: locationId)
                .order("date", ascending: false)
                .execute()
                .value
            
            logs[locationId] = response
        } catch {
            self.error = "获取日志失败: \(error.localizedDescription)"
            print("Fetch error: \(error)")
        }
        
        isLoading = false
    }
    
    // MARK: - 添加新日志到 Supabase
    func addLog(locationId: Int, text: String) async {
        let newEntry = LogEntry(
            id: UUID(),
            locationId: locationId,
            text: text,
            date: Date(),
            userId: supabase.auth.currentUser?.id
        )
        
        // 使用不含 ID 的 InsertLogEntry
        let insertEntry = InsertLogEntry(
            locationId: locationId,
            text: text,
            date: Date(),
            userId: supabase.auth.currentUser?.id
        )
        
        do {
            try await supabase
                .from("logs")
                .insert(insertEntry)
                .execute()
            
            // 刷新该位置的日志列表
            await fetchLogs(locationId: locationId)
        } catch {
            self.error = "添加日志失败: \(error.localizedDescription)"
            print("Insert error: \(error)")
        }
    }
    
    // MARK: - 同步获取本地缓存的日志 (用于 UI 显示)
    func getLogs(locationId: Int) -> [LogEntry] {
        logs[locationId] ?? []
    }
    
    // MARK: - 本地添加日志 (离线模式/测试用)
    func addLogLocally(locationId: Int, text: String) {
        let newEntry = LogEntry(
            id: UUID(),
            locationId: locationId,
            text: text,
            date: Date(),
            userId: nil
        )
        
        if logs[locationId] != nil {
            logs[locationId]?.insert(newEntry, at: 0)
        } else {
            logs[locationId] = [newEntry]
        }
    }
}
