import SwiftUI

struct AsymmetricDashboardView: View {
    @EnvironmentObject private var questStore: SwiftDataQuestStore
    @EnvironmentObject private var bookStore: SwiftDataBookStore
    @EnvironmentObject private var exerciseStore: SwiftDataExerciseStore
    @EnvironmentObject private var financeStore: SwiftDataFinanceStore
    @EnvironmentObject private var sleepStore: SwiftDataSleepStore

    @State private var showSettings = false

    var onStrengthTap: () -> Void
    var onIntellectTap: () -> Void
    var onHealthTap: () -> Void
    var onWealthTap: () -> Void
    var onSpiritTap: () -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                headerBar
                balanceHero
                quickStatsRow
                cardCluster
                operationCard
            }
            .padding(.horizontal, 16)
            .padding(.top, 14)
            .padding(.bottom, 108)
        }
        .scrollIndicators(.hidden)
        .sheet(isPresented: $showSettings) {
            NavigationStack {
                SettingsView()
                    .toolbar {
                        ToolbarItem(placement: .confirmationAction) {
                            Button("done".localized) { showSettings = false }
                                .font(.pixel(16))
                        }
                    }
            }
        }
    }

    private var headerBar: some View {
        HStack(spacing: 12) {
            Button(action: { showSettings = true }) {
                ZStack {
                    Rectangle()
                        .fill(Color("PixelAccent").opacity(0.2))
                        .frame(width: 44, height: 44)

                    Image(systemName: "person.fill")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(Color("PixelAccent"))
                }
                .pixelBorderSmall(color: Color("PixelBorder"))
            }
            .buttonStyle(.plain)

            Spacer()

            DashboardPill(text: "Wallets")
            DashboardPill(text: "Menu", icon: "line.3.horizontal")
        }
    }

    private var balanceHero: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("All sources")
                .font(.pixel(13))
                .foregroundStyle(Color("PixelBorder").opacity(0.6))

            Text("Total Balance")
                .font(.pixel(36))
                .foregroundStyle(Color("PixelBorder"))

            HStack(spacing: 8) {
                ForEach(walletChips, id: \.self) { chip in
                    DashboardPill(text: chip, compact: true)
                }

                Button(action: onSpiritTap) {
                    DashboardPill(text: "Quests", compact: true)
                }
                .buttonStyle(.plain)
            }

            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text("¥\(financeStore.formattedNetWorth)")
                    .font(.pixel(36))
                    .foregroundStyle(Color("PixelBorder"))

                Text("usd")
                    .font(.pixel(15))
                    .foregroundStyle(Color("PixelBorder").opacity(0.6))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var quickStatsRow: some View {
        HStack(spacing: 10) {
            QuickStatPill(
                title: "Streak",
                value: "\(questStore.currentStreak)d",
                icon: "flame.fill",
                accent: Color("PixelAccent"),
                background: Color("PixelButter")
            )

            QuickStatPill(
                title: "Read",
                value: "\(bookStore.readingBooks.count) active",
                icon: "book.fill",
                accent: Color("PixelPeach"),
                background: Color("PixelPeach").opacity(0.65)
            )

            QuickStatPill(
                title: "Sport",
                value: "\(exerciseStore.weekTotalDuration) min",
                icon: "figure.run",
                accent: Color("PixelMint"),
                background: Color("PixelMint").opacity(0.7)
            )
        }
    }

    private var cardCluster: some View {
        ViewThatFits {
            HStack(alignment: .top, spacing: 14) {
                heroLeftCard
                VStack(spacing: 14) {
                    miniSubscriptionCard
                    miniRecoveryCard
                }
            }
            VStack(spacing: 14) {
                heroLeftCard
                HStack(spacing: 14) {
                    miniSubscriptionCard
                    miniRecoveryCard
                }
            }
        }
    }

    private var heroLeftCard: some View {
        Button(action: onWealthTap) {
            VStack(alignment: .leading, spacing: 10) {
                Text("Spent this week")
                    .font(.pixel(13))
                    .foregroundStyle(Color("PixelBorder").opacity(0.7))

                Text("¥\(weekExpenseText)")
                    .font(.pixel(24))
                    .foregroundStyle(Color("PixelBorder"))

                HStack(spacing: 6) {
                    Image(systemName: weekTrend >= 0 ? "arrow.up.circle.fill" : "arrow.down.circle.fill")
                        .font(.system(size: 13))
                        .foregroundStyle(weekTrend >= 0 ? Color("PixelGreen") : Color("PixelRed"))

                    Text(weekTrendText)
                        .font(.pixel(13))
                        .foregroundStyle(Color("PixelBorder").opacity(0.7))
                }

                Spacer(minLength: 6)

                AsymmetricStairChart(values: weeklySpots, accent: Color("PixelAccent"))
                    .frame(height: 86)
            }
            .padding(14)
            .frame(maxWidth: .infinity, minHeight: 205, alignment: .leading)
            .dashboardCard(background: Color("PixelButter"))
        }
        .buttonStyle(.plain)
    }

    private var miniSubscriptionCard: some View {
        Button(action: onIntellectTap) {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    ZStack {
                        Rectangle()
                            .fill(Color("PixelPeach").opacity(0.5))
                            .frame(width: 28, height: 28)
                            .overlay(Rectangle().stroke(Color("PixelBorder").opacity(0.3), lineWidth: 1))
                        Image(systemName: "sparkles")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(Color("PixelAccent"))
                    }
                    Spacer()
                }

                Text("Subscription")
                    .font(.pixel(15))
                    .foregroundStyle(Color("PixelBorder"))

                Text("Books")
                    .font(.pixel(13))
                    .foregroundStyle(Color("PixelBorder").opacity(0.6))

                Spacer(minLength: 6)

                Text("\(bookStore.readingBooks.count) active")
                    .font(.pixel(15))
                    .foregroundStyle(Color("PixelBorder"))
            }
            .padding(12)
            .frame(maxWidth: .infinity, minHeight: 128, alignment: .leading)
            .dashboardCard(background: Color("PixelPeach").opacity(0.65))
        }
        .buttonStyle(.plain)
    }

    private var miniRecoveryCard: some View {
        Button(action: onHealthTap) {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    ZStack {
                        Rectangle()
                            .fill(Color("PixelMint").opacity(0.6))
                            .frame(width: 28, height: 28)
                            .overlay(Rectangle().stroke(Color("PixelBorder").opacity(0.3), lineWidth: 1))
                        Image(systemName: "moon.stars.fill")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(Color("PixelBlue"))
                    }
                    Spacer()
                }

                Text("Recovery")
                    .font(.pixel(15))
                    .foregroundStyle(Color("PixelBorder"))

                Text("\(sleepStore.weekEntries.count) logs")
                    .font(.pixel(13))
                    .foregroundStyle(Color("PixelBorder").opacity(0.6))

                Spacer(minLength: 6)

                Text("\(Int(sleepStore.averageQuality)) QLT")
                    .font(.pixel(15))
                    .foregroundStyle(Color("PixelBorder"))
            }
            .padding(12)
            .frame(maxWidth: .infinity, minHeight: 128, alignment: .leading)
            .dashboardCard(background: Color("PixelMint").opacity(0.7))
        }
        .buttonStyle(.plain)
    }

    private var operationCard: some View {
        Button(action: onStrengthTap) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Operation")
                        .font(.pixel(17))
                        .foregroundStyle(Color("PixelButter"))
                    Spacer()
                    Text("Last week")
                        .font(.pixel(13))
                        .foregroundStyle(Color.white.opacity(0.7))
                }

                Text("¥\(todayExpenseText)")
                    .font(.pixel(22))
                    .foregroundStyle(.white)

                Text("Spent this day")
                    .font(.pixel(13))
                    .foregroundStyle(Color.white.opacity(0.7))

                CozyProgressBar(
                    value: Double(min(exerciseStore.weekTotalDuration, 100)),
                    maxValue: 100,
                    totalBlocks: 10,
                    filledColor: Color("PixelGreen"),
                    emptyColor: Color.white.opacity(0.12),
                    borderColor: Color.white.opacity(0.5),
                    blockSpacing: 3,
                    height: 12,
                    cornerRadius: 0
                )

                HStack(spacing: 10) {
                    Rectangle()
                        .fill(Color("PixelAccent"))
                        .frame(width: 16, height: 16)
                        .overlay(
                            Rectangle()
                                .stroke(Color.white.opacity(0.6), lineWidth: 1)
                        )

                    VStack(alignment: .leading, spacing: 2) {
                        Text(lastEntryTitle)
                            .font(.pixel(13))
                            .foregroundStyle(.white)
                        Text(lastEntryTime)
                            .font(.pixel(11))
                            .foregroundStyle(Color.white.opacity(0.6))
                    }

                    Spacer()

                    Text(lastEntryAmount)
                        .font(.pixel(13))
                        .foregroundStyle(.white)
                }
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .dashboardCard(background: Color("PixelBorder"))
        }
        .buttonStyle(.plain)
    }

    private var weekExpense: Int {
        let calendar = Calendar.current
        let today = Date()
        guard let start = calendar.date(byAdding: .day, value: -6, to: today) else { return 0 }
        return financeStore.entries
            .filter { $0.isExpense && $0.date >= start }
            .reduce(0) { $0 + $1.amount }
    }

    private var previousWeekExpense: Int {
        let calendar = Calendar.current
        let today = Date()
        guard
            let start = calendar.date(byAdding: .day, value: -13, to: today),
            let end = calendar.date(byAdding: .day, value: -7, to: today)
        else { return 0 }

        return financeStore.entries
            .filter { $0.isExpense && $0.date >= start && $0.date <= end }
            .reduce(0) { $0 + $1.amount }
    }

    private var weekTrend: Double {
        guard previousWeekExpense > 0 else { return 0 }
        return Double(weekExpense - previousWeekExpense) / Double(previousWeekExpense)
    }

    private var weekTrendText: String {
        let percent = Int(abs(weekTrend) * 100)
        return "\(percent)% \(weekTrend >= 0 ? "higher" : "lower")"
    }

    private var weekExpenseText: String {
        (Double(weekExpense) / 100.0).formatted(.number.precision(.fractionLength(2)))
    }

    private var todayExpenseText: String {
        let todayExpense = financeStore.todayEntries.filter { $0.isExpense }.reduce(0) { $0 + $1.amount }
        return (Double(todayExpense) / 100.0).formatted(.number.precision(.fractionLength(2)))
    }

    private var walletChips: [String] {
        let names = financeStore.wallets.prefix(2).map { $0.name }
        return names.isEmpty ? ["Main Wallet"] : names
    }

    private var weeklySpots: [Double] {
        var values: [Double] = []
        let calendar = Calendar.current
        let today = Date()

        for dayOffset in (0..<5).reversed() {
            guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: today) else { continue }
            let total = financeStore.entries
                .filter { calendar.isDate($0.date, inSameDayAs: date) && $0.isExpense }
                .reduce(0) { $0 + $1.amount }
            values.append(min(1, Double(total) / 50000))
        }

        return values
    }

    private var lastEntryTitle: String {
        guard let entry = financeStore.entries.first else { return "No records" }
        return entry.note?.isEmpty == false ? entry.note! : entry.category
    }

    private var lastEntryAmount: String {
        guard let entry = financeStore.entries.first else { return "--" }
        let amountText = (Double(entry.amount) / 100.0).formatted(.number.precision(.fractionLength(2)))
        return "\(entry.isExpense ? "-" : "+")¥\(amountText)"
    }

    private var lastEntryTime: String {
        guard let entry = financeStore.entries.first else { return "" }
        return entry.date.formatted(date: .omitted, time: .shortened)
    }
}

