import SwiftUI
import Charts

struct QuestLogView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var questStore: QuestStore
    @State private var selectedDate: Date? = nil
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color("PixelBg").ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // MARK: 1. Stats Overview
                        StatsOverviewCard(
                            streak: questStore.currentStreak,
                            totalXP: questStore.totalXP,
                            totalQuests: questStore.totalCompletedQuests
                        )
                        
                        // MARK: 2. Contribution Heatmap
                        ContributionHeatmap(
                            data: questStore.heatmapData,
                            selectedDate: $selectedDate
                        )
                        
                        // MARK: 3. Type Distribution
                         TypeDistributionChart(distribution: questStore.typeDistribution)
                        
                        // MARK: 4. Recent History (or Selected Date History)
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text(historyTitle)
                                    .font(.pixel(16))
                                    .foregroundColor(Color("PixelAccent"))
                                Spacer()
                            }
                            
                            LazyVStack(spacing: 12) {
                                let logsToShow = filteredLogs
                                if logsToShow.isEmpty {
                                    Text("quest_log_empty".localized)
                                        .font(.pixel(14))
                                        .foregroundColor(.gray)
                                        .padding(.vertical, 20)
                                } else {
                                    ForEach(logsToShow) { log in
                                        LogItemRow(log: log)
                                    }
                                }
                            }
                        }
                        .padding(16)
                        .background(Color.white)
                        .pixelBorderSmall()
                        
                        Spacer(minLength: 40)
                    }
                    .padding()
                }
            }
            .navigationTitle("quest_log_title".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("close".localized) { dismiss() }
                        .font(.pixel(16))
                }
            }
        }
    }
    
    var historyTitle: String {
        if let date = selectedDate {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            return formatter.string(from: date)
        } else {
            return "quest_log_recent".localized
        }
    }
    
    var filteredLogs: [QuestLog] {
        if let date = selectedDate {
            let calendar = Calendar.current
            return questStore.questLog.filter { calendar.isDate($0.completedAt, inSameDayAs: date) }
        } else {
            return Array(questStore.questLog.prefix(10))
        }
    }
}

// MARK: - Subviews

struct StatsOverviewCard: View {
    let streak: Int
    let totalXP: Int
    let totalQuests: Int
    
    var body: some View {
        HStack(spacing: 12) {
            QuestStatItem(title: "STREAK", value: "\(streak)", icon: "flame.fill", color: .orange)
            QuestStatItem(title: "TOTAL XP", value: "\(totalXP)", icon: "star.fill", color: .yellow)
            QuestStatItem(title: "QUESTS", value: "\(totalQuests)", icon: "checkmark.circle.fill", color: .green)
        }
        .padding(16)
        .background(Color.white)
        .pixelBorderSmall()
    }
}

struct QuestStatItem: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(color)
            
            Text(value)
                .font(.pixel(20))
                .foregroundColor(Color("PixelBorder"))
            
            Text(title)
                .font(.pixel(10))
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
    }
}

struct ContributionHeatmap: View {
    let data: [Date: Int]
    @Binding var selectedDate: Date?
    
    // Constants - 4周 x 7天布局
    let weeksToShow = 4   // 显示4周
    let daysInWeek = 7    // 一周7天
    let cellSize: CGFloat = 32
    let spacing: CGFloat = 4
    
    // 7列固定宽度网格
    var gridColumns: [GridItem] {
        Array(repeating: GridItem(.fixed(cellSize), spacing: spacing), count: 7)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("quest_log_activity".localized)
                    .font(.pixel(16))
                    .foregroundColor(Color("PixelAccent"))
                Spacer()
            }
            
            VStack(spacing: spacing) {
                // 星期标题行 - 使用相同的 LazyVGrid
                LazyVGrid(columns: gridColumns, spacing: spacing) {
                    ForEach(["一", "二", "三", "四", "五", "六", "日"], id: \.self) { day in
                        Text(day)
                            .font(.pixel(12))
                            .foregroundColor(.gray)
                            .frame(width: cellSize, height: 20)
                    }
                }
                
                // Heatmap Grid - 4周 x 7天 = 28个格子
                LazyVGrid(columns: gridColumns, spacing: spacing) {
                    ForEach(0..<(weeksToShow * daysInWeek), id: \.self) { index in
                        let weekIndex = index / daysInWeek
                        let dayIndex = index % daysInWeek
                        
                        if let date = getDate(weekIndex: weekIndex, dayIndex: dayIndex) {
                            let count = data[Calendar.current.startOfDay(for: date)] ?? 0
                            HeatmapCell(count: count, isSelected: isSelected(date: date))
                                .onTapGesture {
                                    withAnimation {
                                        if selectedDate == date {
                                            selectedDate = nil
                                        } else {
                                            selectedDate = date
                                        }
                                    }
                                }
                        } else {
                            // 未来日期或无效日期 - 显示空白格子
                            RoundedRectangle(cornerRadius: 2)
                                .fill(Color.gray.opacity(0.1))
                                .frame(width: cellSize, height: cellSize)
                        }
                    }
                }
            }
            
