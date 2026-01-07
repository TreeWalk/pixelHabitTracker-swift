import SwiftUI

struct CharacterStatusView: View {
    @EnvironmentObject var questStore: QuestStore
    @EnvironmentObject var bookStore: BookStore
    @EnvironmentObject var exerciseStore: ExerciseStore
    @EnvironmentObject var financeStore: SwiftDataFinanceStore
    @EnvironmentObject var itemStore: ItemStore
    
    @StateObject private var statsService = PlayerStatsService()
    @StateObject private var localizationManager = LocalizationManager.shared
    
    @State private var showSettings = false
    
    var body: some View {
        ZStack {
            Color("PixelBg").ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 16) {
                    // 头部: 头像 + 等级 + XP
                    headerSection
                    
                    // 属性面板
                    statsSection
                    
                    // 物品栏入口
                    inventorySection
                    
                    // 系统设置
                    settingsSection
                }
                .padding()
            }
        }
        .onAppear {
            statsService.configure(
                questStore: questStore,
                bookStore: bookStore,
                exerciseStore: exerciseStore,
                financeStore: financeStore
            )
        }
        .sheet(isPresented: $showSettings) {
            SystemSettingsSheet()
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: 12) {
            HStack(spacing: 16) {
                // 像素头像
                ZStack {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color("PixelWood").opacity(0.3))
                        .frame(width: 80, height: 80)
                    
                    Image(systemName: "person.fill")
                        .font(.system(size: 40))
                        .foregroundColor(Color("PixelBorder"))
                }
                .pixelBorderSmall()
                
                VStack(alignment: .leading, spacing: 8) {
                    // 玩家名称
                    Text("character_adventurer".localized)
                        .font(.pixel(24))
                        .foregroundColor(Color("PixelBorder"))
                    
                    // 等级徽章
                    HStack(spacing: 8) {
                        Text(statsService.formattedLevel)
                            .font(.pixel(18))
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 4)
                            .background(Color("PixelAccent"))
                            .cornerRadius(4)
                        
                        Text("character_title".localized)
                            .font(.pixel(14))
                            .foregroundColor(Color("PixelWood"))
                    }
                }
                
                Spacer()
            }
            
            // XP 进度条
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("XP")
                        .font(.pixel(14))
                        .foregroundColor(Color("PixelBorder"))
                    Spacer()
                    Text(statsService.formattedXP)
                        .font(.pixel(12))
                        .foregroundColor(Color("PixelWood"))
                }
                
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        // 背景
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color("PixelBorder").opacity(0.2))
                            .frame(height: 12)
                        
                        // 进度
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color("PixelBlue"))
                            .frame(width: geometry.size.width * statsService.xpProgress, height: 12)
                    }
                }
                .frame(height: 12)
            }
        }
        .padding()
        .background(Color.white)
        .pixelBorderSmall()
    }
    
    // MARK: - Stats Section
    
    private var statsSection: some View {
        VStack(spacing: 12) {
            Text("character_stats".localized)
                .font(.pixel(18))
                .foregroundColor(Color("PixelBorder"))
                .frame(maxWidth: .infinity, alignment: .leading)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                StatCard(
                    icon: "figure.strengthtraining.traditional",
                    name: "STR",
                    value: statsService.strength,
                    color: Color("PixelRed"),
                    description: "character_str_desc".localized
                )
                
                StatCard(
                    icon: "book.fill",
                    name: "INT",
                    value: statsService.intelligence,
                    color: Color("PixelBlue"),
                    description: "character_int_desc".localized
                )
                
                StatCard(
                    icon: "heart.fill",
                    name: "VIT",
                    value: statsService.vitality,
                    color: Color("PixelGreen"),
                    description: "character_vit_desc".localized
                )
                
                StatCard(
                    icon: "dollarsign.circle.fill",
                    name: "GOLD",
                    value: statsService.wealth,
                    color: Color("PixelAccent"),
                    description: "character_gold_desc".localized
                )
            }
        }
        .padding()
        .background(Color.white)
        .pixelBorderSmall()
    }
    
    // MARK: - Inventory Section
    
    private var inventorySection: some View {
        VStack(spacing: 12) {
            HStack {
                Text("character_inventory".localized)
                    .font(.pixel(18))
                    .foregroundColor(Color("PixelBorder"))
                
                Spacer()
                
                Text("\(itemStore.items.count) / 12")
                    .font(.pixel(14))
                    .foregroundColor(Color("PixelWood"))
            }
            
            // 物品栏格子 - 显示实际物品
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 6), spacing: 8) {
                ForEach(0..<12, id: \.self) { index in
                    if index < itemStore.items.count {
                        // 有物品的格子
                        let item = itemStore.items[index]
                        InventorySlot(item: item)
                    } else {
                        // 空格子
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color("PixelBorder").opacity(0.1))
                            .frame(height: 44)
                            .overlay(
                                RoundedRectangle(cornerRadius: 2)
                                    .stroke(Color("PixelBorder").opacity(0.3), lineWidth: 1)
                            )
                    }
                }
            }
            
            if itemStore.items.isEmpty {
                Text("character_inventory_hint".localized)
                    .font(.pixel(12))
                    .foregroundColor(Color("PixelWood"))
            }
        }
        .padding()
        .background(Color.white)
        .pixelBorderSmall()
    }
    
    // MARK: - Settings Section
    
    private var settingsSection: some View {
        Button(action: { showSettings = true }) {
            HStack {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 20))
                Text("character_system_settings".localized)
                    .font(.pixel(16))
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 14))
            }
            .foregroundColor(Color("PixelBorder"))
            .padding()
            .background(Color.white)
            .pixelBorderSmall()
        }
    }
}

