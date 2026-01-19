import SwiftUI

struct QuickEntrySheet: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var financeStore: SwiftDataFinanceStore
    
    @State private var selectedType: FinanceType = .expense
    @State private var amountText: String = ""
    @State private var selectedCategory: String = "food"
    @State private var note: String = ""
    
    var categories: [FinanceCategory] {
        FinanceCategory.categories(for: selectedType)
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color("PixelBg").ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 16) {
                        // 收入/支出切换
                        HStack(spacing: 0) {
                            TypeToggleButton(
                                title: "finance_expense".localized,
                                icon: "arrow.down.circle.fill",
                                isSelected: selectedType == .expense,
                                color: Color("PixelRed")
                            ) {
                                selectedType = .expense
                                selectedCategory = financeStore.lastExpenseCategory
                            }

                            TypeToggleButton(
                                title: "finance_income".localized,
                                icon: "arrow.up.circle.fill",
                                isSelected: selectedType == .income,
                                color: Color("PixelGreen")
                            ) {
                                selectedType = .income
                                selectedCategory = financeStore.lastIncomeCategory
                            }
                        }
                        .pixelCardSmall()
                        
                        // 金额输入
                        HStack {
                            Text("¥")
                                .font(.pixel(36))
                                .foregroundColor(selectedType == .expense ? Color("PixelRed") : Color("PixelGreen"))

                            TextField("0.00", text: $amountText)
                                .font(.pixel(44))
                                .foregroundColor(Color("PixelBorder"))
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.center)
                        }
                        .padding()
                        .pixelCardSmall()
                        
                        // 分类选择
                        if !categories.isEmpty {
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 5), spacing: 8) {
                                ForEach(categories) { category in
                                    CategoryButton(
                                        category: category,
                                        isSelected: selectedCategory == category.id,
                                        onTap: { selectedCategory = category.id }
                                    )
                                }
                            }
                        }
                        
                        // 备注
                        TextField("finance_note_optional".localized, text: $note)
                            .font(.pixel(16))
                            .padding(12)
                            .background(Color.white)
                            .pixelBorderSmall()
                        
                        // 记录按钮
                        Button(action: submitEntry) {
                            Text("finance_add_entry".localized)
                                .font(.pixel(22))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(selectedType == .expense ? Color("PixelRed") : Color("PixelGreen"))
                                .pixelBorderSmall(color: selectedType == .expense ? Color("PixelRed") : Color("PixelGreen"))
                        }
                        .disabled(amountText.isEmpty)
                        .opacity(amountText.isEmpty ? 0.5 : 1)
                    }
                    .padding()
                }
            }
            .navigationTitle("finance_quick_entry".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("cancel".localized) {
                        dismiss()
                    }
                    .font(.pixel(16))
                }
            }
        }
        .onAppear {
            selectedCategory = selectedType == .expense ? financeStore.lastExpenseCategory : financeStore.lastIncomeCategory
        }
    }
    
    private func submitEntry() {
        guard let amount = parseAmount(amountText), amount > 0 else { return }
        
        financeStore.addEntry(
            amount: amount,
            type: selectedType == .expense ? "expense" : "income",
            category: selectedCategory,
            note: note.isEmpty ? nil : note
        )
        
        // 震动反馈
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        
        dismiss()
    }
    
    private func parseAmount(_ text: String) -> Int? {
        guard let value = Double(text) else { return nil }
        return Int(value * 100) // 转换为分
    }
}

// MARK: - Type Toggle Button

struct TypeToggleButton: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let color: Color
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                Text(title)
                    .font(.pixel(18))
            }
            .foregroundColor(isSelected ? .white : Color("PixelBorder"))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(isSelected ? color : Color.clear)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Category Button

struct CategoryButton: View {
    let category: FinanceCategory
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 4) {
                Image(systemName: category.icon)
                    .font(.system(size: 20))
                Text(category.name)
                    .font(.pixel(11))
            }
            .foregroundColor(isSelected ? .white : Color("PixelBorder"))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(isSelected ? Color("PixelAccent") : Color.white)
            .pixelBorderSmall(color: isSelected ? Color("PixelAccent") : Color("PixelBorder").opacity(0.3))
        }
        .buttonStyle(.plain)
    }
}