            // Legend
            HStack(spacing: 8) {
                Text("Less")
                    .font(.pixel(10))
                    .foregroundColor(.gray)
                
                ForEach(0..<4) { level in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(HeatmapCell.color(for: level * 2))
                        .frame(width: 12, height: 12)
                }
                
                Text("More")
                    .font(.pixel(10))
                    .foregroundColor(.gray)
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding(16)
        .background(Color.white)
        .pixelBorderSmall()
    }
    
    private func getDate(weekIndex: Int, dayIndex: Int) -> Date? {
        let calendar = Calendar.current
        let today = Date()
        
        // 计算当前周的周一
        let weekday = calendar.component(.weekday, from: today) // 1=Sun, 2=Mon...
        let mondayOffset = weekday == 1 ? -6 : (2 - weekday)  // 调整到周一
        guard let startOfCurrentWeek = calendar.date(byAdding: .day, value: mondayOffset, to: today) else { return nil }
        
        // weekIndex 0 = 最老的周 (3周前)
        // weekIndex 3 = 当前周
        let weekOffset = weekIndex - (weeksToShow - 1)  // 从 -3 到 0
        
        if let weekDate = calendar.date(byAdding: .weekOfYear, value: weekOffset, to: startOfCurrentWeek),
           let cellDate = calendar.date(byAdding: .day, value: dayIndex, to: weekDate) {
            return cellDate > today ? nil : cellDate
        }
        return nil
    }
    
    private func isSelected(date: Date) -> Bool {
        guard let selected = selectedDate else { return false }
        return Calendar.current.isDate(date, inSameDayAs: selected)
    }
}

struct HeatmapCell: View {
    let count: Int
    let isSelected: Bool
    
    var body: some View {
        RoundedRectangle(cornerRadius: 2)
            .fill(Self.color(for: count))
            .frame(width: 32, height: 32)
            .overlay(
                RoundedRectangle(cornerRadius: 2)
                    .stroke(Color.black.opacity(0.5), lineWidth: isSelected ? 2 : 0)
            )
    }
    
    static func color(for count: Int) -> Color {
        if count == 0 { return Color.gray.opacity(0.1) }
        if count <= 2 { return Color("PixelGreen").opacity(0.3) }
        if count <= 4 { return Color("PixelGreen").opacity(0.6) }
        return Color("PixelGreen")
    }
}

 struct TypeDistributionChart: View {
     let distribution: [Quest.QuestType: Int]
     
     var body: some View {
         VStack(alignment: .leading, spacing: 12) {
             Text("quest_log_distribution".localized)
                 .font(.pixel(16))
                 .foregroundColor(Color("PixelAccent"))
             
             if distribution.isEmpty {
                 Text("No data yet")
                     .font(.pixel(12))
                     .foregroundColor(.gray)
                     .frame(maxWidth: .infinity, alignment: .center)
                     .padding()
             } else {
                 Chart {
                     ForEach(Quest.QuestType.allCases, id: \.self) { type in
                         if let count = distribution[type], count > 0 {
                             SectorMark(
                                 angle: .value("Count", count),
                                 innerRadius: .ratio(0.6),
                                 angularInset: 1.5
                             )
                             .foregroundStyle(Color(type.color))
                             .annotation(position: .overlay) {
                                 Text("\(count)")
                                     .font(.pixel(10))
                                     .foregroundColor(.white)
                             }
                         }
                     }
                 }
                 .frame(height: 200)
                 
                 // Legend
                 LazyVGrid(columns: [GridItem(.adaptive(minimum: 80))], spacing: 8) {
                     ForEach(Quest.QuestType.allCases, id: \.self) { type in
                         HStack(spacing: 4) {
                             Circle()
                                 .fill(Color(type.color))
                                 .frame(width: 8, height: 8)
                             Text(type.rawValue)
                                 .font(.pixel(10))
                                 .foregroundColor(.primary)
                         }
                     }
                 }
             }
         }
         .padding(16)
         .background(Color.white)
         .pixelBorderSmall()
     }
 }

struct LogItemRow: View {
    let log: QuestLog
    
    var body: some View {
        HStack(spacing: 12) {
            // Icon
            ZStack {
                Rectangle()
                    .fill(Color(log.questType.color).opacity(0.1))
                    .frame(width: 40, height: 40)
                    .pixelBorderSmall(color: Color(log.questType.color))
                
                Image(systemName: "checkmark")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(Color(log.questType.color))
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(log.questTitle)
                    .font(.pixel(16))
                    .foregroundColor(Color("PixelBorder"))
                
                Text(log.questType.rawValue + " • " + formatDate(log.completedAt))
                    .font(.pixel(10))
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            Text("+\(log.xp) XP")
                .font(.pixel(14))
                .foregroundColor(Color("PixelAccent"))
        }
        .padding(8)
        .background(Color.white)
        .pixelBorderSmall(color: Color("PixelBorder").opacity(0.2))
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, HH:mm"
        return formatter.string(from: date)
    }
}
