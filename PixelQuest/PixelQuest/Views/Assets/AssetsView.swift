import SwiftUI

enum AssetsViewMode: String, CaseIterable {
    case rpg = "RPG"
    case finance = "Finance"
}

struct AssetsView: View {
    @EnvironmentObject var itemStore: SwiftDataItemStore
    @EnvironmentObject var financeStore: SwiftDataFinanceStore

    let heroNamespace: Namespace.ID?

    @State private var viewMode: AssetsViewMode = .rpg
    @State private var showAddItemSheet = false
    @State private var showAddAssetSheet = false
    @State private var selectedItem: ItemData?

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                assetsHeroCard

                Picker("Mode", selection: $viewMode) {
                    ForEach(AssetsViewMode.allCases, id: \.self) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .pickerStyle(.segmented)

                if viewMode == .rpg {
                    rpgModeContent
                } else {
                    financeModeContent
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 24)
        }
        .scrollIndicators(.hidden)
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
                        .foregroundStyle(Color("PixelBorder"))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color("PixelAccent"))
                        .pixelBorderSmall()
                    }
                }
            }
        }
        .sheet(isPresented: $showAddItemSheet) {
            AddItemSheet()
        }
        .sheet(isPresented: $showAddAssetSheet) {
            AddAssetSheet()
        }
        .sheet(item: $selectedItem) { item in
            ItemDataDetailSheet(item: item) {
                itemStore.deleteItem(item)
                selectedItem = nil
            }
        }
    }

    // MARK: - Hero Card

    @ViewBuilder
    private var assetsHeroCard: some View {
        let card = VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("物品概览")
                    .font(.pixelHeader(20))
                    .foregroundStyle(Color("PixelBorder"))

                Spacer()

                Text("总览")
                    .font(.pixel(12))
                    .foregroundStyle(Color("PixelBorder").opacity(0.6))
            }

            Text("物品总数")
                .font(.pixel(12))
                .foregroundStyle(Color("PixelBorder").opacity(0.6))

            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text("\(itemStore.items.count)")
                    .font(.pixelHeader(32))
                    .foregroundStyle(Color("PixelBorder"))
                    .ifAvailable17 { view in
                        view.contentTransition(.numericText())
                    }
                Text("件")
                    .font(.pixel(14))
                    .foregroundStyle(Color("PixelBorder").opacity(0.6))
            }

            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("总价值")
                        .font(.pixel(11))
                        .foregroundStyle(Color("PixelBorder").opacity(0.6))
                    Text(itemStore.formattedTotalValue)
                        .font(.pixel(14))
                        .foregroundStyle(Color("PixelAccent"))
                }

                if let latest = itemStore.items.first {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("最近物品")
                            .font(.pixel(11))
                            .foregroundStyle(Color("PixelBorder").opacity(0.6))
                        Text(latest.name)
                            .font(.pixel(14))
                            .foregroundStyle(Color("PixelBorder"))
                            .lineLimit(1)
                    }
                }
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .cozyCard(backgroundColor: .white, borderWidth: 3)

        if let heroNamespace {
            card.matchedGeometryEffect(id: HomeHeroID.assets, in: heroNamespace, isSource: false)
        } else {
            card
        }
    }

    // MARK: - RPG Mode (Bag)
    private var rpgModeContent: some View {
        Group {
            if itemStore.items.isEmpty {
                VStack(spacing: 20) {
                    Image(systemName: "cube.box")
                        .font(.system(size: 60))
                        .foregroundStyle(Color("PixelBorder").opacity(0.3))

                    Text("还没有记录任何物品")
                        .font(.pixel(18))
                        .foregroundStyle(.secondary)

                    Text("添加你的第一个物品，开始追踪使用价值")
                        .font(.pixel(14))
                        .foregroundStyle(.secondary.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)

                    Button(action: { showAddItemSheet = true }) {
                        HStack {
                            Image(systemName: "plus")
                            Text("添加物品")
                                .font(.pixel(16))
                        }
                        .foregroundStyle(Color("PixelBorder"))
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(Color("PixelAccent"))
                        .pixelBorderSmall()
                    }
                    .padding(.top, 10)
                }
                .padding(.vertical, 40)
            } else {
                VStack(spacing: 16) {
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

                    LazyVStack(spacing: 12) {
                        ForEach(itemStore.items, id: \.itemId) { item in
                            ItemDataCard(item: item) {
                                selectedItem = item
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: - Finance Mode
    private var financeModeContent: some View {
        VStack(spacing: 16) {
            VStack(spacing: 8) {
                Text("net_worth".localized)
                    .font(.pixel(14))
                    .foregroundStyle(.secondary)

                Text("¥\(financeStore.netWorth / 100)")
                    .font(.pixel(32))
                    .foregroundStyle(financeStore.netWorth >= 0 ? Color("PixelGreen") : Color("PixelRed"))
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.white)
            .clipShape(.rect(cornerRadius: 16))

            LazyVStack(spacing: 8) {
                ForEach(financeStore.assets, id: \.assetId) { asset in
                    HStack {
                        Text(asset.name)
                            .font(.pixel(16))
                            .foregroundStyle(Color("PixelBorder"))

                        Spacer()

                        Text("¥\(asset.currentBalance / 100)")
                            .font(.pixel(16))
                            .foregroundStyle(asset.currentBalance >= 0 ? Color("PixelGreen") : Color("PixelRed"))
                    }
                    .padding()
                    .background(Color.white)
                    .clipShape(.rect(cornerRadius: 8))
                }
            }

            Button(action: { showAddAssetSheet = true }) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("asset_add".localized)
                        .font(.pixel(16))
                }
                .foregroundStyle(Color("PixelBorder"))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color("PixelAccent"))
                .pixelBorderSmall()
            }
        }
    }
}

#Preview {
    struct AssetsPreview: View {
        @Namespace private var hero

        var body: some View {
            NavigationStack {
                AssetsView(heroNamespace: hero)
                    .environmentObject(SwiftDataItemStore())
                    .environmentObject(SwiftDataFinanceStore())
            }
        }
    }

    return AssetsPreview()
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
}

struct StatBadge: View {
    let icon: String
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(Color("PixelAccent"))

            Text(value)
                .font(.pixel(16))
                .foregroundStyle(Color("PixelBorder"))

            Text(label)
                .font(.pixel(11))
                .foregroundStyle(Color("PixelBorder").opacity(0.6))
        }
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity)
        .background(Color.white)
        .pixelBorderSmall()
    }
}