// MARK: - Stat Card

struct StatCard: View {
    let icon: String
    let name: String
    let value: Int
    let color: Color
    let description: String
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(color)
                
                Spacer()
                
                Text("\(value)")
                    .font(.pixel(24))
                    .foregroundColor(Color("PixelBorder"))
            }
            
            HStack {
                Text(name)
                    .font(.pixel(14))
                    .foregroundColor(color)
                
                Spacer()
            }
            
            Text(description)
                .font(.pixel(10))
                .foregroundColor(Color("PixelWood"))
                .frame(maxWidth: .infinity, alignment: .leading)
                .lineLimit(2)
        }
        .padding(12)
        .background(color.opacity(0.1))
        .overlay(
            RoundedRectangle(cornerRadius: 4)
                .stroke(color.opacity(0.3), lineWidth: 2)
        )
        .cornerRadius(4)
    }
}

// MARK: - Inventory Slot

struct InventorySlot: View {
    let item: Item
    
    var body: some View {
        ZStack {
            // 背景 - 根据稀有度着色
            RoundedRectangle(cornerRadius: 2)
                .fill(Color(item.rarity.color).opacity(0.2))
                .frame(height: 44)
            
            // 物品图标
            Image(item.icon)
                .resizable()
                .scaledToFit()
                .frame(width: 32, height: 32)
        }
        .overlay(
            RoundedRectangle(cornerRadius: 2)
                .stroke(Color(item.rarity.color).opacity(0.6), lineWidth: 2)
        )
    }
}

// MARK: - System Settings Sheet

struct SystemSettingsSheet: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var localizationManager = LocalizationManager.shared
    
    var body: some View {
        NavigationView {
            ZStack {
                Color("PixelBg").ignoresSafeArea()
                
                VStack(spacing: 20) {
                    // Language Picker
                    VStack(alignment: .leading, spacing: 8) {
                        Text("settings_language".localized)
                            .font(.pixel(16))
                            .foregroundColor(Color("PixelBorder"))
                        
                        Picker("settings_language".localized, selection: $localizationManager.currentLanguage) {
                            Text("language_english".localized).tag("en")
                            Text("language_chinese".localized).tag("zh-Hans")
                        }
                        .pickerStyle(.segmented)
                    }
                    .padding()
                    .background(Color.white)
                    .pixelBorderSmall()
                    
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("character_system_settings".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("done".localized) {
                        dismiss()
                    }
                    .font(.pixel(16))
                }
            }
        }
    }
}

#Preview {
    CharacterStatusView()
        .environmentObject(QuestStore())
        .environmentObject(BookStore())
        .environmentObject(ExerciseStore())
        .environmentObject(SwiftDataFinanceStore())
        .environmentObject(ItemStore())
}