private struct DashboardPill: View {
    var text: String
    var icon: String? = nil
    var compact: Bool = false

    var body: some View {
        HStack(spacing: 6) {
            if let icon {
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .bold))
            }
            Text(text)
                .font(.pixel(compact ? 12 : 13))
        }
        .foregroundStyle(Color("PixelBorder"))
        .padding(.horizontal, compact ? 8 : 10)
        .padding(.vertical, compact ? 4 : 6)
        .background(Color.white.opacity(0.7))
        .overlay(
            Rectangle()
                .stroke(Color("PixelBorder").opacity(0.4), lineWidth: 1)
        )
    }
}

private struct QuickStatPill: View {
    let title: String
    let value: String
    let icon: String
    let accent: Color
    let background: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Rectangle()
                    .fill(accent.opacity(0.25))
                    .frame(width: 18, height: 18)
                    .overlay(
                        Image(systemName: icon)
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(accent)
                    )

                Text(title)
                    .font(.pixel(12))
                    .foregroundStyle(Color("PixelBorder").opacity(0.7))
            }

            Text(value)
                .font(.pixel(15))
                .foregroundStyle(Color("PixelBorder"))
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(background)
        .overlay(
            Rectangle()
                .stroke(Color("PixelBorder").opacity(0.5), lineWidth: 1)
        )
    }
}

