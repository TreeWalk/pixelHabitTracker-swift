import Foundation
import Supabase

@MainActor
class ExerciseStore: ObservableObject {
    @Published var entries: [ExerciseEntry] = []
    @Published var isLoading = false
    @Published var error: String?
    
    // MARK: - 今日数据
    var todayEntries: [ExerciseEntry] {
        let calendar = Calendar.current
        return entries.filter { calendar.isDateInToday($0.date) }
    }
    
    var todayTotalDuration: Int {
        todayEntries.reduce(0) { $0 + $1.duration }
    }
    
    var todayTotalCalories: Int {
        todayEntries.reduce(0) { $0 + $1.calories }
    }
    
    // MARK: - 本周数据
    var weekEntries: [ExerciseEntry] {
        let calendar = Calendar.current
        let now = Date()
        guard let weekAgo = calendar.date(byAdding: .day, value: -6, to: now) else { return [] }
        return entries.filter { $0.date >= weekAgo }
    }
    
    var weekTotalDuration: Int {
        weekEntries.reduce(0) { $0 + $1.duration }
    }
    
    var weekTotalCalories: Int {
        weekEntries.reduce(0) { $0 + $1.calories }
    }
    
    // MARK: - Supabase 操作
    
    func fetchEntries() async {
        isLoading = true
        error = nil
        
        do {
            let response: [ExerciseEntry] = try await supabase
                .from("exercise_entries")
                .select()
                .order("date", ascending: false)
                .limit(30)
                .execute()
                .value
            entries = response
        } catch {
            self.error = "获取运动记录失败: \(error.localizedDescription)"
            print("Fetch exercise entries error: \(error)")
        }
        
        isLoading = false
    }
    
    func addEntry(type: ExerciseEntry.ExerciseType, duration: Int, calories: Int) async {
        let newEntry = ExerciseEntry(
            id: UUID(),
            type: type,
            duration: duration,
            calories: calories,
            date: Date(),
            userId: supabase.auth.currentUser?.id
        )
        
        // 先添加到本地
        entries.insert(newEntry, at: 0)
        
        // 同步到 Supabase
        let insertEntry = InsertExerciseEntry(
            type: type.rawValue,
            duration: duration,
            calories: calories,
            date: Date(),
            userId: supabase.auth.currentUser?.id
        )
        
        do {
            try await supabase.from("exercise_entries").insert(insertEntry).execute()
        } catch {
            self.error = "保存运动记录失败: \(error.localizedDescription)"
            print("Insert exercise entry error: \(error)")
        }
    }
    
    func deleteEntry(id: UUID) async {
        entries.removeAll { $0.id == id }
        
        do {
            try await supabase
                .from("exercise_entries")
                .delete()
                .eq("id", value: id.uuidString)
                .execute()
        } catch {
            print("Delete exercise entry error: \(error)")
        }
    }
    
    // 本地添加（离线模式）
    func addEntryLocally(type: ExerciseEntry.ExerciseType, duration: Int, calories: Int) {
        let entry = ExerciseEntry(
            id: UUID(),
            type: type,
            duration: duration,
            calories: calories,
            date: Date(),
            userId: nil
        )
        entries.insert(entry, at: 0)
    }
}
