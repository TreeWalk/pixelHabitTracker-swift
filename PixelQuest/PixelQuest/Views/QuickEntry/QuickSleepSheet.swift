import SwiftUI

struct QuickSleepSheet: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var sleepStore: SwiftDataSleepStore
    @EnvironmentObject var healthKitManager: HealthKitManager
    
    @State private var bedTime = Calendar.current.date(bySettingHour: 22, minute: 30, second: 0, of: Date()) ?? Date()
    @State private var wakeTime = Calendar.current.date(bySettingHour: 7, minute: 0, second: 0, of: Date()) ?? Date()
    @State private var quality: Int = 4
    @State private var isSyncing = false
    @State private var isSaving = false
    @State private var syncedData: SleepData?
    
    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "moon.zzz.fill")
                        .font(.system(size: 20))
                        .foregroundColor(Color("PixelBlue"))
                    Text("quick_sleep_title".localized)
                        .font(.pixel(20))
                        .foregroundColor(Color("PixelBorder"))
                }
                Spacer()
                Button(action: { dismiss() }) {
                    Text("✕")
                        .font(.pixel(20))
                        .foregroundColor(Color("PixelBorder"))
                        .frame(width: 32, height: 32)
                        .background(Color("PixelAccent"))
                        .pixelBorderSmall()
                }
            }
            .padding(.horizontal)
            .padding(.top, 20)
            
            // HealthKit Sync Button
            Button(action: syncFromHealthKit) {
                HStack(spacing: 8) {
                    if isSyncing {
                        ProgressView()
                            .scaleEffect(0.8)
                            .tint(.white)
                    } else {
                        Image(systemName: "heart.fill")
                    }
                    Text(isSyncing ? "同步中..." : "❤️ 从健康同步")
                        .font(.pixel(16))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color.red)
                .pixelBorderSmall(color: Color.red.opacity(0.7))
            }
            .disabled(isSyncing)
            .padding(.horizontal)
            
            // Time Inputs Card
            VStack(spacing: 12) {
                HStack {
                    // Bed Time
                    VStack(spacing: 4) {
                        HStack(spacing: 4) {
                            Image(systemName: "moon.fill")
                                .foregroundColor(Color("PixelBlue"))
                            Text("bed_time".localized)
                                .font(.pixel(14))
                                .foregroundColor(Color("PixelBorder"))
                        }
                        PixelDatePicker(title: "", selection: $bedTime, displayedComponents: .hourAndMinute)
                            .frame(width: 100)
                    }

                    Spacer()

                    // Wake Time
                    VStack(spacing: 4) {
                        HStack(spacing: 4) {
                            Image(systemName: "sun.max.fill")
                                .foregroundColor(Color("PixelAccent"))
                            Text("wake_time".localized)
                                .font(.pixel(14))
                                .foregroundColor(Color("PixelBorder"))
                        }
                        PixelDatePicker(title: "", selection: $wakeTime, displayedComponents: .hourAndMinute)
                            .frame(width: 100)
                    }
                }
            }
            .padding()
            .pixelCardSmall()
            .padding(.horizontal)
            
            // Quality Stars Card
            VStack(spacing: 8) {
                Text("sleep_quality_label".localized)
                    .font(.pixel(14))
                    .foregroundColor(Color("PixelBorder").opacity(0.7))

                HStack(spacing: 12) {
                    ForEach(1...5, id: \.self) { index in
                        Button(action: { quality = index }) {
                            Image(systemName: index <= quality ? "star.fill" : "star")
                                .font(.system(size: 28))
                                .foregroundColor(index <= quality ? Color("PixelAccent") : Color.gray.opacity(0.3))
                        }
                    }
                }

                Text(qualityText)
                    .font(.pixel(12))
                    .foregroundColor(Color("PixelAccent"))
            }
            .padding()
            .pixelCardSmall()
            .padding(.horizontal)
            
            Spacer()
            
            // Save Button
            Button(action: saveSleep) {
                HStack {
                    if isSaving {
                        ProgressView()
                            .scaleEffect(0.8)
                            .tint(Color("PixelBorder"))
                    }
                    Text("record_sleep".localized + " ✓")
                        .font(.pixel(22))
                }
                .foregroundColor(Color("PixelBorder"))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color("PixelAccent"))
                .pixelBorderSmall()
            }
            .disabled(isSaving)
            .padding(.horizontal)
            .padding(.bottom, 8)
        }
        .background(Color("PixelBg"))
    }
    
    var qualityText: String {
        switch quality {
        case 1: return "很差"
        case 2: return "较差"
        case 3: return "一般"
        case 4: return "良好"
        case 5: return "极佳"
        default: return ""
        }
    }
    
    func syncFromHealthKit() {
        isSyncing = true
        Task {
            let authorized = await healthKitManager.requestAuthorization()
            guard authorized else {
                isSyncing = false
                return
            }
            
            if let sleepData = await healthKitManager.fetchLastNightSleep() {
                syncedData = sleepData
                bedTime = sleepData.bedTime
                wakeTime = sleepData.wakeTime
            }
            isSyncing = false
        }
    }
    
    func saveSleep() {
        isSaving = true
        Task { @MainActor in
            if let data = syncedData {
                sleepStore.addEntryWithHealthKitData(
                    bedTime: data.bedTime,
                    wakeTime: data.wakeTime,
                    quality: quality,
                    deepSleep: data.deepSleep,
                    coreSleep: data.coreSleep,
                    remSleep: data.remSleep,
                    awakeTime: data.awakeTime,
                    sleepScore: data.sleepScore
                )
            } else {
                sleepStore.addEntry(bedTime: bedTime, wakeTime: wakeTime, quality: quality)
            }
            isSaving = false
            dismiss()
        }
    }
}

#Preview {
    QuickSleepSheet()
        .environmentObject(SwiftDataSleepStore())
        .environmentObject(HealthKitManager())
}
