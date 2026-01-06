import SwiftUI

struct TransactionStatsSheet: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var financeStore: SwiftDataFinanceStore
    
    @State private var startDate: Date
    @State private var endDate: Date = Date()
    @State private var showResult = false
    
    init() {
        // 默认：上月今天到今天
        let calendar = Calendar.current
        let oneMonthAgo = calendar.date(byAdding: .month, value: -1, to: Date()) ?? Date()
        _startDate = State(initialValue: oneMonthAgo)
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color("PixelBg").ignoresSafeArea()
                
                if showResult {
                    // POS 小票样式显示统计结果
                    StatsReceiptView(
                        startDate: startDate,
                        endDate: endDate,
                        entries: filteredEntries,
                        onDismiss: {
                            showResult = false
                        }
                    )
                } else {
                    // 日期选择界面
                    ScrollView {
                        VStack(spacing: 20) {
                            Text("stats_period".localized)
                                .font(.pixel(20))
                                .foregroundColor(Color("PixelBorder"))
                                .padding(.top, 16)
                            
                            // 开始日期
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Start Date")
                                    .font(.pixel(14))
                                    .foregroundColor(Color("PixelBorder").opacity(0.7))
                                
                                DatePicker("", selection: $startDate, displayedComponents: .date)
                                    .datePickerStyle(.compact)
                                    .labelsHidden()
                                    .padding(12)
                                    .background(Color.white)
                                    .pixelBorderSmall()
                            }
                            .padding(.horizontal, 16)
                            
                            // 结束日期
                            VStack(alignment: .leading, spacing: 8) {
                                Text("End Date")
                                    .font(.pixel(14))
                                    .foregroundColor(Color("PixelBorder").opacity(0.7))
                                
                                DatePicker("", selection: $endDate, displayedComponents: .date)
                                    .datePickerStyle(.compact)
                                    .labelsHidden()
                                    .padding(12)
                                    .background(Color.white)
                                    .pixelBorderSmall()
                            }
                            .padding(.horizontal, 16)
                            
                            // 统计按钮
                            Button(action: { showResult = true }) {
                                HStack {
                                    Image(systemName: "chart.bar.fill")
                                    Text("stats_title".localized)
                                        .font(.pixel(20))
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(Color("PixelBlue"))
                                .pixelBorderSmall(color: Color("PixelBlue"))
                            }
                            .padding(.horizontal, 16)
                            .padding(.bottom, 16)
                        }
                    }
                }
            }
            .navigationTitle("stats_title".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if !showResult {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("cancel".localized) {
                            dismiss()
                        }
                        .font(.pixel(16))
                        .foregroundColor(Color("PixelBorder"))
                    }
                }
            }
        }
    }
    
    private var filteredEntries: [FinanceEntryData] {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: startDate)
        let end = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: endDate)) ?? endDate
        
        return financeStore.entries.filter { $0.date >= start && $0.date < end }
    }
}

// MARK: - Stats Receipt View

struct StatsReceiptView: View {
    let startDate: Date
    let endDate: Date
    let entries: [FinanceEntryData]
    let onDismiss: () -> Void
    
    @State private var printedLines: Int = 0
    private let totalLines = 15
    
    var totalIncome: Int {
        entries.filter { $0.isIncome }.reduce(0) { $0 + $1.amount }
    }
    
    var totalExpense: Int {
        entries.filter { $0.isExpense }.reduce(0) { $0 + $1.amount }
    }
    
    var net: Int {
        totalIncome - totalExpense
    }
    