private struct AsymmetricStairChart: View {
    let values: [Double]
    let accent: Color

    var body: some View {
        HStack(alignment: .bottom, spacing: 6) {
            ForEach(values.indices, id: \.self) { index in
                VStack(spacing: 4) {
                    ForEach(0..<4, id: \.self) { step in
                        Rectangle()
                            .fill(step < Int(values[index] * 4) ? accent : accent.opacity(0.15))
                            .frame(width: 18, height: 10)
                    }
                }
            }
        }
    }
}

private extension View {
    func dashboardCard(background: Color) -> some View {
        self
            .background(background)
            .overlay(
                Rectangle()
                    .stroke(Color("PixelBorder"), lineWidth: 2)
            )
            .background(
                Rectangle()
                    .fill(Color("PixelBorder").opacity(0.2))
                    .offset(x: 4, y: 4)
            )
    }
}

private extension SwiftDataFinanceStore {
    var formattedNetWorth: String {
        (Double(netWorth) / 100.0).formatted(.number.precision(.fractionLength(2)))
    }
}

#Preview {
    AsymmetricDashboardView(
        onStrengthTap: {},
        onIntellectTap: {},
        onHealthTap: {},
        onWealthTap: {},
        onSpiritTap: {}
    )
    .environmentObject(SwiftDataQuestStore())
    .environmentObject(SwiftDataBookStore())
    .environmentObject(SwiftDataExerciseStore())
    .environmentObject(SwiftDataFinanceStore())
    .environmentObject(SwiftDataSleepStore())
    .background(Color("PixelBg"))
}
