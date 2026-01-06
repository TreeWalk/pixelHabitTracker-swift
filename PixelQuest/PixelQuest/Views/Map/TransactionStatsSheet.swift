import SwiftUI

struct TransactionStatsSheet: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var financeStore: SwiftDataFinanceStore
    
    @State private var startDate: Date
    @State private var endDate: Date = Date()
    @State private var showResult = false
    
    init() {
        let calendar = Calendar.current
        let oneMonthAgo = calendar.date(byAdding: .month, value: -1, to: Date()) ?? Date()
        _startDate = State(initialValue: oneMonthAgo)
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color("PixelBg").ignoresSafeArea()
                
                if showResult {
                    ScrollView {
                        StatsReceipt(
                            startDate: startDate,
                            endDate: endDate,
                            entries: filteredEntries,
                            onDismiss: { showResult = false }
                        )
                        .padding()
                    }
                } else {
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

// MARK: - Stats Receipt

struct StatsReceipt: View {
    let startDate: Date
    let endDate: Date
    let entries: [FinanceEntryData]
    let onDismiss: () -> Void
    
    @State private var showContent = false
    
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
        guard dayCount > 0 else { return 0 }
        return totalExpense / dayCount
    }
    
    var categoryStats: [(category: String, amount: Int)] {
        let grouped = Dictionary(grouping: entries.filter { $0.isExpense }) { $0.category }
        return grouped.map { (category: $0.key, amount: $0.value.reduce(0) { $0 + $1.amount }) }
            .sorted { $0.amount > $1.amount }
    }
    
    var body: some View {
        VStack(spacing: 16) {
            ThermalReceiptView(
                ticketNo: String(UUID().uuidString.prefix(6)).uppercased(),
                date: Date(),
                title: "stats_title".localized
            ) {
                if showContent {
                    VStack(spacing: 12) {
                        // 统计期间
                        HStack {
                            Text("\(formatDate(startDate)) - \(formatDate(endDate))")
                                .font(.pixel(12))
                                .foregroundColor(.secondary)
                            Spacer()
                            Text("\(dayCount) days")
                                .font(.pixel(12))
                                .foregroundColor(.secondary)
                        }
                        
                        ReceiptDivider()
                        
                        // 总收入
                        ReceiptRow(
                            label: "stats_total_income".localized,
                            value: "¥\(String(format: "%.2f", Double(totalIncome) / 100.0))",
                            valueColor: Color("PixelGreen")
                        )
                        
                        // 总支出
                        ReceiptRow(
                            label: "stats_total_expense".localized,
                            value: "¥\(String(format: "%.2f", Double(totalExpense) / 100.0))",
                            valueColor: Color("PixelRed")
                        )
                        
                        ReceiptDivider()
                        
                        // 净额
                        HStack {
                            Text("stats_net".localized)
                                .font(.pixel(18))
                                .foregroundColor(Color(red: 0.3, green: 0.25, blue: 0.2))
                            Spacer()
                            Text("\(net >= 0 ? "+" : "")¥\(String(format: "%.2f", Double(net) / 100.0))")
                                .font(.pixel(20))
                                .fontWeight(.bold)
                                .foregroundColor(net >= 0 ? Color("PixelGreen") : Color("PixelRed"))
                        }
                        
                        // 日均支出
                        ReceiptRow(
                            label: "stats_daily_avg".localized,
                            value: "¥\(String(format: "%.2f", Double(dailyAverage) / 100.0))",
                            valueColor: Color("PixelBlue")
                        )
                        
                        ReceiptDivider()
                        
                        // 按分类统计
                        Text("stats_by_category".localized)
                            .font(.pixel(14))
                            .foregroundColor(Color(red: 0.3, green: 0.25, blue: 0.2))
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        ForEach(Array(categoryStats.prefix(5).enumerated()), id: \.offset) { _, stat in
                            ReceiptRow(
                                label: getCategoryName(stat.category),
                                value: "¥\(String(format: "%.2f", Double(stat.amount) / 100.0))"
                            )
                        }
                        
                        // 完成按钮
                        Button(action: onDismiss) {
                            Text("back".localized)
                                .font(.pixel(18))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(Color("PixelBlue"))
                                .pixelBorderSmall(color: Color("PixelBlue"))
                        }
                        .padding(.top, 8)
                    }
                }
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation(.easeOut(duration: 0.5)) {
                    showContent = true
                }
            }
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yy/MM/dd"
        return formatter.string(from: date)
    }
    
    private func getCategoryName(_ category: String) -> String {
        return "category_\(category)".localized
    }
}
