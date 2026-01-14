import SwiftUI

struct SplashView: View {
    @Binding var isLoading: Bool
    @Binding var loadingProgress: Double
    @Binding var loadingMessage: String

    var body: some View {
        ZStack {
            // Background
            Color("PixelBg")
                .ignoresSafeArea()

            VStack(spacing: 40) {
                Spacer()

                // App Logo/Title
                VStack(spacing: 16) {
                    // Pixel-style icon placeholder
                    ZStack {
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color("PixelAccent"))
                            .frame(width: 120, height: 120)
                            .pixelBorderSmall()

                        Image(systemName: "gamecontroller.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.white)
                    }

                    Text("PIXEL QUEST")
                        .font(.pixel(36))
                        .foregroundColor(Color("PixelBorder"))

                    Text("Gamify Your Life")
                        .font(.pixel(16))
                        .foregroundColor(Color("PixelAccent"))
                }

                Spacer()

                // Loading Section
                VStack(spacing: 20) {
                    // Progress Bar
                    VStack(spacing: 8) {
                        // Progress bar container
                        ZStack(alignment: .leading) {
                            // Background
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.white)
                                .frame(height: 24)
                                .pixelBorderSmall()

                            // Progress fill
                            RoundedRectangle(cornerRadius: 2)
                                .fill(Color("PixelAccent"))
                                .frame(width: max(0, (UIScreen.main.bounds.width - 80) * loadingProgress), height: 20)
                                .padding(.leading, 2)
                                .animation(.easeInOut(duration: 0.3), value: loadingProgress)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, 40)

                        // Percentage
                        Text("\(Int(loadingProgress * 100))%")
                            .font(.pixel(18))
                            .foregroundColor(Color("PixelBorder"))
                    }

                    // Loading message
                    HStack(spacing: 8) {
                        // Animated dots
                        LoadingDots()

                        Text(loadingMessage)
                            .font(.pixel(14))
                            .foregroundColor(Color("PixelBorder").opacity(0.7))
                            .frame(minWidth: 200, alignment: .leading)
                    }
                }
                .padding(.bottom, 60)
            }
        }
    }
}

// MARK: - Loading Dots Animation
struct LoadingDots: View {
    @State private var animationPhase = 0

    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<3) { index in
                Circle()
                    .fill(Color("PixelAccent"))
                    .frame(width: 8, height: 8)
                    .opacity(animationPhase == index ? 1.0 : 0.3)
            }
        }
        .onAppear {
            Timer.scheduledTimer(withTimeInterval: 0.4, repeats: true) { _ in
                withAnimation {
                    animationPhase = (animationPhase + 1) % 3
                }
            }
        }
    }
}

#Preview {
    SplashView(
        isLoading: .constant(true),
        loadingProgress: .constant(0.6),
        loadingMessage: .constant("Loading quest data...")
    )
}
