import SwiftUI

enum AssetsViewMode: String, CaseIterable {
    case rpg = "RPG"
    case finance = "Finance"
}

struct AssetsView: View {
    @EnvironmentObject var itemStore: SwiftDataItemStore
    @EnvironmentObject var financeStore: SwiftDataFinanceStore
    @State private var viewMode: AssetsViewMode = .rpg
    @State private var showAddItemSheet = false
    @State private var selectedItem: ItemData?
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Mode Picker
                Picker("Mode", selection: $viewMode) {
                    ForEach(AssetsViewMode.allCases, id: \.self) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .padding()
                
                // Content based on mode
                if viewMode == .rpg {
                    rpgModeContent
                } else {
                    financeModeContent
                }
            }
            .background(Color("PixelBg"))
            .navigationTitle("assets_title".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if viewMode == .rpg {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: { showAddItemSheet = true }) {
                            HStack(spacing: 4) {
                                Image(systemName: "plus")
                                    .font(.system(size: 14, weight: .bold))
                                Text("ADD")
                                    .font(.pixel(12))
                            }
                            .foregroundColor(Color("PixelBorder"))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color("PixelAccent"))
                            .pixelBorderSmall()
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showAddItemSheet) {
            AddItemSheet()
        }
        .sheet(item: $selectedItem) { item in
            ItemDataDetailSheet(item: item) {
                itemStore.deleteItem(item)
                selectedItem = nil
            }
        }
    }
    
    // MARK: - RPG Mode (Bag)
    private var rpgModeContent: some View {
        Group {
            if itemStore.items.isEmpty {
                // Empty state
                VStack(spacing: 20) {
                    Spacer()
                    
                    Image(systemName: "cube.box")
                        .font(.system(size: 60))
                        .foregroundColor(Color("PixelBorder").opacity(0.3))
                    
                    Text("还没有记录任何物品")
                        .font(.pixel(18))
                        .foregroundColor(.secondary)
                    
                    Text("添加你的第一个物品，开始追踪使用价值")
                        .font(.pixel(14))
                        .foregroundColor(.secondary.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                    
                    Button(action: { showAddItemSheet = true }) {
                        HStack {
                            Image(systemName: "plus")
                            Text("添加物品")
                                .font(.pixel(16))
                        }
                        .foregroundColor(Color("PixelBorder"))
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(Color("PixelAccent"))
                        .pixelBorderSmall()
                    }
                    .padding(.top, 10)
                    
                    Spacer()
                }
            } else {
                ScrollView {
                    // Stats Row  
                    HStack(spacing: 16) {
                        StatBadge(
                            icon: "cube.fill",
                            value: "\(itemStore.items.count)",
                            label: "件物品"
                        )
                        
                        StatBadge(
                            icon: "yensign.circle.fill",
                            value: "¥\(itemStore.totalValue)",
                            label: "总价值"
                        )
                        
                        StatBadge(
                            icon: "chart.line.downtrend.xyaxis",
                            value: String(format: "¥%.1f", itemStore.averageDailyCost),
                            label: "日均成本"
                        )
                    }
                    .padding()
                    
                    LazyVStack(spacing: 12) {
                        ForEach(itemStore.items, id: \.itemId) { item in
                            ItemDataCard(item: item) {
                                selectedItem = item
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom)
                }
            }
        }
    }
    
    // MARK: - Finance Mode
    private var financeModeContent: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Net Worth Card
                VStack(spacing: 8) {
                    Text("net_worth".localized)
                        .font(.pixel(14))
                        .foregroundColor(.secondary)
                    
                    Text("¥\(financeStore.netWorth / 100)")
                        .font(.pixel(32))
                        .foregroundColor(financeStore.netWorth >= 0 ? Color("PixelGreen") : Color("PixelRed"))
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.white)
                .cornerRadius(16)
                
                // Assets list
                LazyVStack(spacing: 8) {
                    ForEach(financeStore.assets, id: \.assetId) { asset in
                        HStack {
                            Text(asset.name)
                                .font(.pixel(16))
                                .foregroundColor(Color("PixelBorder"))
                            
                            Spacer()
                            
                            Text("¥\(asset.currentBalance / 100)")
                                .font(.pixel(16))
                                .foregroundColor(asset.currentBalance >= 0 ? Color("PixelGreen") : Color("PixelRed"))
                        }
                        .padding()
                        .background(Color.white)
                        .cornerRadius(8)
                    }
                }
            }
            .padding()
        }
    }
}

#Preview {
    AssetsView()
        .environmentObject(SwiftDataItemStore())
        .environmentObject(SwiftDataFinanceStore())
}