    var dayCount: Int {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: startDate, to: endDate)
        return max(1, (components.day ?? 0) + 1)
    }
    
    var dailyAverage: Int {
        totalExpense / dayCount
    }
    
    var categoryStats: [(category: String, amount: Int)] {
        let grouped = Dictionary(grouping: entries.filter { $0.isExpense }) { $0.category }
        return grouped.map { (category: $0.key, amount: $0.value.reduce(0) { $0 + $1.amount }) }
            .sorted { $0.amount > $1.amount }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // POS 小票样式
                VStack(spacing: 4) {
                    // 标题
                    Text("※ \("stats_title".localized.uppercased()) ※")
                        .font(.system(size: 16, design: .monospaced))
                        .fontWeight(.bold)
                        .padding(.top, 20)
                    
                    if printedLines >= 1 {
                        Text("\(formatDate(startDate)) - \(formatDate(endDate))")
                            .font(.system(size: 12, design: .monospaced))
                            .foregroundColor(.secondary)
                            .padding(.bottom, 10)
                    }
                    
                    if printedLines >= 2 {
                        Divider()
                    }
                    
                    // 总收入
                    if printedLines >= 3 {
                        HStack {
                            Text("stats_total_income".localized)
                                .font(.system(size: 14, design: .monospaced))
                            Spacer()
                            Text("¥\(String(format: "%.2f", Double(totalIncome) / 100.0))")
                                .font(.system(size: 14, design: .monospaced))
                                .foregroundColor(Color("PixelGreen"))
                        }
                        .padding(.vertical, 4)
                    }
                    
                    // 总支出
                    if printedLines >= 4 {
                        HStack {
                            Text("stats_total_expense".localized)
                                .font(.system(size: 14, design: .monospaced))
                            Spacer()
                            Text("¥\(String(format: "%.2f", Double(totalExpense) / 100.0))")
                                .font(.system(size: 14, design: .monospaced))
                                .foregroundColor(Color("PixelRed"))
                        }
                        .padding(.vertical, 4)
                    }
                    
                    if printedLines >= 5 {
                        Divider()
                    }
                    
                    // 净额
                    if printedLines >= 6 {
                        HStack {
                            Text("stats_net".localized)
                                .font(.system(size: 16, design: .monospaced))
                                .fontWeight(.bold)
                            Spacer()
                            Text("\(net >= 0 ? "+" : "")¥\(String(format: "%.2f", Double(net) / 100.0))")
                                .font(.system(size: 16, design: .monospaced))
                                .fontWeight(.bold)
                                .foregroundColor(net >= 0 ? Color("PixelGreen") : Color("PixelRed"))
                        }
                        .padding(.vertical, 8)
                    }
                    
                    // 日均支出
                    if printedLines >= 7 {
                        HStack {
                            Text("stats_daily_avg".localized)
                                .font(.system(size: 14, design: .monospaced))
                            Spacer()
                            Text("¥\(String(format: "%.2f", Double(dailyAverage) / 100.0))")
                                .font(.system(size: 14, design: .monospaced))
                                .foregroundColor(Color("PixelBlue"))
                        }
                        .padding(.vertical, 4)
                    }
                    
                    if printedLines >= 8 {
                        Divider()
                        
                        // 按分类统计
                        Text("stats_by_category".localized)
                            .font(.system(size: 14, design: .monospaced))
                            .fontWeight(.bold)
                            .padding(.vertical, 8)
                    }
                    
                    if printedLines >= 9 {
                        ForEach(Array(categoryStats.prefix(5).enumerated()), id: \.offset) { index, stat in
                            if printedLines >= 9 + index {
                                HStack {
                                    Text(getCategoryName(stat.category))
                                        .font(.system(size: 12, design: .monospaced))
                                    Spacer()
                                    Text("¥\(String(format: "%.2f", Double(stat.amount) / 100.0))")
                                        .font(.system(size: 12, design: .monospaced))
                                }
                                .padding(.vertical, 2)
                            }
                        }
                    }
                    
                    if printedLines >= totalLines {
                        Divider()
                        
                        Text("reconcile_thank_you".localized)
                            .font(.system(size: 12, design: .monospaced))
                            .padding(.top, 10)
                        
                        Text("reconcile_slogan".localized)
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundColor(.secondary)
                            .padding(.bottom, 10)
                        
                        Text("reconcile_tear_here".localized)
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundColor(.secondary)
                            .padding(.vertical, 10)
                        
                        // 完成按钮
                        Button(action: onDismiss) {
                            Text("reconcile_got_it".localized)
                                .font(.pixel(20))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(Color("PixelBlue"))
                                .pixelBorderSmall(color: Color("PixelBlue"))
                        }
                        .padding(.top, 10)
                    }
                }
                .padding()
                .frame(maxWidth: 400)
                .background(Color.white)
                .pixelBorderSmall()
                .padding()
            }
        }
        .onAppear {
            animatePrint()
        }
    }
    
    private func animatePrint() {
        for i in 0...totalLines {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.1) {
                printedLines = i
            }
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
    
    private func getCategoryName(_ category: String) -> String {
        return "category_\(category)".localized
    }
}
