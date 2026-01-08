import SwiftUI

struct ItemsView: View {
    @EnvironmentObject var itemStore: SwiftDataItemStore
    @EnvironmentObject var localizationManager: LocalizationManager
    @State private var showAddSheet = false
    @State private var selectedItem: ItemData?
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color("PixelBg").ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header with Stats
                    ItemsHeader(
                        itemCount: itemStore.items.count,
                        totalValue: itemStore.totalValue,
                        averageDailyCost: itemStore.averageDailyCost,
                        onAddTap: { showAddSheet = true }
                    )
                    
                    // Item Cards List
                    if itemStore.items.isEmpty {
                        EmptyCollectionView(onAddTap: { showAddSheet = true })
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 12) {
                                ForEach(itemStore.items, id: \.itemId) { item in
                                    ItemDataCard(item: item) {
                                        selectedItem = item
                                    }
                                }
                            }
                            .padding()
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showAddSheet) {
            AddItemSheet()
        }
        .sheet(item: $selectedItem) { item in
            ItemDataDetailSheet(item: item) {
                itemStore.deleteItem(item)
                selectedItem = nil
            }
        }
    }
}

// MARK: - Items Header

struct ItemsHeader: View {
    let itemCount: Int
    let totalValue: Int
    let averageDailyCost: Double
    let onAddTap: () -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            // Title Row
            HStack(alignment: .center) {
                Text("items_title".localized)
                    .font(.pixel(28))
                    .foregroundColor(Color("PixelBorder"))
                
                Spacer()
                
                Button(action: onAddTap) {
                    HStack(spacing: 4) {
                        Image(systemName: "plus")
                            .font(.system(size: 14, weight: .bold))
                        Text("ADD")
                            .font(.pixel(14))
                    }
                    .foregroundColor(Color("PixelBorder"))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color("PixelAccent"))
                    .pixelBorderSmall()
                }
            }
            
            // Stats Row
            HStack(spacing: 16) {
                StatBadge(
                    icon: "cube.fill",
                    value: "\(itemCount)",
                    label: "件物品"
                )
                
                StatBadge(
                    icon: "yensign.circle.fill",
                    value: "¥\(totalValue)",
                    label: "总价值"
                )
                
                StatBadge(
                    icon: "chart.line.downtrend.xyaxis",
                    value: String(format: "¥%.1f", averageDailyCost),
                    label: "日均成本"
                )
            }
        }
        .padding()
        .background(Color("PixelBg"))
    }
}

// MARK: - Stat Badge

struct StatBadge: View {
    let icon: String
    let value: String
    let label: String
    
    var body: some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 12))
                    .foregroundColor(Color("PixelAccent"))
                Text(value)
                    .font(.pixel(16))
                    .foregroundColor(Color("PixelBorder"))
            }
            Text(label)
                .font(.pixel(10))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(Color.white.opacity(0.5))
        .overlay(
            Rectangle()
                .stroke(Color("PixelBorder").opacity(0.3), lineWidth: 2)
        )
    }
}

// MARK: - Item Data Card

struct ItemDataCard: View {
    let item: ItemData
    let onTap: () -> Void
    
    // Color based on daily cost - lower is better (greener)
    var costColor: Color {
        if item.dailyCost < 5 {
            return Color.green
        } else if item.dailyCost < 20 {
            return Color("PixelAccent")
        } else if item.dailyCost < 50 {
            return Color.orange
        } else {
            return Color("PixelRed")
        }
    }
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Item Icon
                Image(item.icon)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 56, height: 56)
                    .padding(8)
                    .background(Color.white)
                    .overlay(
                        Rectangle()
                            .stroke(Color("PixelBorder").opacity(0.3), lineWidth: 2)
                    )
                
                // Item Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.name)
                        .font(.pixel(18))
                        .foregroundColor(Color("PixelBorder"))
                        .lineLimit(1)
                    
                    HStack(spacing: 8) {
                        Text(item.formattedPrice)
                            .font(.pixel(14))
                            .foregroundColor(Color("PixelAccent"))
                        
                        Text("·")
                            .foregroundColor(.secondary)
                        
                        Text(formattedDate)
                            .font(.pixel(12))
                            .foregroundColor(.secondary)
                    }
                    
                    Text(item.itemDescription)
                        .font(.pixel(11))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                
                Spacer()
                
                // Daily Cost Display
                VStack(alignment: .trailing, spacing: 2) {
                    Text(String(format: "¥%.1f", item.dailyCost))
                        .font(.pixel(18))
                        .foregroundColor(costColor)
                    
                    Text("/天")
                        .font(.pixel(10))
                        .foregroundColor(.secondary)
                    
                    Text("已用\(item.daysOwned)天")
                        .font(.pixel(10))
                        .foregroundColor(costColor.opacity(0.8))
                }
                .padding(.trailing, 4)
                
                // Arrow
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Color("PixelBorder").opacity(0.5))
            }
            .padding(12)
            .background(Color.white)
            .overlay(
                Rectangle()
                    .stroke(Color("PixelBorder"), lineWidth: 3)
            )
        }
        .buttonStyle(.plain)
    }
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy.MM.dd"
        return formatter.string(from: item.purchaseDate)
    }
}

