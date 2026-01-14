import SwiftUI

struct WorldView: View {
    @State private var selectedLocation: Location?
    @State private var showDetail = false
    
    // Predefined locations
    private let locations = [
        Location(id: 1, name: "Home Base", icon: "home", banner: "homeLong", type: "Rest", desc: "Safe zone. Recover HP here.", unlocked: true),
        Location(id: 2, name: "Gym", icon: "gyn", banner: "gymLong", type: "Strength", desc: "Train your strength stats.", unlocked: true),
        Location(id: 3, name: "Library", icon: "library", banner: "libraryLongMorning", type: "Intellect", desc: "Ancient knowledge lies here.", unlocked: true),
        Location(id: 4, name: "Company", icon: "company", banner: "companyLongMorning", type: "Skill", desc: "Level up your career skills.", unlocked: true),
    ]
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    ForEach(locations) { location in
                        WorldLocationCard(location: location) {
                            selectedLocation = location
                            showDetail = true
                        }
                    }
                }
                .padding()
                .padding(.bottom, 80)
            }
            .background(Color("PixelBg"))
            .navigationTitle("world_title".localized)
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(isPresented: $showDetail) {
                if let location = selectedLocation {
                    switch location.id {
                    case 1:
                        HomeBaseDetailView(location: location)
                    case 2:
                        GymDetailView(location: location)
                    case 3:
                        LibraryDetailView(location: location)
                    case 4:
                        CompanyDetailView(location: location)
                    default:
                        Text("Unknown Location")
                    }
                }
            }
        }
    }
}

// MARK: - World Location Card
struct WorldLocationCard: View {
    let location: Location
    let onTap: () -> Void
    
    private func locationSubtitle() -> String {
        switch location.id {
        case 1: return "睡眠 · 休息"
        case 2: return "运动 · 锻炼"
        case 3: return "阅读 · 学习"
        case 4: return "工作 · 财务"
        default: return location.desc
        }
    }
    
    var body: some View {
        Button(action: onTap) {
            ZStack(alignment: .bottomLeading) {
                // Banner Background
                if let banner = location.banner {
                    Image(banner)
                        .resizable()
                        .interpolation(.none)
                        .aspectRatio(contentMode: .fill)
                        .frame(height: 160)
                        .clipped()
                }
                
                // Gradient Overlay
                LinearGradient(
                    colors: [.clear, .black.opacity(0.7)],
                    startPoint: .center,
                    endPoint: .bottom
                )
                
                // Text Content
                VStack(alignment: .leading, spacing: 4) {
                    Text(location.name.uppercased())
                        .font(.pixel(24))
                        .foregroundColor(.white)
                    
                    Text(locationSubtitle())
                        .font(.pixel(14))
                        .foregroundColor(.white.opacity(0.8))
                }
                .padding(16)
            }
            .frame(height: 160)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color("PixelBorder"), lineWidth: 3)
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    WorldView()
}
