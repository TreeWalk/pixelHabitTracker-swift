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
            // Main Tab View
            TabView(selection: $selectedTab) {
                DashboardView()
                    .tabItem {
                        VStack {
                            Image(systemName: "person.crop.circle")
                            Text("Dashboard")
                        }
                    }
                    .tag(0)
                
                QuestsView()
                    .tabItem {
                        VStack {
                            Image(systemName: "scroll.fill")
                            Text("Actions")
                        }
                    }
                    .tag(1)
                
                AssetsView()
                    .tabItem {
                        VStack {
                            Image(systemName: "shippingbox.fill")
                            Text("Assets")
                        }
                    }
                    .tag(2)
                
                WorldView()
                    .tabItem {
                        VStack {
                            Image(systemName: "map.fill")
                            Text("World")
                        }
                    }
                    .tag(3)
            }
            .tint(Color("PixelAccent"))
            
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
                        fabActionButton(pixelIcon: "pixel_sleep", color: .blue, label: "Sleep") {
                            showSleepSheet = true
                            isFabMenuOpen = false
                        }
                        fabActionButton(pixelIcon: "pixel_strength", color: .red, label: "Sport") {
                            showSportSheet = true
                            isFabMenuOpen = false
                        }
                    }
                    HStack(spacing: 30) {
                        fabActionButton(pixelIcon: "pixel_book", color: .green, label: "Read") {
                            showReadSheet = true
                            isFabMenuOpen = false
                        }
                        fabActionButton(pixelIcon: "pixel_money", color: .orange, label: "Bill") {
                            showBillSheet = true
                            isFabMenuOpen = false
                        }
                    }
                }
                .offset(y: -140)
                .opacity(isFabMenuOpen ? 1 : 0)
            }
            
            // Main FAB Button (Pixel Style)
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
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color(red: 0.15, green: 0.15, blue: 0.15), lineWidth: 3)
                    )
                    .shadow(color: Color("PixelAccent").opacity(0.4), radius: 8, y: 4)
                    .rotationEffect(.degrees(isFabMenuOpen ? 45 : 0))
            }
            .padding(.bottom, 60) // Above tab bar
        }
        .onAppear {
            setupTabBarAppearance()
        }
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
                    // Pixel-style rounded rectangle with black border (NES controller style)
                    RoundedRectangle(cornerRadius: 6)
                        .fill(color)
                        .frame(width: 56, height: 56)
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(Color(red: 0.15, green: 0.15, blue: 0.15), lineWidth: 3)
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
    
    // MARK: - Tab Bar Appearance
    private func setupTabBarAppearance() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(named: "PixelBg")
        
        UITabBar.appearance().layer.borderWidth = 2
        UITabBar.appearance().layer.borderColor = UIColor(named: "PixelBorder")?.cgColor
        
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }
}

#Preview {
    ContentView()
        .environmentObject(SwiftDataQuestStore())
        .environmentObject(SwiftDataItemStore())
        .environmentObject(SwiftDataLogStore())
}

