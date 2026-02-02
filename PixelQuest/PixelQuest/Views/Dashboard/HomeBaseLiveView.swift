import SwiftUI

struct HomeBaseLiveView: View {
    @State private var waveOffset: CGFloat = 0
    
    var body: some View {
        ZStack {
            // Background with time-based gradient
            TimeBasedBackground()
                .frame(height: 180)
            
            // Dynamic Pixel Elements
            VStack {
                Spacer()
                
                HStack(alignment: .bottom, spacing: 0) {
                    // Floating "Island" or Floor
                    Rectangle()
                        .fill(Color.darkCoffee)
                        .frame(height: 4)
                        .overlay(
                            VStack(spacing: 0) {
                                Rectangle()
                                    .fill(Color.white.opacity(0.15))
                                    .frame(height: 1)
                                Spacer()
                            }
                        )
                }
            }
            
            // Character & Ambient Elements
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    
                    // Small "Home" Silhouette or Icon
                    Image("home")
                        .resizable()
                        .interpolation(.none)
                        .scaledToFit()
                        .frame(width: 64, height: 64)
                        .pixelGlow(color: .white, isActive: true, intensity: 0.2)
                        .offset(y: -4)
                        .padding(.trailing, 40)
                }
            }
            
            // Floating Sparkles
            GeometryReader { geometry in
                PixelParticleEmitter(
                    preset: .sparkle,
                    origin: CGPoint(x: geometry.size.width * 0.3, y: geometry.size.height * 0.4),
                    isEmitting: true
                )
            }
            
            // Title Overlay
            VStack {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("home_base".localized.uppercased())
                            .font(.pixelHeader(24))
                            .foregroundColor(.white)
                            .pixelHardShadow(color: .black.opacity(0.5), offset: 2)
                        
                        Text("safe_zone".localized)
                            .font(.pixel(12))
                            .foregroundColor(.white.opacity(0.8))
                            .pixelHardShadow(color: .black.opacity(0.3), offset: 1)
                    }
                    Spacer()
                }
                .padding(20)
                Spacer()
            }
        }
        .frame(height: 180)
        .cozyBorder(color: .darkCoffee, lineWidth: 3, cornerRadius: 16)
        .pixelHardShadow(color: .darkCoffee.opacity(0.25), offset: 5)
        .padding(.horizontal)
    }
}

#Preview {
    VStack {
        HomeBaseLiveView()
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color.creamBg)
}
