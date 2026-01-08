import SwiftUI

// MARK: - Pixel Date Picker

struct PixelDatePicker: View {
    let title: String
    @Binding var selection: Date
    var displayedComponents: DatePickerComponents = .date
    
    @State private var showPicker = false
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        switch displayedComponents {
        case .date:
            formatter.dateFormat = "yyyy-MM-dd"
        case .hourAndMinute:
            formatter.dateFormat = "HH:mm"
        case [.date, .hourAndMinute]:
            formatter.dateFormat = "yyyy-MM-dd HH:mm"
        default:
            formatter.dateFormat = "yyyy-MM-dd"
        }
        return formatter
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            if !title.isEmpty {
                Text(title)
                    .font(.pixel(14))
                    .foregroundColor(Color("PixelBorder"))
            }
            
            Button(action: { showPicker.toggle() }) {
                HStack {
                    Text(dateFormatter.string(from: selection))
                        .font(.pixel(16))
                        .foregroundColor(Color("PixelBorder"))
                    
                    Spacer()
                    
                    Image(systemName: displayedComponents == .hourAndMinute ? "clock.fill" : "calendar")
                        .font(.system(size: 16))
                        .foregroundColor(Color("PixelWood"))
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(Color.white)
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(Color("PixelBorder"), lineWidth: 2)
                )
            }
        }
        .sheet(isPresented: $showPicker) {
            PixelDatePickerSheet(
                selection: $selection,
                displayedComponents: displayedComponents,
                dismiss: { showPicker = false }
            )
        }
    }
}

// MARK: - Pixel Date Picker Sheet

struct PixelDatePickerSheet: View {
    @Binding var selection: Date
    let displayedComponents: DatePickerComponents
    let dismiss: () -> Void
    
    @State private var tempSelection: Date = Date()
    
    var body: some View {
        ZStack {
            Color("PixelBg").ignoresSafeArea()
            
            VStack(spacing: 16) {
                // 标题栏
                HStack {
                    Button("cancel".localized) {
                        dismiss()
                    }
                    .font(.pixel(16))
                    .foregroundColor(Color("PixelWood"))
                    
                    Spacer()
                    
                    Text(displayedComponents == .hourAndMinute ? "picker_select_time".localized : "picker_select_date".localized)
                        .font(.pixel(18))
                        .foregroundColor(Color("PixelBorder"))
                    
                    Spacer()
                    
                    Button("confirm".localized) {
                        selection = tempSelection
                        dismiss()
                    }
                    .font(.pixel(16))
                    .foregroundColor(Color("PixelAccent"))
                }
                .padding()
                .background(Color.white)
                .pixelBorderSmall()
                
                // 选择器内容
                if displayedComponents == .hourAndMinute {
                    PixelTimePicker(selection: $tempSelection)
                } else {
                    PixelCalendarPicker(selection: $tempSelection)
                }
            }
            .padding()
        }
        .presentationDetents(displayedComponents == .hourAndMinute ? [.height(380)] : [.height(480)])
        .presentationDragIndicator(.visible)
        .onAppear {
            tempSelection = selection
        }
    }
}

// MARK: - Pixel Time Picker

struct PixelTimePicker: View {
    @Binding var selection: Date
    
    @State private var selectedHour: Int = 0
    @State private var selectedMinute: Int = 0
    
    var body: some View {
        VStack(spacing: 20) {
            // 当前选择显示
            HStack(spacing: 4) {
                Text(String(format: "%02d", selectedHour))
                    .font(.pixel(56))
                    .foregroundColor(Color("PixelAccent"))
                    .frame(width: 80)
                
                Text(":")
                    .font(.pixel(48))
                    .foregroundColor(Color("PixelBorder"))
                
                Text(String(format: "%02d", selectedMinute))
                    .font(.pixel(56))
                    .foregroundColor(Color("PixelAccent"))
                    .frame(width: 80)
            }
            .padding(.vertical, 16)
            .padding(.horizontal, 24)
            .background(Color.white)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color("PixelBorder"), lineWidth: 3)
            )
            
            // 滚轮选择器
            HStack(spacing: 0) {
                // 小时选择器
                VStack(spacing: 4) {
                    Text("picker_hour".localized)
                        .font(.pixel(14))
                        .foregroundColor(Color("PixelWood"))
                    
                    PixelWheelPicker(
                        selection: $selectedHour,
                        range: 0..<24,
                        format: { String(format: "%02d", $0) }
                    )
                    .frame(width: 100, height: 150)
                }
                
                Text(":")
                    .font(.pixel(32))
                    .foregroundColor(Color("PixelBorder"))
                    .padding(.top, 20)
                
                // 分钟选择器
                VStack(spacing: 4) {
                    Text("picker_minute".localized)
                        .font(.pixel(14))
                        .foregroundColor(Color("PixelWood"))
                    
                    PixelWheelPicker(
                        selection: $selectedMinute,
                        range: 0..<60,
                        format: { String(format: "%02d", $0) }
                    )
                    .frame(width: 100, height: 150)
                }
            }
            .padding()
            .background(Color.white)
            .pixelBorderSmall()
        }
        .onAppear {
            let calendar = Calendar.current
            selectedHour = calendar.component(.hour, from: selection)
            selectedMinute = calendar.component(.minute, from: selection)
        }
        .onChange(of: selectedHour) { _ in updateSelection() }
        .onChange(of: selectedMinute) { _ in updateSelection() }
    }
    
    private func updateSelection() {
        var components = Calendar.current.dateComponents([.year, .month, .day], from: selection)
        components.hour = selectedHour
        components.minute = selectedMinute
        if let newDate = Calendar.current.date(from: components) {
            selection = newDate
        }
    }
}

