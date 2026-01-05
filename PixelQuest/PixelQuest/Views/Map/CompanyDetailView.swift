import SwiftUI

struct CompanyDetailView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var financeStore: SwiftDataFinanceStore
    @EnvironmentObject var localizationManager: LocalizationManager
    let location: Location
    
    @State private var selectedTab: Int = 0
    @State private var showQuickEntry = false
    @State private var showReconcile = false
    
    var body: some View {
        GeometryReader { geometry in
            let contentWidth = max(0, geometry.size.width - 32) // 确保非负
            
            ZStack {
                Color("PixelBg").ignoresSafeArea()
                
                if financeStore.wallets.isEmpty {
                    // 加载中或无数据
                    VStack {
                        ProgressView()
                        Text("Loading...")
                            .font(.pixel(16))
                            .foregroundColor(.secondary)
                            .padding(.top, 8)
                    }
                } else {
                    VStack(spacing: 0) {
                        // Custom Tab Bar
                        HStack(spacing: 0) {
                            TabButton(
                                title: "finance_transactions".localized,
                                icon: "list.bullet.rectangle.fill",
                                isSelected: selectedTab == 0,
                                action: { selectedTab = 0 }
                            )
                            
                            TabButton(
                                title: "finance_reconcile".localized,
                                icon: "wallet.pass.fill",
                                isSelected: selectedTab == 1,
                                action: { selectedTab = 1 }
                            )
                        }
                        .background(Color.white)
                        .pixelBorderSmall()
                        .padding(.horizontal, 16)
                        .padding(.top, 8)
                        
                        // Tab Content
                        TabView(selection: $selectedTab) {
                            TransactionsTab(
                                financeStore: financeStore,
                                contentWidth: contentWidth,
                                onQuickEntry: { showQuickEntry = true }
                            )
                            .tag(0)
                            
                            ReconciliationTab(
                                financeStore: financeStore,
                                contentWidth: contentWidth,
                                onReconcile: { showReconcile = true }
                            )
                            .tag(1)
                        }
                        .tabViewStyle(.page(indexDisplayMode: .never))
                    }
                }
            }
        }
        .navigationTitle(location.name)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { dismiss() }) {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.left")
                        Text("back".localized)
                    }
                    .font(.pixel(16))
                    .foregroundColor(Color("PixelBorder"))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color("PixelAccent"))
                    .pixelBorderSmall()
                }
            }
        }
        .sheet(isPresented: $showQuickEntry) {
            QuickEntrySheet()
        }
        .sheet(isPresented: $showReconcile) {
            ReconcileSheet()
        }
    }
}

// MARK: - Tab Button

struct TabButton: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                Text(title)
                    .font(.pixel(20))
            }
            .foregroundColor(isSelected ? .white : Color("PixelBorder"))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(isSelected ? Color("PixelAccent") : Color.clear)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Transactions Tab

