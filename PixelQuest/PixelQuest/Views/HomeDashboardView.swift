import SwiftUI

enum HeatmapSource: String, CaseIterable, Identifiable {
    case combined = "合并"
    case bookkeeping = "记账"
    case items = "物品"

    var id: String { rawValue }
}

struct HeatmapDay: Identifiable {
    let date: Date
    let count: Int
    let isFuture: Bool

    var id: Date { date }
}

struct HomeDashboardView: View {
    @EnvironmentObject private var financeStore: SwiftDataFinanceStore
    @EnvironmentObject private var itemStore: SwiftDataItemStore

    let heroNamespace: Namespace.ID

    @State private var heatmapSource: HeatmapSource = .combined
    @State private var appear = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                header
                    .animatedSection(appear: appear, index: 0)

                bookkeepingOverviewCard
                    .animatedSection(appear: appear, index: 1)

                heatmapCard
                    .animatedSection(appear: appear, index: 2)

                itemsOverviewCard
                    .animatedSection(appear: appear, index: 3)

                recentSection
                    .animatedSection(appear: appear, index: 4)
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 40)
        }
        .scrollIndicators(.hidden)
        .background(PaperTextureBackground())
        .onAppear {
            withAnimation(.easeInOut(duration: 0.4)) {
                appear = true
            }
        }
        .toolbar(.hidden, for: .navigationBar)
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("首页")
                    .font(.system(size: 26, weight: .semibold))
                    .foregroundStyle(Color.pencilDark)
                Text("记账与物品概览")
                    .font(.system(size: 11, weight: .regular))
                    .foregroundStyle(Color.pencilLight)
            }

            Spacer()
        }
    }

    // MARK: - Bookkeeping Overview

    private var bookkeepingOverviewCard: some View {
        NavigationLink {
            BookkeepingView(heroNamespace: heroNamespace)
        } label: {
            VStack(alignment: .leading, spacing: 10) {
                // 标题行
                HStack {
                    Text("记账概览")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Color.pencilDark)
                    Spacer()
                    Text("本月")
                        .font(.system(size: 10, weight: .regular))
                        .foregroundStyle(Color.pencilLight)
                }

                // 金额区域 - 居中对齐
                VStack(spacing: 2) {
                    Text("总余额")
                        .font(.system(size: 10, weight: .regular))
                        .foregroundStyle(Color.pencilLight)

                    Text(Double(financeStore.totalBalance) / 100, format: .currency(code: "CNY").precision(.fractionLength(2)))
                        .font(.system(size: 32, weight: .regular))
                        .foregroundStyle(Color.pencilDark)
                        .ifAvailable17 { view in
                            view.contentTransition(.numericText())
                        }
                }
                .frame(maxWidth: .infinity, alignment: .center)

                // 收入/支出/净值 小标签
                HStack(spacing: 8) {
                    amountLabel(title: "收入", amount: financeStore.monthIncome)
                    amountLabel(title: "支出", amount: financeStore.monthExpense)
                    amountLabel(title: "净值", amount: financeStore.monthNet)
                }
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .pencilSketchCard()
            .matchedGeometryEffect(id: HomeHeroID.bookkeeping, in: heroNamespace)
        }
        .buttonStyle(.plain)
    }

    private func amountLabel(title: String, amount: Int) -> some View {
        HStack(spacing: 4) {
            Text(title)
                .font(.system(size: 10, weight: .regular))
                .foregroundStyle(Color.pencilLight)
            Text(Double(amount) / 100, format: .currency(code: "CNY").precision(.fractionLength(0)))
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(Color.pencilDark)
        }
        .padding(.vertical, 5)
        .padding(.horizontal, 8)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .stroke(Color.pencilStroke, lineWidth: 0.5)
        )
    }

    private func sketchAmountPill(title: String, amount: Int) -> some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(title)
                .font(.system(size: 9, weight: .regular))
                .foregroundStyle(Color.pencilLight)

            Text(Double(amount) / 100, format: .currency(code: "CNY").precision(.fractionLength(0)))
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(Color.pencilDark)
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 6)
        .pencilSketchBorder()
    }

    // MARK: - Heatmap

    private var heatmapCard: some View {
        let heatmap = heatmapData
        let gridData = heatmapGridData(from: heatmap.days, maxCount: heatmap.maxCount)

        return VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("热力图")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color.pencilDark)

                Spacer()

                // 分段选择器
                HStack(spacing: 0) {
                    ForEach(HeatmapSource.allCases) { source in
                        Button {
                            heatmapSource = source
                        } label: {
                            Text(source.rawValue)
                                .font(.system(size: 12, weight: heatmapSource == source ? .medium : .regular))
                                .foregroundStyle(heatmapSource == source ? Color.pencilDark : Color.pencilLight)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 7)
                                .background(
                                    heatmapSource == source ?
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(Color.paperWhite)
                                        .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.pencilStroke, lineWidth: 0.8))
                                    : nil
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.pencilStroke, lineWidth: 0.5)
                )
            }

            // 13x5 热力图网格 - 精确还原参考图
            HStack(alignment: .top, spacing: 4) {
                ForEach(0..<13, id: \.self) { col in
                    VStack(spacing: 4) {
                        ForEach(0..<5, id: \.self) { row in
                            PencilHeatmapCell(
                                intensity: gridData[col][row],
                                size: 18
                            )
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .center)
            .animation(.easeInOut(duration: 0.2), value: heatmapSource)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .pencilSketchCard()
    }

    /// 将热力图数据转换为13x5网格格式 (显示最近65天)
    private func heatmapGridData(from days: [HeatmapDay], maxCount: Int) -> [[Double]] {
        var grid: [[Double]] = Array(repeating: Array(repeating: 0.0, count: 5), count: 13)
        
        // 取最近65天的数据填充13x5网格
        // 注意：通常热力图是从左上到右下，或者左下到右上。
        // 参考图看起来是时间从左到右，每天一列？或者通常的周视图（一列是一周）？
        // 13列 x 5行 = 65格。
        // 如果是日历热力图，通常一列是一周（7天）。但这里是5行。
        // 可能是一列代表连续的5天？或者这只是一个抽象的并在布局？
        // 假设：从左到右是时间轴，每一列是连续的5天（不太可能）。
        // 通常做法：左上角是最早的日期，右下角是最新的日期。
        // 为了视觉对应，我们把最近的数据放在最后（右下角）。
        
        let totalCells = 13 * 5
        let recentDays = Array(days.suffix(totalCells))
        
        // 我们需要把一维数组映射到二维网格 [col][row]
        // 假设从左到右填充，列优先还是行优先？
        // 观察参考图：深色块集中在后面。
        // 我们按列填充：第一列是 Day 0-4, 第二列 Day 5-9...
        
        for (index, day) in recentDays.enumerated() {
            // 如果我们想让最新的日期在最右侧那一列的底部
            // index 0 应该是最早的日期
            
            let col = index / 5
            let row = index % 5
            
            if col < 13 && row < 5 {
                if day.isFuture {
                    grid[col][row] = 0.0
                } else if maxCount > 0 {
                    grid[col][row] = Double(day.count) / Double(maxCount)
                }
            }
        }
        return grid
    }

    private func pencilHeatmapCell(day: HeatmapDay, maxCount: Int) -> some View {
        let size: CGFloat = 14  // 稍微放大的格子
        let intensity = day.isFuture ? 0.0 : (maxCount > 0 ? Double(day.count) / Double(maxCount) : 0.0)
        
        return PencilHeatmapCell(intensity: intensity, size: size)
            .accessibilityLabel(heatmapAccessibilityLabel(for: day))
    }

    private func pencilHeatmapIntensity(count: Int, maxCount: Int, isFuture: Bool) -> Double {
        if isFuture { return 0.0 }
        if count == 0 { return 0.05 }
        return Double(count) / Double(max(maxCount, 1))
    }

    private func heatmapAccessibilityLabel(for day: HeatmapDay) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM-dd"
        return "\(formatter.string(from: day.date))，记录 \(day.count) 条"
    }

    private var heatmapData: (days: [HeatmapDay], maxCount: Int) {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let weekday = calendar.component(.weekday, from: today)
        let daysFromWeekStart = (weekday - calendar.firstWeekday + 7) % 7
        let startOfWeek = calendar.date(byAdding: .day, value: -daysFromWeekStart, to: today) ?? today
        let startDate = calendar.date(byAdding: .day, value: -(7 * 7), to: startOfWeek) ?? today
        let dayCount = 8 * 7

        let entryCounts = countsByDay(for: financeStore.entries.map { $0.date })
        let itemCounts = countsByDay(for: itemStore.items.map { $0.purchaseDate })

        var days: [HeatmapDay] = []
        var maxCount = 0

        for offset in 0..<dayCount {
            let date = calendar.date(byAdding: .day, value: offset, to: startDate) ?? today
            let key = calendar.startOfDay(for: date)
            let count: Int

            switch heatmapSource {
            case .bookkeeping:
                count = entryCounts[key, default: 0]
            case .items:
                count = itemCounts[key, default: 0]
            case .combined:
                count = entryCounts[key, default: 0] + itemCounts[key, default: 0]
            }

            maxCount = max(maxCount, count)
            days.append(HeatmapDay(date: key, count: count, isFuture: key > today))
        }

        return (days, max(maxCount, 1))
    }

    private func countsByDay(for dates: [Date]) -> [Date: Int] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: dates) { calendar.startOfDay(for: $0) }
        return grouped.mapValues { $0.count }
    }

    private func heatmapWeeks(from days: [HeatmapDay]) -> [[HeatmapDay]] {
        stride(from: 0, to: days.count, by: 7).map { index in
            Array(days[index..<min(index + 7, days.count)])
        }
    }

    // MARK: - Items Overview

    private var itemsOverviewCard: some View {
        NavigationLink {
            AssetsView(heroNamespace: heroNamespace)
        } label: {
            VStack(alignment: .leading, spacing: 10) {
                // 标题行
                HStack {
                    Text("物品概览")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Color.pencilDark)
                    Spacer()
                    Text("总览")
                        .font(.system(size: 10, weight: .regular))
                        .foregroundStyle(Color.pencilLight)
                }

                // 物品数量 - 居中大号显示
                VStack(spacing: 2) {
                    Text("物品总数")
                        .font(.system(size: 10, weight: .regular))
                        .foregroundStyle(Color.pencilLight)

                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text("\(itemStore.items.count)")
                            .font(.system(size: 36, weight: .regular))
                            .foregroundStyle(Color.pencilDark)
                            .ifAvailable17 { view in
                                view.contentTransition(.numericText())
                            }
                        Text("件")
                            .font(.system(size: 14, weight: .regular))
                            .foregroundStyle(Color.pencilLight)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .center)

                // 总价值和最近物品
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 4) {
                        Text("总价值")
                            .font(.system(size: 9, weight: .regular))
                            .foregroundStyle(Color.pencilLight)
                        Text(itemStore.formattedTotalValue)
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(Color.pencilDark)
                    }

                    if let latest = itemStore.items.first {
                        HStack(spacing: 4) {
                            Text("最近物品：")
                                .font(.system(size: 9, weight: .regular))
                                .foregroundStyle(Color.pencilLight)
                            Text(latest.name)
                                .font(.system(size: 10, weight: .medium))
                                .foregroundStyle(Color.pencilDark)
                                .lineLimit(1)
                        }
                    }
                }
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .pencilSketchCard()
            .matchedGeometryEffect(id: HomeHeroID.assets, in: heroNamespace)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Recent Section

    private var recentSection: some View {
        HStack(alignment: .top, spacing: 12) {
            recentEntriesCard
            recentItemsCard
        }
    }

    private var recentEntriesCard: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("最近记账")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Color.pencilDark)

            if financeStore.entries.isEmpty {
                Text("暂无记录")
                    .font(.system(size: 10, weight: .regular))
                    .foregroundStyle(Color.pencilLight)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 8)
            } else {
                ForEach(Array(financeStore.entries.prefix(3))) { entry in
                    HStack(spacing: 6) {
                        Image(systemName: entry.categoryInfo?.icon ?? "circle")
                            .font(.system(size: 10))
                            .foregroundStyle(Color.pencilMedium)
                            .frame(width: 14)
                        
                        Text(entry.categoryInfo?.name ?? "其他")
                            .font(.system(size: 10, weight: .regular))
                            .foregroundStyle(Color.pencilMedium)
                            .lineLimit(1)

                        Spacer()

                        Text(entry.signedAmountText)
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(Color.pencilDark)
                    }
                    .padding(.vertical, 2)
                }
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .pencilSketchCard()
    }

    private var recentItemsCard: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("最近物品")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Color.pencilDark)

            if itemStore.items.isEmpty {
                Text("暂无物品")
                    .font(.system(size: 10, weight: .regular))
                    .foregroundStyle(Color.pencilLight)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 8)
            } else {
                ForEach(Array(itemStore.items.prefix(3))) { item in
                    HStack(spacing: 6) {
                        Image(systemName: "cube.box")
                            .font(.system(size: 10))
                            .foregroundStyle(Color.pencilMedium)
                            .frame(width: 14)
                        
                        Text(item.name)
                            .font(.system(size: 10, weight: .regular))
                            .foregroundStyle(Color.pencilMedium)
                            .lineLimit(1)

                        Spacer()

                        Text("¥\(item.price)")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(Color.pencilDark)
                    }
                    .padding(.vertical, 2)
                }
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .pencilSketchCard()
    }
}

#Preview {
    struct HomePreview: View {
        @Namespace private var hero

        var body: some View {
            NavigationStack {
                HomeDashboardView(heroNamespace: hero)
                    .environmentObject(SwiftDataItemStore())
                    .environmentObject(SwiftDataFinanceStore())
                    .environmentObject(LocalizationManager.shared)
            }
        }
    }

    return HomePreview()
}

private extension View {
    @ViewBuilder
    func ifAvailable17(_ transform: (Self) -> some View) -> some View {
        if #available(iOS 17.0, *) {
            transform(self)
        } else {
            self
        }
    }

    func animatedSection(appear: Bool, index: Int) -> some View {
        let delay = Double(index) * 0.06
        return self
            .opacity(appear ? 1 : 0)
            .offset(y: appear ? 0 : 8)
            .animation(.easeInOut(duration: 0.4).delay(delay), value: appear)
    }
}