// MARK: - Pixel Wheel Picker

struct PixelWheelPicker: View {
    @Binding var selection: Int
    let range: Range<Int>
    let format: (Int) -> String
    
    // 用于 iOS 17 scrollPosition 的绑定
    @State private var scrollID: Int?
    
    var body: some View {
        ZStack {
            // 选中框 (背景)
            Rectangle()
                .fill(Color("PixelAccent").opacity(0.1))
                .frame(height: 50)
                .overlay(
                    Rectangle()
                        .stroke(Color("PixelAccent"), lineWidth: 2)
                )
            
            // 滚动列表
            ScrollView(.vertical, showsIndicators: false) {
                LazyVStack(spacing: 0) {
                    // 顶部留白，使第一个元素可以居中
                    Color.clear.frame(height: 50)
                    
                    ForEach(range, id: \.self) { value in
                        Text(format(value))
                            .font(.pixel(value == (scrollID ?? selection) ? 24 : 18))
                            .foregroundColor(value == (scrollID ?? selection) ? Color("PixelAccent") : Color("PixelBorder").opacity(0.5))
                            .frame(height: 50)
                            .frame(maxWidth: .infinity)
                            .id(value)
                    }
                    
                    // 底部留白
                    Color.clear.frame(height: 50)
                }
                .scrollTargetLayout()
            }
            .scrollTargetBehavior(.viewAligned)
            .scrollPosition(id: $scrollID)
            .onChange(of: scrollID) {
                if let id = scrollID {
                    selection = id
                }
            }
            .onAppear {
                scrollID = selection
            }
            .onChange(of: selection) {
                if scrollID != selection {
                    scrollID = selection
                }
            }
        }
        .frame(height: 150)
        .clipped()
    }
}

// MARK: - Pixel Calendar Picker

struct PixelCalendarPicker: View {
    @Binding var selection: Date
    
    @State private var displayedMonth: Date = Date()
    
    private let calendar = Calendar.current
    private let weekdaySymbols = ["日", "一", "二", "三", "四", "五", "六"]
    
    private var monthYearString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年 MM月"
        return formatter.string(from: displayedMonth)
    }
    
    private var daysInMonth: [Date?] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: displayedMonth),
              let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: displayedMonth)) else {
            return []
        }
        
        let firstWeekday = calendar.component(.weekday, from: monthStart) - 1
        var days: [Date?] = Array(repeating: nil, count: firstWeekday)
        
        var currentDate = monthStart
        while currentDate < monthInterval.end {
            days.append(currentDate)
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate)!
        }
        
        // 补齐到完整的周
        while days.count % 7 != 0 {
            days.append(nil)
        }
        
        return days
    }
    
    var body: some View {
        VStack(spacing: 12) {
            // 月份导航
            HStack {
                Button(action: previousMonth) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(Color("PixelBorder"))
                        .frame(width: 44, height: 44)
                }
                
                Spacer()
                
                Text(monthYearString)
                    .font(.pixel(18))
                    .foregroundColor(Color("PixelBorder"))
                
                Spacer()
                
                Button(action: nextMonth) {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(Color("PixelBorder"))
                        .frame(width: 44, height: 44)
                }
            }
            
            // 星期标题
            HStack(spacing: 0) {
                ForEach(weekdaySymbols, id: \.self) { symbol in
                    Text(symbol)
                        .font(.pixel(12))
                        .foregroundColor(Color("PixelWood"))
                        .frame(maxWidth: .infinity)
                }
            }
            
            // 日期网格
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 0), count: 7), spacing: 4) {
                ForEach(Array(daysInMonth.enumerated()), id: \.offset) { _, date in
                    if let date = date {
                        DayCell(date: date, isSelected: isSameDay(date, selection)) {
                            selection = date
                        }
                    } else {
                        Text("")
                            .frame(height: 36)
                    }
                }
            }
        }
        .padding()
        .background(Color.white)
        .pixelBorderSmall()
        .onAppear {
            displayedMonth = selection
        }
    }
    
    private func previousMonth() {
        displayedMonth = calendar.date(byAdding: .month, value: -1, to: displayedMonth) ?? displayedMonth
    }
    
    private func nextMonth() {
        displayedMonth = calendar.date(byAdding: .month, value: 1, to: displayedMonth) ?? displayedMonth
    }
    
    private func isSameDay(_ date1: Date, _ date2: Date) -> Bool {
        calendar.isDate(date1, inSameDayAs: date2)
    }
}

// MARK: - Day Cell

struct DayCell: View {
    let date: Date
    let isSelected: Bool
    let action: () -> Void
    
    private var dayNumber: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: date)
    }
    
    private var isToday: Bool {
        Calendar.current.isDateInToday(date)
    }
    
    var body: some View {
        Button(action: action) {
            Text(dayNumber)
                .font(.pixel(isSelected ? 16 : 14))
                .foregroundColor(dayColor)
                .frame(height: 36)
                .frame(maxWidth: .infinity)
                .background(backgroundColor)
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(isToday && !isSelected ? Color("PixelAccent") : Color.clear, lineWidth: 2)
                )
                .cornerRadius(4)
        }
    }
    
    private var dayColor: Color {
        if isSelected {
            return .white
        } else if isToday {
            return Color("PixelAccent")
        } else {
            return Color("PixelBorder")
        }
    }
    
    private var backgroundColor: Color {
        if isSelected {
            return Color("PixelAccent")
        } else {
            return Color.clear
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 20) {
        PixelDatePicker(title: "选择日期", selection: .constant(Date()))
        PixelDatePicker(title: "选择时间", selection: .constant(Date()), displayedComponents: .hourAndMinute)
    }
    .padding()
    .background(Color("PixelBg"))
}