struct TransactionsTab: View {
    @ObservedObject var financeStore: SwiftDataFinanceStore
    let contentWidth: CGFloat
    let onQuickEntry: () -> Void
    
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            ScrollView {
                VStack(spacing: 16) {
                    // 月度统计
                    MonthStatsCard(
                        income: financeStore.monthIncome,
                        expense: financeStore.monthExpense,
                        net: financeStore.monthNet
                    )
                    .frame(width: contentWidth)
                    .padding(.top, 16)
                    
                    // 流水列表
                    ForEach(financeStore.entriesGroupedByDate(), id: \.date) { group in
                        VStack(alignment: .leading, spacing: 8) {
                            // 日期标题
                            HStack {
                                Image(systemName: "calendar")
                                    .font(.system(size: 14))
                                    .foregroundColor(Color("PixelBlue"))
                                Text(formatDateHeader(group.date))
                                    .font(.pixel(16))
                                    .foregroundColor(Color("PixelBorder"))
                                Spacer()
                            }
                            .padding(.horizontal, 16)
                            
                            // 记录列表
                            ForEach(group.entries) { entry in
                                EntryRow(entry: entry)
                                    .padding(.horizontal, 16)
                                    .swipeActions(edge: .trailing) {
                                        Button(role: .destructive) {
                                            financeStore.deleteEntry(entry)
                                        } label: {
                                            Label("delete".localized, systemImage: "trash")
                                        }
                                    }
                            }
                        }
                    }
                    
                    if financeStore.entries.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "doc.text")
                                .font(.system(size: 48))
                                .foregroundColor(.secondary)
                            Text("finance_no_records".localized)
                                .font(.pixel(16))
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 60)
                    }
                }
                .padding(.bottom, 100)
            }
            
            // FAB
            Button(action: onQuickEntry) {
                Image(systemName: "plus")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 56, height: 56)
                    .background(Color("PixelAccent"))
                    .pixelBorderSmall(color: Color("PixelAccent"))
            }
            .padding(24)
        }
    }
    
    private func formatDateHeader(_ date: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            return "date_today".localized
        } else if calendar.isDateInYesterday(date) {
            return "date_yesterday".localized
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "MM-dd"
            return formatter.string(from: date)
        }
    }
}

// MARK: - Month Stats Card

struct MonthStatsCard: View {
    let income: Int
    let expense: Int
    let net: Int
    
    var body: some View {
        HStack(spacing: 20) {
            StatItem(title: "finance_month_income".localized, amount: income, isPositive: true)
            
            Rectangle()
                .fill(Color("PixelBorder").opacity(0.2))
                .frame(width: 2)
            
            StatItem(title: "finance_month_expense".localized, amount: expense, isPositive: false)
            
            Rectangle()
                .fill(Color("PixelBorder").opacity(0.2))
                .frame(width: 2)
            
            StatItem(title: "finance_net".localized, amount: net, isPositive: net >= 0)
        }
        .padding()
        .background(Color.white)
        .pixelBorderSmall()
    }
}

struct StatItem: View {
    let title: String
    let amount: Int
    let isPositive: Bool
    
    var body: some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.pixel(12))
                .foregroundColor(.secondary)
            Text(formatAmount(amount, showSign: true))
                .font(.pixel(18))
                .foregroundColor(isPositive ? Color("PixelGreen") : Color("PixelRed"))
        }
        .frame(maxWidth: .infinity)
    }
    
    private func formatAmount(_ amount: Int, showSign: Bool) -> String {
        let yuan = Double(amount) / 100.0
        if showSign {
            return String(format: amount >= 0 ? "+%.2f" : "%.2f", yuan)
        }
        return String(format: "%.2f", yuan)
    }
}

// MARK: - Entry Row

struct EntryRow: View {
    let entry: FinanceEntryData
    
    var body: some View {
        HStack(spacing: 12) {
            // 分类图标
            if let info = entry.categoryInfo {
                Image(systemName: info.icon)
                    .font(.system(size: 20))
                    .foregroundColor(entry.isExpense ? Color("PixelRed") : Color("PixelGreen"))
                    .frame(width: 40, height: 40)
                    .background(entry.isExpense ? Color("PixelRed").opacity(0.1) : Color("PixelGreen").opacity(0.1))
                    .pixelBorderSmall(color: (entry.isExpense ? Color("PixelRed") : Color("PixelGreen")).opacity(0.3))
            }
            
            // 信息
            VStack(alignment: .leading, spacing: 4) {
                Text(entry.categoryInfo?.name ?? "其他")
                    .font(.pixel(16))
                    .foregroundColor(Color("PixelBorder"))
                
                if let note = entry.note, !note.isEmpty {
                    Text(note)
                        .font(.pixel(12))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                // 金额
                Text(entry.signedAmountText)
                    .font(.pixel(18))
                    .foregroundColor(entry.isExpense ? Color("PixelRed") : Color("PixelGreen"))
                
                // 时间
                Text(entry.formattedDate)
                    .font(.pixel(12))
                    .foregroundColor(.secondary)
            }
        }
        .padding(12)
        .background(Color.white)
        .pixelBorderSmall()
    }
}

// MARK: - Reconciliation Tab

struct ReconciliationTab: View {
    @ObservedObject var financeStore: SwiftDataFinanceStore
    let contentWidth: CGFloat
    let onReconcile: () -> Void
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // 总资产卡片
                TotalAssetsCard(
                    total: financeStore.totalBalance,
                    lastUpdated: financeStore.latestSnapshot?.date
                )
                .frame(width: contentWidth)
                .padding(.top, 16)
                
