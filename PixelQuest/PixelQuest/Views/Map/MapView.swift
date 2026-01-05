import SwiftUI

struct MapView: View {
    @EnvironmentObject var logStore: LogStore
    @EnvironmentObject var localizationManager: LocalizationManager
    @State private var selectedLocation: Location?
    @State private var showDetail = false
    
    let locations: [Location] = [
        Location(id: 1, name: "Home Base", icon: "home", banner: "homeLong", type: "Rest", desc: "Safe zone. Recover HP here.", unlocked: true),
        Location(id: 2, name: "Gym", icon: "gyn", banner: "gymLong", type: "Strength", desc: "Train your strength stats.", unlocked: true),
        Location(id: 3, name: "Library", icon: "library", banner: "libraryLongMorning", type: "Intellect", desc: "Ancient knowledge lies here.", unlocked: true),
        Location(id: 4, name: "Company", icon: "company", banner: "companyLongMorning", type: "Skill", desc: "Level up your career skills.", unlocked: true),
    ]
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color("PixelBg").ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header
                    VStack(alignment: .leading, spacing: 4) {
                        Text("map_title".localized)
                            .font(.pixel(28))
                            .foregroundColor(Color("PixelBorder"))
                            
                        Text("Select a destination to explore")
                            .font(.pixel(16))
                            .foregroundColor(Color("PixelAccent"))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    
                    Rectangle()
                        .fill(Color("PixelAccent"))
                        .frame(height: 4)
                        .padding(.horizontal)
                        .padding(.bottom, 16)
                    
                    // Building List
                    ScrollView {
                        VStack(spacing: 16) {
                            ForEach(locations) { location in
                                BuildingCard(location: location) {
                                    selectedLocation = location
                                    showDetail = true
                                }
                            }
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 100)
                    }
                }
            }
            .navigationDestination(isPresented: $showDetail) {
                if let location = selectedLocation {
                    switch location.id {
                    case 1:
                        // Home Base 使用睡眠追踪页面
                        HomeBaseDetailView(location: location)
                    case 2:
                        // Gym 使用运动记录页面
                        GymDetailView(location: location)
                    case 3:
                        // Library 使用读书记录页面
                        LibraryDetailView(location: location)
                    case 4:
                        // Company 使用财务记录页面
                        CompanyDetailView(location: location)
                    default:
                        LocationDetailView(location: location)
                    }
                }
            }
        }
    }
}

struct BuildingCard: View {
    let location: Location
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            ZStack(alignment: .leading) {
                // Banner Background
                if let banner = location.banner {
                    Image(banner)
                        .resizable()
                        .interpolation(.none)
                        .aspectRatio(contentMode: .fill)
                        .frame(height: 140)
                        .clipped()
                }
                
                // Gradient Overlay
                LinearGradient(
                    colors: [.black.opacity(0.8), .black.opacity(0.4), .clear],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                
                // Content
                HStack(spacing: 16) {
                    Image(location.icon)
                        .resizable()
                        .interpolation(.none)
                        .frame(width: 56, height: 56)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(location.name.uppercased())
                            .font(.pixel(24))
                            .foregroundColor(.white)
                            
                        
                        HStack(spacing: 8) {
                            Text(location.type.uppercased())
                                .font(.pixel(14))
                                .foregroundColor(.yellow)
                            
                            Circle()
                                .fill(.white.opacity(0.5))
                                .frame(width: 4, height: 4)
                            
                            Text("MAP UNIT \(location.id)")
                                .font(.pixel(12))
                                .foregroundColor(.white.opacity(0.7))
                        }
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 24)
            }
            .frame(height: 140)
            .pixelBorderSmall()
            .pixelCorners()
        }
        .buttonStyle(.plain)
    }
}

struct LocationDetailView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var logStore: LogStore
    let location: Location
    @State private var inputText = ""
    
    var body: some View {
        GeometryReader { geometry in
            let contentWidth = geometry.size.width - 32 // 16pt padding on each side
            
            ZStack {
                Color("PixelBg").ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Banner
                        if let banner = location.banner {
                            Image(banner)
                                .resizable()
                                .interpolation(.none)
                                .aspectRatio(contentMode: .fill)
                                .frame(width: contentWidth, height: 200)
                                .clipped()
                                .pixelBorderSmall()
                        }
                        
                        // Section Title
                        HStack(spacing: 8) {
                            Rectangle()
                                .fill(Color("PixelBlue"))
                                .frame(width: 4, height: 20)
                            Text("ADVENTURE LOG")
                                .font(.pixel(20))
                                .foregroundColor(Color("PixelBorder"))
                            Spacer()
                        }
                        .frame(width: contentWidth, alignment: .leading)
                        
                        // Input Area
                        TextEditor(text: $inputText)
                            .font(.pixel(16))
                            .frame(width: contentWidth, height: 100)
                            .padding(8)
                            .background(Color.white)
                            .pixelBorderSmall()
                        
                        // Log Button
                        Button(action: addLog) {
                            Text("LOG ENTRY")
                                .font(.pixel(18))
                                .foregroundColor(Color("PixelBorder"))
                                .frame(width: contentWidth)
                                .padding(.vertical, 12)
                                .background(Color("PixelAccent"))
                                .pixelBorderSmall()
                        }
                        .disabled(inputText.isEmpty)
                        .opacity(inputText.isEmpty ? 0.5 : 1)
                        
                        // Log List
                        let logs = logStore.getLogs(locationId: location.id)
                        if logs.isEmpty {
                            VStack(spacing: 8) {
                                Text("No entries recorded...")
                                    .font(.pixel(16))
                                Text("Every step is a story.")
                                    .font(.pixel(14))
                            }
                            .foregroundColor(.gray)
                            .frame(width: contentWidth)
                            .padding(.vertical, 40)
                        } else {
                            VStack(spacing: 12) {
                                ForEach(logs) { log in
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text("LOGGED AT \(log.formattedDate)")
                                            .font(.pixel(12))
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 4)
                                            .background(Color("PixelBlue").opacity(0.1))
                                            .foregroundColor(Color("PixelBlue"))
                                        
                                        Text(log.text)
                                            .font(.pixel(16))
                                            .foregroundColor(Color("PixelBorder"))
                                            .fixedSize(horizontal: false, vertical: true)
                                    }
                                    .frame(width: contentWidth, alignment: .leading)
                                    .padding()
                                    .background(.white)
                                    .pixelBorderSmall()
                                    .overlay(
                                        Rectangle()
                                            .fill(Color("PixelBlue"))
                                            .frame(width: 4),
                                        alignment: .leading
                                    )
                                }
                            }
                        }
                    }
                    .frame(width: geometry.size.width)
                    .padding(.vertical, 20)
                }
            }
        }
        .navigationTitle(location.name)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { dismiss() }) {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.left")
                        Text("BACK")
                    }
                    .font(.pixel(16))
                    .foregroundColor(Color("PixelBorder"))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color("PixelAccent"))
                    .pixelBorderSmall()
                }
            }
        }
    }
    
    private func addLog() {
        guard !inputText.isEmpty else { return }
        let text = inputText
        inputText = ""
        
        Task {
            await logStore.addLog(locationId: location.id, text: text)
        }
    }
}

#Preview {
    MapView()
        .environmentObject(LogStore())
}
