import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 0
    @State private var isFabMenuOpen = false
    @State private var showBillSheet = false
    @State private var showSleepSheet = false
    @State private var showSportSheet = false
    @State private var showReadSheet = false
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
                    NavigationStack { DashboardView() }
                case 1:
                    QuestsView()
                case 2:
                    AssetsView()
                case 3:
                    WorldView()
                default:
                    DashboardView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            // FAB Overlay
            if isFabMenuOpen {
                // Blur background
                Rectangle()
                    .fill(.ultraThinMaterial)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            isFabMenuOpen = false
                        }
                    }
                
                // Sub-menu buttons with pixel icons
                VStack(spacing: 20) {
                    HStack(spacing: 30) {
                        fabActionButton(pixelIcon: "pixel_sleep", color: Color("PixelBlue"), label: "Sleep") {
                            showSleepSheet = true
                            isFabMenuOpen = false
                        }
                        fabActionButton(pixelIcon: "pixel_strength", color: Color("PixelRed"), label: "Sport") {
                            showSportSheet = true
                            isFabMenuOpen = false
                        }
                    }
                    HStack(spacing: 30) {
                        fabActionButton(pixelIcon: "pixel_book", color: Color("PixelGreen"), label: "Read") {
                            showReadSheet = true
                            isFabMenuOpen = false
                        }
                        fabActionButton(pixelIcon: "pixel_money", color: Color("PixelAccent"), label: "Bill") {
                            showBillSheet = true
                            isFabMenuOpen = false
                        }
                    }
                }
                .offset(y: -180)
                .opacity(isFabMenuOpen ? 1 : 0)
            }
            
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
            
            // Custom Floating Tab Bar
            FloatingTabBar(selectedTab: $selectedTab)
                .padding(.bottom, 8)
        }
        .background(Color.creamBg.ignoresSafeArea())
        // Bill Sheet
        .sheet(isPresented: $showBillSheet) {
            QuickEntrySheet()
                .presentationDetents([.medium])
        }
        // Sleep Sheet
        .sheet(isPresented: $showSleepSheet) {
            QuickSleepSheet()
                .presentationDetents([.fraction(0.6)])
        }
        // Sport Sheet
        .sheet(isPresented: $showSportSheet) {
            QuickExerciseSheet()
                .presentationDetents([.fraction(0.65)])
        }
        // Read Sheet
        .sheet(isPresented: $showReadSheet) {
            QuickReadSheet()
                .presentationDetents([.fraction(0.7)])
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
                    .foregroundColor(.white)
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(SwiftDataQuestStore())
        .environmentObject(SwiftDataItemStore())
        .environmentObject(SwiftDataLogStore())
}