                // 钱包列表
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(financeStore.wallets) { wallet in
                            WalletMiniCard(
                                wallet: wallet,
                                balance: financeStore.latestSnapshot?.balance(for: wallet.walletId) ?? 0
                            )
                        }
                    }
                    .padding(.horizontal, 16)
                }
                
                // 开始核对按钮
                Button(action: onReconcile) {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                        Text("finance_start_reconcile".localized)
                            .font(.pixel(20))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color("PixelBlue"))
                    .pixelBorderSmall(color: Color("PixelBlue"))
                }
                .frame(width: contentWidth)
                
                // 历史核对记录
                if !financeStore.snapshots.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "clock.arrow.circlepath")
                                .font(.system(size: 14))
                            Text("finance_history_records".localized)
                                .font(.pixel(16))
                                .foregroundColor(Color("PixelBorder"))
                        }
                        .padding(.horizontal, 16)
                        
                        ForEach(Array(financeStore.snapshots.sorted { $0.date > $1.date }.prefix(5))) { snapshot in
                            HistoryRow(snapshot: snapshot)
                                .padding(.horizontal, 16)
                        }
                    }
                }
            }
            .padding(.bottom, 24)
        }
    }
}

// MARK: - Total Assets Card

struct TotalAssetsCard: View {
    let total: Int
    let lastUpdated: Date?
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: "wallet.pass.fill")
                    .font(.system(size: 20))
                Text("finance_total_assets".localized)
                    .font(.pixel(18))
                Spacer()
            }
            .foregroundColor(Color("PixelBorder"))
            
            HStack {
                Text("¥")
                    .font(.pixel(28))
                Text(String(format: "%.2f", Double(total) / 100.0))
                    .font(.pixel(36))
                Spacer()
            }
            .foregroundColor(Color("PixelAccent"))
            
            if let date = lastUpdated {
                HStack {
                    Text("finance_last_reconcile".localized + ": \(formatDate(date))")
                        .font(.pixel(12))
                        .foregroundColor(.secondary)
                    Spacer()
                }
            }
        }
        .padding()
        .background(Color.white)
        .pixelBorderSmall()
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        return formatter.string(from: date)
    }
}

// MARK: - Wallet Mini Card

struct WalletMiniCard: View {
    let wallet: WalletData
    let balance: Int
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: wallet.icon)
                .font(.system(size: 24))
                .foregroundColor(Color(wallet.color))
            
            Text(wallet.displayName)
                .font(.pixel(14))
                .foregroundColor(Color("PixelBorder"))
            
            Text("¥\(String(format: "%.2f", Double(balance) / 100.0))")
                .font(.pixel(16))
                .foregroundColor(Color("PixelBorder"))
        }
        .frame(width: 90, height: 100)
        .background(Color.white)
        .pixelBorderSmall(color: Color(wallet.color).opacity(0.5))
    }
}

// MARK: - History Row

struct HistoryRow: View {
    let snapshot: WalletSnapshotData
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(formatDate(snapshot.date))
                    .font(.pixel(14))
                    .foregroundColor(Color("PixelBorder"))
                Text("¥\(snapshot.formattedTotalBalance)")
                    .font(.pixel(12))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(Color("PixelGreen"))
        }
        .padding(12)
        .background(Color.white)
        .pixelBorderSmall()
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        return formatter.string(from: date)
    }
}
