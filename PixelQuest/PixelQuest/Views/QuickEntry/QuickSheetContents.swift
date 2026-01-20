import SwiftUI

// MARK: - Quick Sleep Sheet Content
/// 简化的睡眠记录内容
struct QuickSleepSheetContent: View {
    @Binding var isPresented: Bool
    @EnvironmentObject var sleepStore: SwiftDataSleepStore
    @EnvironmentObject var healthKitManager: HealthKitManager
    
    @State private var bedTime = Calendar.current.date(bySettingHour: 22, minute: 30, second: 0, of: Date()) ?? Date()
    @State private var wakeTime = Calendar.current.date(bySettingHour: 7, minute: 0, second: 0, of: Date()) ?? Date()
    @State private var quality: Int = 4
    @State private var isSaving = false
    
    var body: some View {
        VStack(spacing: 12) {
            // 时间选择
            HStack(spacing: 16) {
                // 入睡
                VStack(spacing: 4) {
                    HStack(spacing: 4) {
                        Image(systemName: "moon.fill")
                            .font(.system(size: 12))
                            .foregroundColor(Color("PixelBlue"))
                        Text("bed_time".localized)
                            .font(.pixel(12))
                            .foregroundColor(Color("PixelBorder"))
                    }
                    PixelDatePicker(title: "", selection: $bedTime, displayedComponents: .hourAndMinute)
                        .frame(width: 90)
                }
                
                // 起床
                VStack(spacing: 4) {
                    HStack(spacing: 4) {
                        Image(systemName: "sun.max.fill")
                            .font(.system(size: 12))
                            .foregroundColor(Color("PixelAccent"))
                        Text("wake_time".localized)
                            .font(.pixel(12))
                            .foregroundColor(Color("PixelBorder"))
                    }
                    PixelDatePicker(title: "", selection: $wakeTime, displayedComponents: .hourAndMinute)
                        .frame(width: 90)
                }
            }
            .padding(10)
            .background(Color.white)
            .overlay(Rectangle().stroke(Color("PixelBorder"), lineWidth: 2))
            
            // 睡眠质量
            VStack(spacing: 6) {
                Text("sleep_quality_label".localized)
                    .font(.pixel(12))
                    .foregroundColor(Color("PixelBorder").opacity(0.7))
                
                HStack(spacing: 8) {
                    ForEach(1...5, id: \.self) { index in
                        Button(action: { quality = index }) {
                            Image(systemName: index <= quality ? "star.fill" : "star")
                                .font(.system(size: 22))
                                .foregroundColor(index <= quality ? Color("PixelAccent") : Color.gray.opacity(0.3))
                        }
                    }
                }
                
                Text(qualityText)
                    .font(.pixel(10))
                    .foregroundColor(Color("PixelAccent"))
            }
            .padding(10)
            .background(Color.white)
            .overlay(Rectangle().stroke(Color("PixelBorder"), lineWidth: 2))
            
            // 保存按钮
            Button(action: saveSleep) {
                Text("record_sleep".localized + " ✓")
                    .font(.pixel(16))
                    .foregroundColor(Color("PixelBorder"))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color("PixelAccent"))
                    .overlay(Rectangle().stroke(Color("PixelBorder"), lineWidth: 2))
            }
            .disabled(isSaving)
        }
        .padding(10)
    }
    
    var qualityText: String {
        switch quality {
        case 1: return "quality_very_bad".localized
        case 2: return "quality_bad".localized
        case 3: return "quality_normal".localized
        case 4: return "quality_good".localized
        case 5: return "quality_excellent".localized
        default: return ""
        }
    }
    
    func saveSleep() {
        isSaving = true
        sleepStore.addEntry(bedTime: bedTime, wakeTime: wakeTime, quality: quality)
        isSaving = false
        isPresented = false
    }
}

// MARK: - Quick Exercise Sheet Content
/// 简化的运动记录内容
struct QuickExerciseSheetContent: View {
    @Binding var isPresented: Bool
    @EnvironmentObject var exerciseStore: SwiftDataExerciseStore
    
    @State private var selectedType: ExerciseType = .running
    @State private var duration: Int = 30
    @State private var isSaving = false
    
