import SwiftUI

struct SettingsView: View {
    @StateObject private var localizationManager = LocalizationManager.shared
    
    var body: some View {
        ZStack {
            Color("PixelBg").ignoresSafeArea()
            
            VStack(spacing: 20) {
                // Language Picker
                VStack(alignment: .leading, spacing: 8) {
                    Text("settings_language".localized)
                        .font(.pixel(16))
                        .foregroundColor(Color("PixelBorder"))
                        .padding(.leading, 16)
                    
                    Picker("settings_language".localized, selection: $localizationManager.currentLanguage) {
                        Text("language_english".localized).tag("en")
                        Text("language_chinese".localized).tag("zh-Hans")
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, 16)
                }
                .padding()
                .background(Color.white)
                .pixelBorderSmall()
                .padding(.horizontal, 16)
                .padding(.top, 20)
                
                // Work in Progress
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 64))
                    .foregroundColor(Color("PixelWood"))
                
                Text("settings_work_in_progress".localized)
                    .font(.pixel(24))
                    .foregroundColor(Color("PixelWood"))
                
                Spacer()
            }
            .opacity(0.8)
        }
    }
}

#Preview {
    SettingsView()
}
