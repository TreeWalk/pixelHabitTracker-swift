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
        .background(Color.creamBg)
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
            VStack(alignment: .leading, spacing: 4) {
                Text("首页")
                    .font(.pixelHeader(28))
                    .foregroundStyle(Color.darkCoffee)
                Text("记账与物品概览")
                    .font(.pixel(12))
                    .foregroundStyle(Color.lightCoffee)
            }

            Spacer()

            Circle()
                .fill(Color.warmButter)
                .frame(width: 36, height: 36)
                .overlay(
                    Image(systemName: "person.fill")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(Color.darkCoffee)
                )
                .cozyBorder(lineWidth: 3)
        }
    }

    // MARK: - Bookkeeping Overview

    private var bookkeepingOverviewCard: some View {
        NavigationLink {
            BookkeepingView(heroNamespace: heroNamespace)
        } label: {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("记账概览")
                        .font(.pixelHeader(20))
                        .foregroundStyle(Color.darkCoffee)

                    Spacer()

                    Text("本月")
                        .font(.pixel(12))
                        .foregroundStyle(Color.lightCoffee)
                }

                Text("总余额")
                    .font(.pixel(12))
                    .foregroundStyle(Color.lightCoffee)

                Text(Double(financeStore.totalBalance) / 100, format: .currency(code: "CNY").precision(.fractionLength(2)))
                    .font(.pixelHeader(32))
                    .foregroundStyle(Color.darkCoffee)
                    .ifAvailable17 { view in
                        view.contentTransition(.numericText())
                    }

                HStack(spacing: 12) {
                    amountPill(title: "收入", amount: financeStore.monthIncome, tint: Color("PixelGreen"))
                    amountPill(title: "支出", amount: financeStore.monthExpense, tint: Color("PixelRed"))
                    amountPill(title: "净值", amount: financeStore.monthNet, tint: Color("PixelAccent"))
                }
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .cozyCard(backgroundColor: .white, borderWidth: 3)
            .matchedGeometryEffect(id: HomeHeroID.bookkeeping, in: heroNamespace)
        }
        .buttonStyle(.plain)
    }

    private func amountPill(title: String, amount: Int, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.pixel(11))
                .foregroundStyle(Color.lightCoffee)

            Text(Double(amount) / 100, format: .currency(code: "CNY").precision(.fractionLength(2)))
                .font(.pixel(14))
                .foregroundStyle(tint)
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 8)
        .cozyBorder(color: Color.darkCoffee.opacity(0.3), lineWidth: 2)
    }

    // MARK: - Heatmap

    private var heatmapCard: some View {
        let heatmap = heatmapData
        let weeks = heatmapWeeks(from: heatmap.days)

        return VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Text("热力图")
                    .font(.pixelHeader(18))
                    .foregroundStyle(Color.darkCoffee)

                Spacer()

                Picker("Source", selection: $heatmapSource) {
                    ForEach(HeatmapSource.allCases) { source in
                        Text(source.rawValue)
                            .tag(source)
                    }
                }
                .pickerStyle(.segmented)
                .frame(maxWidth: 220)
            }

            HStack(alignment: .top, spacing: 4) {
                ForEach(weeks.indices, id: \.self) { index in
                    VStack(spacing: 4) {
                        ForEach(weeks[index]) { day in
                            heatmapCell(day: day, maxCount: heatmap.maxCount)
                        }
                    }
                }
            }
            .animation(.easeInOut(duration: 0.2), value: heatmapSource)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .cozyCard(backgroundColor: .white, borderWidth: 3)
    }

    private func heatmapCell(day: HeatmapDay, maxCount: Int) -> some View {
        let size: CGFloat = 12
        let color = heatmapColor(count: day.count, maxCount: maxCount, isFuture: day.isFuture)

        return Rectangle()
            .fill(color)
            .frame(width: size, height: size)
            .overlay(
                Rectangle()
                    .stroke(Color.darkCoffee.opacity(0.15), lineWidth: 1)
            )
            .accessibilityLabel(heatmapAccessibilityLabel(for: day))
    }

    private func heatmapColor(count: Int, maxCount: Int, isFuture: Bool) -> Color {
        if isFuture {
            return Color.darkCoffee.opacity(0.06)
        }
        if count == 0 {
            return Color.darkCoffee.opacity(0.08)
        }

        let normalized = Double(count) / Double(max(maxCount, 1))
        let bucket = Int((normalized * 4).rounded(.up))
        let level = max(1, min(4, bucket))

        switch level {
        case 1: return Color("PixelAccent").opacity(0.25)
        case 2: return Color("PixelAccent").opacity(0.45)
        case 3: return Color("PixelAccent").opacity(0.7)
        default: return Color("PixelAccent").opacity(0.95)
        }
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
                HStack {
                    Text("物品概览")
                        .font(.pixelHeader(20))
                        .foregroundStyle(Color.darkCoffee)

                    Spacer()

                    Text("总览")
                        .font(.pixel(12))
                        .foregroundStyle(Color.lightCoffee)
                }

                Text("物品总数")
                    .font(.pixel(12))
                    .foregroundStyle(Color.lightCoffee)

                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text("\(itemStore.items.count)")
                        .font(.pixelHeader(32))
                        .foregroundStyle(Color.darkCoffee)
                        .ifAvailable17 { view in
                            view.contentTransition(.numericText())
                        }

                    Text("件")
                        .font(.pixel(14))
                        .foregroundStyle(Color.lightCoffee)
                }

                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("总价值")
                            .font(.pixel(11))
                            .foregroundStyle(Color.lightCoffee)
                        Text(itemStore.formattedTotalValue)
                            .font(.pixel(14))
                            .foregroundStyle(Color("PixelAccent"))
                    }

                    if let latest = itemStore.items.first {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("最近物品")
                                .font(.pixel(11))
                                .foregroundStyle(Color.lightCoffee)
                            Text(latest.name)
                                .font(.pixel(14))
                                .foregroundStyle(Color.darkCoffee)
                                .lineLimit(1)
                        }
                    }
                }
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .cozyCard(backgroundColor: .white, borderWidth: 3)
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
        VStack(alignment: .leading, spacing: 10) {
            Text("最近记账")
                .font(.pixelHeader(16))
                .foregroundStyle(Color.darkCoffee)

            if financeStore.entries.isEmpty {
                Text("暂无记录")
                    .font(.pixel(12))
                    .foregroundStyle(Color.lightCoffee)
            } else {
                ForEach(Array(financeStore.entries.prefix(3))) { entry in
                    HStack {
                        Text(entry.categoryInfo?.name ?? "其他")
                            .font(.pixel(12))
                            .foregroundStyle(Color.darkCoffee)
                            .lineLimit(1)

                        Spacer()

                        Text(entry.signedAmountText)
                            .font(.pixel(12))
                            .foregroundStyle(entry.isExpense ? Color("PixelRed") : Color("PixelGreen"))
                    }
                }
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .cozyCard(backgroundColor: .white, borderWidth: 3)
    }

    private var recentItemsCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("最近物品")
                .font(.pixelHeader(16))
                .foregroundStyle(Color.darkCoffee)

            if itemStore.items.isEmpty {
                Text("暂无物品")
                    .font(.pixel(12))
                    .foregroundStyle(Color.lightCoffee)
            } else {
                ForEach(Array(itemStore.items.prefix(3))) { item in
                    HStack {
                        Text(item.name)
                            .font(.pixel(12))
                            .foregroundStyle(Color.darkCoffee)
                            .lineLimit(1)

                        Spacer()

                        Text("¥\(item.price)")
                            .font(.pixel(12))
                            .foregroundStyle(Color("PixelAccent"))
                    }
                }
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .cozyCard(backgroundColor: .white, borderWidth: 3)
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