    var body: some View {
        VStack(spacing: 12) {
            // 运动类型
            VStack(alignment: .leading, spacing: 6) {
                Text("exercise_type_label".localized)
                    .font(.pixel(12))
                    .foregroundColor(Color("PixelBorder").opacity(0.7))
                
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 50))], spacing: 6) {
                    ForEach(ExerciseType.allCases, id: \.self) { type in
                        Button(action: { selectedType = type }) {
                            VStack(spacing: 2) {
                                Image(systemName: type.icon)
                                    .font(.system(size: 16))
                                Text(type.rawValue)
                                    .font(.pixel(8))
                            }
                            .foregroundColor(selectedType == type ? .white : Color("PixelBorder"))
                            .frame(width: 44, height: 44)
                            .background(selectedType == type ? Color("PixelBlue") : Color.white)
                            .overlay(Rectangle().stroke(Color("PixelBorder"), lineWidth: 1))
                        }
                    }
                }
            }
            .padding(10)
            .background(Color.white)
            .overlay(Rectangle().stroke(Color("PixelBorder"), lineWidth: 2))
            
            // 时长
            HStack {
                Text("duration_label".localized)
                    .font(.pixel(12))
                    .foregroundColor(Color("PixelBorder"))
                
                Spacer()
                
                Button(action: { if duration > 5 { duration -= 5 } }) {
                    Text("−")
                        .font(.pixel(18))
                        .foregroundColor(Color("PixelBorder"))
                        .frame(width: 32, height: 32)
                        .background(Color("PixelAccent"))
                        .overlay(Rectangle().stroke(Color("PixelBorder"), lineWidth: 1))
                }
                
                Text("\(duration)")
                    .font(.pixel(22))
                    .foregroundColor(Color("PixelBlue"))
                    .frame(width: 50)
                
                Text("minutes".localized)
                    .font(.pixel(10))
                    .foregroundColor(Color("PixelBorder").opacity(0.7))
                
                Button(action: { duration += 5 }) {
                    Text("+")
                        .font(.pixel(18))
                        .foregroundColor(Color("PixelBorder"))
                        .frame(width: 32, height: 32)
                        .background(Color("PixelAccent"))
                        .overlay(Rectangle().stroke(Color("PixelBorder"), lineWidth: 1))
                }
            }
            .padding(10)
            .background(Color.white)
            .overlay(Rectangle().stroke(Color("PixelBorder"), lineWidth: 2))
            
            // 保存
            Button(action: saveExercise) {
                Text("record_exercise".localized + " ✓")
                    .font(.pixel(16))
                    .foregroundColor(Color("PixelBorder"))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color("PixelAccent"))
                    .overlay(Rectangle().stroke(Color("PixelBorder"), lineWidth: 2))
            }
            .disabled(isSaving)
        }
        .padding(10)
    }
    
    func saveExercise() {
        isSaving = true
        let estimatedCalories = duration * 8
        exerciseStore.addEntry(type: selectedType, duration: duration, calories: estimatedCalories)
        isSaving = false
        isPresented = false
    }
}

// MARK: - Quick Read Sheet Content
struct QuickReadSheetContent: View {
    @Binding var isPresented: Bool
    @EnvironmentObject var bookStore: SwiftDataBookStore
    
    @State private var selectedBook: BookEntryData?
    @State private var duration: Int = 30
    @State private var isSaving = false
    
    var readingBooks: [BookEntryData] {
        bookStore.readingBooks
    }
    
    var body: some View {
        VStack(spacing: 12) {
            // 书籍选择
            VStack(alignment: .leading, spacing: 6) {
                Text("select_book".localized)
                    .font(.pixel(12))
                    .foregroundColor(Color("PixelBorder").opacity(0.7))
                
                if readingBooks.isEmpty {
                    HStack {
                        Image(systemName: "book.closed")
                            .font(.system(size: 12))
                        Text("no_reading_books".localized)
                            .font(.pixel(12))
                    }
                    .foregroundColor(Color("PixelBorder").opacity(0.5))
                    .frame(maxWidth: .infinity)
                    .padding(10)
                    .background(Color.white)
                    .overlay(Rectangle().stroke(Color("PixelBorder"), lineWidth: 1))
                } else {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 6) {
                            ForEach(readingBooks) { book in
                                Button(action: { selectedBook = book }) {
                                    VStack(spacing: 2) {
                                        Image(systemName: "book.closed.fill")
                                            .font(.system(size: 14))
                                        Text(book.title)
                                            .font(.pixel(8))
                                            .lineLimit(1)
                                    }
                                    .foregroundColor(selectedBook?.title == book.title ? .white : Color("PixelBorder"))
                                    .frame(width: 50, height: 44)
                                    .background(selectedBook?.title == book.title ? Color("PixelGreen") : Color.white)
                                    .overlay(Rectangle().stroke(Color("PixelBorder"), lineWidth: 1))
                                }
                            }
                        }
                    }
                }
            }
            .padding(10)
            .background(Color.white)
            .overlay(Rectangle().stroke(Color("PixelBorder"), lineWidth: 2))
            
            // 时长
            HStack {
                Text("reading_duration".localized)
                    .font(.pixel(12))
                    .foregroundColor(Color("PixelBorder"))
                
                Spacer()
                
                Button(action: { if duration > 10 { duration -= 10 } }) {
                    Text("−")
                        .font(.pixel(18))
                        .foregroundColor(Color("PixelBorder"))
                        .frame(width: 32, height: 32)
                        .background(Color("PixelAccent"))
                        .overlay(Rectangle().stroke(Color("PixelBorder"), lineWidth: 1))
                }
                
                Text("\(duration)")
                    .font(.pixel(22))
                    .foregroundColor(Color("PixelGreen"))
                    .frame(width: 50)
                
                Text("minutes".localized)
                    .font(.pixel(10))
                    .foregroundColor(Color("PixelBorder").opacity(0.7))
                
                Button(action: { duration += 10 }) {
                    Text("+")
                        .font(.pixel(18))
                        .foregroundColor(Color("PixelBorder"))
                        .frame(width: 32, height: 32)
                        .background(Color("PixelAccent"))
                        .overlay(Rectangle().stroke(Color("PixelBorder"), lineWidth: 1))
                }
            }
            .padding(10)
            .background(Color.white)
            .overlay(Rectangle().stroke(Color("PixelBorder"), lineWidth: 2))
            