// MARK: - Empty Collection View

struct EmptyCollectionView: View {
    let onAddTap: () -> Void
    
    var body: some View {
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
            
            Button(action: onAddTap) {
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
    }
}

// MARK: - Item Data Detail Sheet

struct ItemDataDetailSheet: View {
    @Environment(\.dismiss) var dismiss
    let item: ItemData
    let onDelete: () -> Void
    
    // Predict when daily cost will drop to certain thresholds
    var nextMilestone: (days: Int, cost: Double)? {
        let targets: [Double] = [50, 20, 10, 5, 2, 1, 0.5]
        for target in targets {
            let neededDays = Int(ceil(Double(item.price) / target))
            if neededDays > item.daysOwned {
                return (neededDays - item.daysOwned, target)
            }
        }
        return nil
    }
    
    var costColor: Color {
        if item.dailyCost < 5 {
            return Color.green
        } else if item.dailyCost < 20 {
            return Color("PixelAccent")
        } else if item.dailyCost < 50 {
            return Color.orange
        } else {
            return Color("PixelRed")
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color("PixelBg").ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Item Icon
                        Image(item.icon)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 120, height: 120)
                            .padding(20)
                            .background(Color.white)
                            .overlay(
                                Rectangle()
                                    .stroke(Color(item.rarityColor), lineWidth: 4)
                            )
                        
                        // Item Name
                        Text(item.name)
                            .font(.pixel(28))
                            .foregroundColor(Color("PixelBorder"))
                        
                        // Rarity Badge
                        Text(item.rarityEnum.localizedName)
                            .font(.pixel(12))
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 4)
                            .background(Color(item.rarityColor))
                            .cornerRadius(4)
                        
                        // Description
                        Text(item.itemDescription)
                            .font(.pixel(14))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        
                        // Stats Grid
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                            DetailStatCard(
                                title: "购买价格",
                                value: item.formattedPrice,
                                icon: "yensign.circle"
                            )
                            
                            DetailStatCard(
                                title: "购买日期",
                                value: formattedDate,
                                icon: "calendar"
                            )
                            
                            DetailStatCard(
                                title: "使用天数",
                                value: "\(item.daysOwned) 天",
                                icon: "clock"
                            )
                            
                            DetailStatCard(
                                title: "日均成本",
                                value: String(format: "¥%.2f", item.dailyCost),
                                icon: "chart.line.downtrend.xyaxis",
                                valueColor: costColor
                            )
                        }
                        .padding(.horizontal)
                        
                        // Milestone Encouragement
                        if let milestone = nextMilestone {
                            VStack(spacing: 8) {
                                Text("🎯 长期主义目标")
                                    .font(.pixel(14))
                                    .foregroundColor(Color("PixelAccent"))
                                
                                Text("再使用 \(milestone.days) 天")
                                    .font(.pixel(18))
                                    .foregroundColor(Color("PixelBorder"))
                                
                                Text("日均成本将降至 ¥\(String(format: "%.1f", milestone.cost))")
                                    .font(.pixel(14))
                                    .foregroundColor(.green)
                            }
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.green.opacity(0.1))
                            .overlay(
                                Rectangle()
                                    .stroke(Color.green.opacity(0.5), lineWidth: 2)
                            )
                            .padding(.horizontal)
                        }
                        
                        Spacer(minLength: 40)
                        
                        // Delete Button
                        Button(action: {
                            onDelete()
                        }) {
                            HStack {
                                Image(systemName: "trash")
                                Text("删除此物品")
                                    .font(.pixel(16))
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
                            .background(Color("PixelRed"))
                            .pixelBorderSmall()
                        }
                        .padding(.bottom)
                    }
                    .padding(.top, 20)
                }
            }
            .navigationTitle("物品详情")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") { dismiss() }
                        .font(.pixel(16))
                }
            }
        }
    }
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy.MM.dd"
        return formatter.string(from: item.purchaseDate)
    }
}

// MARK: - Detail Stat Card

struct DetailStatCard: View {
    let title: String
    let value: String
    let icon: String
    var valueColor: Color = Color("PixelBorder")
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(Color("PixelAccent"))
            
            Text(value)
                .font(.pixel(18))
                .foregroundColor(valueColor)
            
            Text(title)
                .font(.pixel(11))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Color.white)
        .overlay(
            Rectangle()
                .stroke(Color("PixelBorder").opacity(0.3), lineWidth: 2)
        )
    }
}

// MARK: - Add Item Sheet

