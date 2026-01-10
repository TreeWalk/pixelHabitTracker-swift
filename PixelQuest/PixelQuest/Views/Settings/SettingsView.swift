import SwiftUI

struct SettingsView: View {
    @StateObject private var localizationManager = LocalizationManager.shared
    @State private var soundEnabled = true
    @State private var notificationsEnabled = true
    @State private var showAbout = false
    
    var body: some View {
        ZStack {
            // 渐变背景 - Nintendo Switch 风格
            LinearGradient(
                colors: [
                    Color("PixelBg"),
                    Color("PixelBg").opacity(0.95)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 20) {
                    // MARK: - Header
                    headerSection
                    
                    // MARK: - Game Settings
                    GameSectionHeader(title: "settings_game".localized, icon: "gamecontroller.fill", iconColor: Color("PixelBlue"))
                    
                    VStack(spacing: 8) {
                        // 语言设置
                        languageSettingsRow
                        
                        // 音效开关
                        GameStyleToggle(
                            icon: "speaker.wave.2.fill",
                            iconColor: .purple,
                            title: "settings_sound".localized,
                            isOn: $soundEnabled
                        )
                        
                        // 通知开关
                        GameStyleToggle(
                            icon: "bell.fill",
                            iconColor: .orange,
                            title: "settings_notifications".localized,
                            isOn: $notificationsEnabled
                        )
                    }
                    .padding(.horizontal)
                    
                    // MARK: - Data Settings
                    GameSectionHeader(title: "settings_data".localized, icon: "externaldrive.fill", iconColor: Color("PixelGreen"))
                    
                    VStack(spacing: 8) {
                        AnimatedSettingsRow(
                            icon: "square.and.arrow.up",
                            iconColor: Color("PixelBlue"),
                            title: "settings_export".localized,
                            subtitle: "settings_export_desc".localized
                        ) {
                            // Export action
                        }
                        
                        AnimatedSettingsRow(
                            icon: "arrow.clockwise",
                            iconColor: Color("PixelRed"),
                            title: "settings_reset".localized,
                            subtitle: "settings_reset_desc".localized
                        ) {
                            // Reset action
                        }
                    }
                    .padding(.horizontal)
                    
                    // MARK: - About
                    GameSectionHeader(title: "settings_about".localized, icon: "info.circle.fill", iconColor: .gray)
                    
                    VStack(spacing: 8) {
                        AnimatedSettingsRow(
                            icon: "star.fill",
                            iconColor: Color("PixelAccent"),
                            title: "settings_rate".localized
                        ) {
                            // Rate app action
                        }
                        
                        AnimatedSettingsRow(
                            icon: "questionmark.circle",
                            iconColor: .blue,
                            title: "settings_help".localized
                        ) {
                            // Help action
                        }
                        
                        // 版本信息
                        HStack {
                            Text("settings_version".localized)
                                .font(.pixel(14))
                                .foregroundColor(.gray)
                            Spacer()
                            Text("v1.0.0")
                                .font(.pixel(14))
                                .foregroundColor(Color("PixelWood"))
                        }
                        .padding(16)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .padding(.horizontal)
                    
                    // Footer
                    Text("※ PIXEL QUEST ※")
                        .font(.pixel(12))
                        .foregroundColor(.gray.opacity(0.5))
                        .padding(.top, 20)
                        .padding(.bottom, 40)
                }
                .padding(.top, 20)
            }
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        HStack(spacing: 16) {
            // 设置图标
            ZStack {
                Circle()
                    .fill(Color("PixelAccent").opacity(0.15))
                    .frame(width: 60, height: 60)
                
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 28))
                    .foregroundColor(Color("PixelAccent"))
                    .rotationEffect(.degrees(-15))
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text("settings_title".localized)
                    .font(.pixel(24))
                    .foregroundColor(Color("PixelBorder"))
                
                Text("settings_subtitle".localized)
                    .font(.pixel(12))
                    .foregroundColor(.gray)
            }
            
            Spacer()
        }
        .padding()
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
        .padding(.horizontal)
    }
    
    // MARK: - Language Settings Row
    private var languageSettingsRow: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 16) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.blue.opacity(0.15))
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: "globe")
                        .font(.system(size: 20))
                        .foregroundColor(.blue)
                }
                
                Text("settings_language".localized)
                    .font(.pixel(16))
                    .foregroundColor(Color("PixelBorder"))
                
                Spacer()
            }
            
            // 语言选择按钮
            HStack(spacing: 12) {
                languageButton(language: "en", name: "English", flag: "🇺🇸")
                languageButton(language: "zh-Hans", name: "中文", flag: "🇨🇳")
            }
        }
        .padding(12)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    private func languageButton(language: String, name: String, flag: String) -> some View {
        Button(action: {
            withAnimation(.spring(response: 0.3)) {
                localizationManager.currentLanguage = language
            }
            let feedback = UIImpactFeedbackGenerator(style: .light)
            feedback.impactOccurred()
        }) {
            HStack(spacing: 8) {
                Text(flag)
                    .font(.system(size: 20))
                Text(name)
                    .font(.pixel(14))
                    .foregroundColor(localizationManager.currentLanguage == language ? .white : Color("PixelBorder"))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                localizationManager.currentLanguage == language
                    ? Color("PixelBlue")
                    : Color("PixelBg")
            )
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(
                        localizationManager.currentLanguage == language
                            ? Color("PixelBlue")
                            : Color("PixelBorder").opacity(0.3),
                        lineWidth: 2
                    )
            )
        }
        .buttonStyle(BounceButtonStyle())
    }
}

#Preview {
    SettingsView()
}