struct ItemDataCard: View {
    let item: ItemData
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                Image(item.icon)
                    .resizable()
                    .interpolation(.none)
                    .scaledToFit()
                    .frame(width: 44, height: 44)
                    .padding(6)
                    .background(Color("PixelBg"))
                    .pixelBorderSmall()

                VStack(alignment: .leading, spacing: 4) {
                    Text(item.name)
                        .font(.pixel(16))
                        .foregroundStyle(Color("PixelBorder"))
                        .lineLimit(1)

                    Text(item.rarityEnum.localizedName)
                        .font(.pixel(12))
                        .foregroundStyle(Color(item.rarityColor))
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text("¥\(item.price)")
                        .font(.pixel(14))
                        .foregroundStyle(Color("PixelAccent"))

                    Text(item.formattedDailyCost)
                        .font(.pixel(11))
                        .foregroundStyle(Color("PixelBorder").opacity(0.6))
                }
            }
            .padding(12)
            .background(Color.white)
            .pixelBorderSmall()
        }
        .buttonStyle(.plain)
    }
}

struct ItemDataDetailSheet: View {
    let item: ItemData
    let onDelete: () -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    HStack(spacing: 12) {
                        Image(item.icon)
                            .resizable()
                            .interpolation(.none)
                            .scaledToFit()
                            .frame(width: 64, height: 64)
                            .padding(8)
                            .background(Color("PixelBg"))
                            .pixelBorderSmall()

                        VStack(alignment: .leading, spacing: 6) {
                            Text(item.name)
                                .font(.pixelHeader(24))
                                .foregroundStyle(Color("PixelBorder"))

                            Text(item.rarityEnum.localizedName)
                                .font(.pixel(14))
                                .foregroundStyle(Color(item.rarityColor))
                        }

                        Spacer()
                    }

