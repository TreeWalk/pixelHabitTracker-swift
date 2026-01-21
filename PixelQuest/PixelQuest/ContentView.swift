import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 0
    @State private var isFabMenuOpen = false
    @State private var showBillSheet = false
    @State private var showSleepSheet = false
    @State private var showSportSheet = false
    @State private var showReadSheet = false
    @State private var showQuestSheet = false
    @State private var hideTabBar = false
    @EnvironmentObject var localizationManager: LocalizationManager
    
    // Static haptic generator to avoid recreation on each tap
    private static let hapticGenerator: UIImpactFeedbackGenerator = {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.prepare()
        return generator
    }()
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // Main Content (no native TabView)
            Group {
                switch selectedTab {
                case 0:
                    NavigationStack { 
                        DashboardView(hideTabBar: $hideTabBar)
                    }
                case 1:
                    QuestsView()
                case 2:
                    AssetsView()
                case 3:
                    WorldView()
                default:
                    DashboardView(hideTabBar: $hideTabBar)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            // FAB Overlay - Blur background
            if isFabMenuOpen {
                Rectangle()
                    .fill(.ultraThinMaterial)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            isFabMenuOpen = false
                        }
                    }
            }
            
            // Fan-shaped menu buttons (5 buttons in arc) - Always present for animation
            ZStack {
                    // Button 1: Sleep (leftmost)
                    fabActionButton(pixelIcon: "pixel_sleep", color: Color("PixelBlue"), label: "Sleep") {
                        showSleepSheet = true
                        isFabMenuOpen = false
                    }
                    .offset(
                        x: isFabMenuOpen ? fanOffset(index: 0).x : 0,
                        y: isFabMenuOpen ? fanOffset(index: 0).y : 0
                    )
                    
                    // Button 2: Sport (left-center)
                    fabActionButton(pixelIcon: "pixel_strength", color: Color("PixelRed"), label: "Sport") {
                        showSportSheet = true
                        isFabMenuOpen = false
                    }
                    .offset(
                        x: isFabMenuOpen ? fanOffset(index: 1).x : 0,
                        y: isFabMenuOpen ? fanOffset(index: 1).y : 0
                    )
                    
                    // Button 3: Quest (center)
                    fabActionButton(pixelIcon: "pixel_todo", color: Color("PixelAccent"), label: "Quest") {
                        showQuestSheet = true
                        isFabMenuOpen = false
                    }
                    .offset(
                        x: isFabMenuOpen ? fanOffset(index: 2).x : 0,
                        y: isFabMenuOpen ? fanOffset(index: 2).y : 0
                    )
                    
                    // Button 4: Read (right-center)
                    fabActionButton(pixelIcon: "pixel_book", color: Color("PixelGreen"), label: "Read") {
                        showReadSheet = true
                        isFabMenuOpen = false
                    }
                    .offset(
                        x: isFabMenuOpen ? fanOffset(index: 3).x : 0,
                        y: isFabMenuOpen ? fanOffset(index: 3).y : 0
                    )
                    
                    // Button 5: Bill (rightmost)
                    fabActionButton(pixelIcon: "pixel_money", color: Color("PixelAccent"), label: "Bill") {
                        showBillSheet = true
                        isFabMenuOpen = false
                    }
                    .offset(
                        x: isFabMenuOpen ? fanOffset(index: 4).x : 0,
                        y: isFabMenuOpen ? fanOffset(index: 4).y : 0
                    )
            }
            .offset(y: -90)
            .opacity(isFabMenuOpen ? 1 : 0)
            .allowsHitTesting(isFabMenuOpen)
            
            // Main FAB Button (Cozy Style)
            Button(action: {
                Self.hapticGenerator.impactOccurred()
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    isFabMenuOpen.toggle()
                }
            }) {
                Image(systemName: "plus")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 56, height: 56)
                    .background(Color("PixelAccent"))
                    .clipShape(Rectangle())
                    .overlay(
                        Rectangle()
                            .stroke(Color.darkCoffee, lineWidth: 3)
                    )
                    .background(
                        Rectangle()
                            .fill(Color.darkCoffee.opacity(0.3))
                            .offset(x: 4, y: 4)
                    )
                    .rotationEffect(.degrees(isFabMenuOpen ? 45 : 0))
            }
            .padding(.bottom, 90) // Above custom tab bar
            .offset(y: hideTabBar ? 200 : 0)
            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: hideTabBar)
            
            // Custom Floating Tab Bar
            FloatingTabBar(selectedTab: $selectedTab)
                .padding(.bottom, 8)
                .offset(y: hideTabBar ? 200 : 0)
                .animation(.spring(response: 0.4, dampingFraction: 0.8), value: hideTabBar)
        }
        .background(Color.creamBg.ignoresSafeArea())
        // Bill Window (像素风格窗口弹窗)
        .pixelWindow(
            isPresented: $showBillSheet,
            title: "quick_bill_title".localized,
            icon: "yensign.circle.fill",
            iconColor: Color("PixelAccent")
        ) {
            QuickEntrySheetContent(isPresented: $showBillSheet)
        }
        // Sleep Window
        .pixelWindow(
            isPresented: $showSleepSheet,
            title: "quick_sleep_title".localized,
            icon: "moon.zzz.fill",
            iconColor: Color("PixelBlue")
        ) {
            QuickSleepSheetContent(isPresented: $showSleepSheet)
        }
        // Sport Window
        .pixelWindow(
            isPresented: $showSportSheet,
            title: "quick_exercise_title".localized,
            icon: "figure.run",
            iconColor: Color("PixelRed")
        ) {
            QuickExerciseSheetContent(isPresented: $showSportSheet)
        }
        // Read Window
        .pixelWindow(
            isPresented: $showReadSheet,
            title: "quick_read_title".localized,
            icon: "book.fill",
            iconColor: Color("PixelGreen")
        ) {
            QuickReadSheetContent(isPresented: $showReadSheet)
        }
        // Quest Window
        .pixelWindow(
            isPresented: $showQuestSheet,
            title: "quick_quest_title".localized,
            icon: "checkmark.circle.fill",
            iconColor: Color("PixelAccent")
        ) {
            QuickQuestSheetContent(isPresented: $showQuestSheet)
        }
    }
    
    // MARK: - FAB Action Button (Pixel Style)
    private func fabActionButton(pixelIcon: String, color: Color, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ZStack {
                    // Pixel style square button
                    Rectangle()
                        .fill(color)
                        .frame(width: 56, height: 56)
                        .overlay(
                            Rectangle()
                                .stroke(Color.darkCoffee, lineWidth: 3)
                        )
                        .background(
                            Rectangle()
                                .fill(Color.darkCoffee.opacity(0.3))
                                .offset(x: 4, y: 4)
                        )

                    Image(pixelIcon)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 28, height: 28)
                }

                Text(label)
                    .font(.pixel(12))
                    .foregroundColor(Color("PixelBorder"))
            }
        }
    }
    
    // MARK: - Fan Layout Helper
    /// Calculate position for fan-shaped button layout
    /// Creates a semi-circular arc above the main FAB
    private func fanOffset(index: Int) -> CGPoint {
        let totalButtons = 5
        let radius: CGFloat = 140 // Distance from center
        let startAngle: CGFloat = 180 // Start from left (180°)
        let endAngle: CGFloat = 0 // End at right (0°)
        let angleRange = startAngle - endAngle
        
        // Calculate angle for this button
        let angle = startAngle - (angleRange * CGFloat(index) / CGFloat(totalButtons - 1))
        let radians = angle * .pi / 180
        
        // Convert polar to cartesian coordinates
        let x = radius * cos(radians)
        let y = -radius * sin(radians) // Negative because SwiftUI y-axis points down
        
        return CGPoint(x: x, y: y)
    }
}

#Preview {
    ContentView()
        .environmentObject(SwiftDataQuestStore())
        .environmentObject(SwiftDataItemStore())
        .environmentObject(SwiftDataLogStore())
}
