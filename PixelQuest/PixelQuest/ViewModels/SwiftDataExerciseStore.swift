import Foundation
import SwiftData

@MainActor
class SwiftDataExerciseStore: ObservableObject {
    private var modelContext: ModelContext?
    
    @Published var entries: [ExerciseEntryData] = []
    @Published var isLoading = false
    @Published var error: String?
    
    // MARK: - Configure
    
    func configure(modelContext: ModelContext) async {
        self.modelContext = modelContext
        loadData()
    }
    
    // MARK: - Load Data
    
    private func loadData() {
        guard let context = modelContext else { return }
        
        do {
            let descriptor = FetchDescriptor<ExerciseEntryData>(sortBy: [SortDescriptor(\.date, order: .reverse)])
            entries = try context.fetch(descriptor)
        } catch {
            self.error = "加载运动记录失败: \(error.localizedDescription)"
        }
    }
    
    // MARK: - Computed Properties
    
    var todayEntries: [ExerciseEntryData] {
        let calendar = Calendar.current
        return entries.filter { calendar.isDateInToday($0.date) }
    }
    
    var todayTotalDuration: Int {
        todayEntries.reduce(0) { $0 + $1.duration }
    }
    
    var todayTotalCalories: Int {
        todayEntries.reduce(0) { $0 + $1.calories }
    }
    
    var weekEntries: [ExerciseEntryData] {
        let calendar = Calendar.current
        guard let weekAgo = calendar.date(byAdding: .day, value: -6, to: Date()) else { return [] }
        return entries.filter { $0.date >= weekAgo }
    }
    
    var weekTotalDuration: Int {
        weekEntries.reduce(0) { $0 + $1.duration }
    }
    
    var weekTotalCalories: Int {
        weekEntries.reduce(0) { $0 + $1.calories }
    }
    
    // MARK: - CRUD Operations
    
    func addEntry(type: ExerciseType, duration: Int, calories: Int) {
        guard let context = modelContext else { return }
        
        let entry = ExerciseEntryData(
            type: type.rawValue,
            duration: duration,
            calories: calories
        )
        
        context.insert(entry)
        entries.insert(entry, at: 0)
        
        try? context.save()
    }
    
    func deleteEntry(_ entry: ExerciseEntryData) {
        guard let context = modelContext else { return }
        
        context.delete(entry)
        entries.removeAll { $0.date == entry.date && $0.type == entry.type }
        
        try? context.save()
    }
}