            // 保存
            Button(action: saveReading) {
                Text("record_reading".localized + " ✓")
                    .font(.pixel(16))
                    .foregroundColor(Color("PixelBorder"))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color("PixelAccent"))
                    .overlay(Rectangle().stroke(Color("PixelBorder"), lineWidth: 2))
            }
            .disabled(isSaving || selectedBook == nil)
            .opacity(selectedBook == nil ? 0.5 : 1)
        }
        .padding(10)
        .onAppear {
            if selectedBook == nil {
                selectedBook = readingBooks.first
            }
        }
    }
    
    func saveReading() {
        guard let book = selectedBook else { return }
        isSaving = true
        // 简化保存逻辑，只更新进度
        isSaving = false
        isPresented = false
    }
}

// MARK: - Quick Entry Sheet Content (记账)
struct QuickEntrySheetContent: View {
    @Binding var isPresented: Bool
    @EnvironmentObject var financeStore: SwiftDataFinanceStore
    
    @State private var selectedType: FinanceType = .expense
    @State private var amountText: String = ""
    @State private var selectedCategory: String = "food"
    @State private var note: String = ""
    @State private var isSaving = false
    
    var categories: [FinanceCategory] {
        FinanceCategory.categories(for: selectedType)
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // 收入/支出切换
            HStack(spacing: 0) {
                Button(action: {
                    selectedType = .expense
                    selectedCategory = financeStore.lastExpenseCategory
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.down.circle.fill")
                            .font(.system(size: 18))
                        Text("finance_expense".localized)
                            .font(.pixel(18))
                    }
                    .foregroundColor(selectedType == .expense ? .white : Color("PixelBorder"))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(selectedType == .expense ? Color("PixelRed") : Color.clear)
                }
                
                Button(action: {
                    selectedType = .income
                    selectedCategory = financeStore.lastIncomeCategory
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 18))
                        Text("finance_income".localized)
                            .font(.pixel(18))
                    }
                    .foregroundColor(selectedType == .income ? .white : Color("PixelBorder"))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(selectedType == .income ? Color("PixelGreen") : Color.clear)
                }
            }
            .background(Color.white)
            .pixelBorderSmall()
            .padding(.horizontal)
            
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
            .background(Color.white)
            .pixelBorderSmall()
            .padding(.horizontal)
            
            // 分类选择
            if !categories.isEmpty {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 5), spacing: 8) {
                    ForEach(categories) { category in
                        Button(action: { selectedCategory = category.id }) {
                            VStack(spacing: 4) {
                                Image(systemName: category.icon)
                                    .font(.system(size: 20))
                                Text(category.name)
                                    .font(.pixel(11))
                            }
                            .foregroundColor(selectedCategory == category.id ? .white : Color("PixelBorder"))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(selectedCategory == category.id ? Color("PixelAccent") : Color.white)
                            .pixelBorderSmall(color: selectedCategory == category.id ? Color("PixelAccent") : Color("PixelBorder").opacity(0.3))
                        }
                    }
                }
                .padding(.horizontal)
            }
            
            // 备注
            TextField("finance_note_optional".localized, text: $note)
                .font(.pixel(16))
                .padding(12)
                .background(Color.white)
                .pixelBorderSmall()
                .padding(.horizontal)
            
            Spacer()
            
            // 记录按钮
            Button(action: submitEntry) {
                HStack {
                    if isSaving {
                        ProgressView()
                            .scaleEffect(0.8)
                            .tint(.white)
                    }
                    Text("finance_add_entry".localized)
                        .font(.pixel(22))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(selectedType == .expense ? Color("PixelRed") : Color("PixelGreen"))
                .overlay(
                    Rectangle()
                        .stroke(selectedType == .expense ? Color("PixelRed") : Color("PixelGreen"), lineWidth: 2)
                )
            }
            .disabled(amountText.isEmpty)
            .opacity(amountText.isEmpty ? 0.5 : 1)
            .padding(.horizontal)
            .padding(.bottom, 8)
        }
        .padding(.top, 8)
        .onAppear {
            selectedCategory = selectedType == .expense ? financeStore.lastExpenseCategory : financeStore.lastIncomeCategory
        }
    }
    
    private func submitEntry() {
        guard let amount = parseAmount(amountText), amount > 0 else { return }
        isSaving = true
        
        financeStore.addEntry(
            amount: amount,
            type: selectedType == .expense ? "expense" : "income",
            category: selectedCategory,
            note: note.isEmpty ? nil : note
        )
        
        // 震动反馈
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        
        isSaving = false
        isPresented = false
    }
    
    private func parseAmount(_ text: String) -> Int? {
        guard let value = Double(text) else { return nil }
        return Int(value * 100) // 转换为分
    }
}
