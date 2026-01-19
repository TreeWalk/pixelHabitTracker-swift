import SwiftUI

struct QuickExerciseSheet: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var exerciseStore: SwiftDataExerciseStore
    @EnvironmentObject var healthKitManager: HealthKitManager
    
    @State private var selectedType: ExerciseType = .running
    @State private var duration: Int = 30
    @State private var isSyncing = false
    @State private var isSaving = false
    @State private var syncedWorkouts: [WorkoutData] = []
    
    var body: some View {
        ZStack {
            Color("PixelBg").ignoresSafeArea()
            
            VStack(spacing: 16) {
                // Header
                HStack {
                    HStack(spacing: 8) {
                        Image(systemName: "figure.run")
                            .font(.system(size: 20))
                            .foregroundColor(Color("PixelRed"))
                        Text("快速记录运动")
                            .font(.pixel(22))
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
                
                // Synced Workouts
                if !syncedWorkouts.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(syncedWorkouts) { workout in
                                VStack(spacing: 4) {
                                    Image(systemName: workout.typeIcon)
                                        .font(.system(size: 20))
                                        .foregroundColor(Color("PixelRed"))
                                    Text(workout.formattedDuration)
                                        .font(.pixel(12))
                                        .foregroundColor(Color("PixelBorder"))
                                    Text("\(Int(workout.calories))kcal")
                                        .font(.pixel(10))
                                        .foregroundColor(Color("PixelBorder").opacity(0.7))
                                }
                                .padding(10)
                                .background(Color.white)
                                .pixelBorderSmall(color: Color("PixelRed").opacity(0.5))
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                
                // Exercise Type Card
                VStack(alignment: .leading, spacing: 8) {
                    Text("运动类型")
                        .font(.pixel(14))
                        .foregroundColor(Color("PixelBorder").opacity(0.7))

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(ExerciseType.allCases, id: \.self) { type in
                                Button(action: { selectedType = type }) {
                                    VStack(spacing: 4) {
                                        Image(systemName: type.icon)
                                            .font(.system(size: 20))
                                        Text(type.rawValue)
                                            .font(.pixel(10))
                                    }
                                    .foregroundColor(selectedType == type ? .white : Color("PixelBorder"))
                                    .frame(width: 56, height: 56)
                                    .background(selectedType == type ? Color("PixelBlue") : Color.white)
                                    .pixelBorderSmall(color: selectedType == type ? Color("PixelBlue") : Color("PixelBorder"))
                                }
                            }
                        }
                    }
                }
                .padding()
                .pixelCardSmall()
                .padding(.horizontal)
                
                // Duration Card
                HStack {
                    Text("时长")
                        .font(.pixel(16))
                        .foregroundColor(Color("PixelBorder"))

                    Spacer()

                    Button(action: { if duration > 5 { duration -= 5 } }) {
                        Text("−")
                            .font(.pixel(24))
                            .foregroundColor(Color("PixelBorder"))
                            .frame(width: 40, height: 40)
                            .background(Color("PixelAccent"))
                            .pixelBorderSmall()
                    }

                    Text("\(duration)")
                        .font(.pixel(28))
                        .foregroundColor(Color("PixelBlue"))
                        .frame(width: 60)

                    Text("分钟")
                        .font(.pixel(14))
                        .foregroundColor(Color("PixelBorder").opacity(0.7))

                    Button(action: { duration += 5 }) {
                        Text("+")
                            .font(.pixel(24))
                            .foregroundColor(Color("PixelBorder"))
                            .frame(width: 40, height: 40)
                            .background(Color("PixelAccent"))
                            .pixelBorderSmall()
                    }
                }
                .padding()
                .pixelCardSmall()
                .padding(.horizontal)
                
                Spacer()
                
                // Save Button
                Button(action: saveExercise) {
                    HStack {
                        if isSaving {
                            ProgressView()
                                .scaleEffect(0.8)
                                .tint(Color("PixelBorder"))
                        }
                        Text("记录运动 ✓")
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
                .padding(.bottom)
            }
            .padding(.top)
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
            
            syncedWorkouts = await healthKitManager.fetchTodayWorkouts()
            if let first = syncedWorkouts.first {
                duration = Int(first.duration / 60)
            }
            isSyncing = false
        }
    }
    
    func saveExercise() {
        isSaving = true
        let estimatedCalories = duration * 8
        exerciseStore.addEntry(type: selectedType, duration: duration, calories: estimatedCalories)
        isSaving = false
        dismiss()
    }
}

#Preview {
    QuickExerciseSheet()
        .environmentObject(SwiftDataExerciseStore())
        .environmentObject(HealthKitManager())
}