                    detailRow(title: "价格", value: "¥\(item.price)")
                    detailRow(title: "日均成本", value: item.formattedDailyCost)
                    detailRow(title: "购买日期", value: item.purchaseDate.formatted(date: .abbreviated, time: .omitted))

                    Text(item.itemDescription)
                        .font(.pixel(14))
                        .foregroundStyle(Color("PixelBorder"))
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.white)
                        .pixelBorderSmall()
                }
                .padding(16)
            }
            .navigationTitle("物品详情")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("关闭") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button(role: .destructive) {
                        onDelete()
                        dismiss()
                    } label: {
                        Text("删除")
                    }
                }
            }
        }
    }

    private func detailRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .font(.pixel(12))
                .foregroundStyle(Color("PixelBorder").opacity(0.6))

            Spacer()

            Text(value)
                .font(.pixel(14))
                .foregroundStyle(Color("PixelBorder"))
        }
        .padding(12)
        .background(Color.white)
        .pixelBorderSmall()
    }
}

struct AddItemSheet: View {
    @EnvironmentObject private var itemStore: SwiftDataItemStore
    @Environment(\.dismiss) private var dismiss

    @State private var name: String = ""
    @State private var description: String = ""
    @State private var priceText: String = ""
    @State private var purchaseDate: Date = Date()
    @State private var selectedRarity: ItemRarity = .common
    @State private var selectedIcon: String = "item_pc"

    private let iconOptions: [String] = [
        "item_pc",
        "item_phone",
        "item_watch",
        "item_book",
        "item_gamepad"
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    TextField("物品名称", text: $name)
                        .textFieldStyle(.roundedBorder)

                    TextField("描述", text: $description)
                        .textFieldStyle(.roundedBorder)

                    TextField("价格（元）", text: $priceText)
                        .keyboardType(.numberPad)
                        .textFieldStyle(.roundedBorder)

                    DatePicker("购买日期", selection: $purchaseDate, displayedComponents: .date)
                        .datePickerStyle(.compact)

                    Picker("稀有度", selection: $selectedRarity) {
                        ForEach(ItemRarity.allCases, id: \.self) { rarity in
                            Text(rarity.localizedName).tag(rarity)
                        }
                    }
                    .pickerStyle(.segmented)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("图标")
                            .font(.pixel(12))
                            .foregroundStyle(Color("PixelBorder").opacity(0.6))

                        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 5), spacing: 8) {
                            ForEach(iconOptions, id: \.self) { icon in
                                Button(action: { selectedIcon = icon }) {
                                    Image(icon)
                                        .resizable()
                                        .interpolation(.none)
                                        .scaledToFit()
                                        .frame(width: 36, height: 36)
                                        .padding(6)
                                        .background(selectedIcon == icon ? Color("PixelAccent").opacity(0.2) : Color.white)
                                        .pixelBorderSmall()
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
                .padding(16)
            }
            .navigationTitle("添加物品")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        saveItem()
                        dismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || priceValue <= 0)
                }
            }
        }
    }

    private var priceValue: Int {
        Int(priceText.trimmingCharacters(in: .whitespacesAndNewlines)) ?? 0
    }

    private func saveItem() {
        itemStore.addItem(
            name: name,
            icon: selectedIcon,
            rarity: selectedRarity,
            description: description,
            price: priceValue,
            purchaseDate: purchaseDate
        )
    }
}