struct AddItemSheet: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var itemStore: SwiftDataItemStore
    @State private var name = ""
    @State private var description = ""
    @State private var priceText = ""
    @State private var selectedIcon = "item_car"
    @State private var selectedRarity: ItemRarity = .common
    @State private var purchaseDate = Date()
    
    let availableIcons = [
        "item_bag", "item_books", "item_car",
        "item_figure", "item_game", "item_green",
        "item_pc", "item_phone", "item_watch"
    ]
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color("PixelBg").ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Icon Selection
                        VStack(alignment: .leading, spacing: 8) {
                            Text("选择图标")
                                .font(.pixel(14))
                                .foregroundColor(Color("PixelAccent"))
                            
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 5), spacing: 8) {
                                ForEach(availableIcons, id: \.self) { iconName in
                                    Button(action: { selectedIcon = iconName }) {
                                        Image(iconName)
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 40, height: 40)
                                            .padding(8)
                                            .background(selectedIcon == iconName ? Color("PixelAccent").opacity(0.2) : Color.white)
                                            .overlay(
                                                Rectangle()
                                                    .stroke(selectedIcon == iconName ? Color("PixelAccent") : Color("PixelBorder").opacity(0.3), lineWidth: selectedIcon == iconName ? 3 : 2)
                                            )
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                        
                        // Name Input
                        VStack(alignment: .leading, spacing: 8) {
                            Text("物品名称")
                                .font(.pixel(14))
                                .foregroundColor(Color("PixelAccent"))
                            TextField("例如：MacBook Pro", text: $name)
                                .font(.pixel(18))
                                .padding(12)
                                .background(.white)
                                .overlay(
                                    Rectangle()
                                        .stroke(Color("PixelBorder"), lineWidth: 2)
                                )
                        }
                        
                        // Price Input
                        VStack(alignment: .leading, spacing: 8) {
                            Text("购买价格 (元)")
                                .font(.pixel(14))
                                .foregroundColor(Color("PixelAccent"))
                            TextField("0", text: $priceText)
                                .font(.pixel(24))
                                .keyboardType(.numberPad)
                                .padding(12)
                                .background(.white)
                                .overlay(
                                    Rectangle()
                                        .stroke(Color("PixelBorder"), lineWidth: 2)
                                )
                        }
                        
                        // Rarity Picker
                        VStack(alignment: .leading, spacing: 8) {
                            Text("稀有度")
                                .font(.pixel(14))
                                .foregroundColor(Color("PixelAccent"))
                            
                            LazyVGrid(columns: [
                                GridItem(.flexible()),
                                GridItem(.flexible())
                            ], spacing: 8) {
                                ForEach(ItemRarity.allCases, id: \.self) { rarity in
                                    Button(action: { selectedRarity = rarity }) {
                                        Text(rarity.localizedName)
                                            .font(.pixel(14))
                                            .foregroundColor(selectedRarity == rarity ? .white : Color(rarity.color))
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 10)
                                            .background(selectedRarity == rarity ? Color(rarity.color) : Color.white)
                                            .overlay(
                                                Rectangle()
                                                    .stroke(Color(rarity.color), lineWidth: 2)
                                            )
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                        
                        // Date Picker
                        PixelDatePicker(
                            title: "items_purchase_date".localized,
                            selection: $purchaseDate,
                            displayedComponents: .date
                        )
                        
                        // Description Input
                        VStack(alignment: .leading, spacing: 8) {
                            Text("备注 (可选)")
                                .font(.pixel(14))
                                .foregroundColor(Color("PixelAccent"))
                            TextField("描述一下这个物品...", text: $description)
                                .font(.pixel(14))
                                .padding(12)
                                .background(.white)
                                .overlay(
                                    Rectangle()
                                        .stroke(Color("PixelBorder").opacity(0.5), lineWidth: 2)
                                )
                        }
                        
                        Spacer(minLength: 30)
                        
                        // Add Button
                        Button(action: {
                            let price = Int(priceText) ?? 0
                            itemStore.addItem(
                                name: name,
                                icon: selectedIcon,
                                rarity: selectedRarity,
                                description: description.isEmpty ? "无备注" : description,
                                price: price,
                                purchaseDate: purchaseDate
                            )
                            dismiss()
                        }) {
                            Text("添加到收藏")
                                .font(.pixel(20))
                                .foregroundColor(Color("PixelBorder"))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(Color("PixelAccent"))
                                .pixelBorderSmall()
                        }
                        .disabled(name.isEmpty || priceText.isEmpty)
                        .opacity((name.isEmpty || priceText.isEmpty) ? 0.5 : 1)
                    }
                    .padding()
                }
            }
            .navigationTitle("添加物品")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                        .font(.pixel(16))
                }
            }
        }
    }
}

#Preview {
    ItemsView()
        .environmentObject(SwiftDataItemStore())
}

