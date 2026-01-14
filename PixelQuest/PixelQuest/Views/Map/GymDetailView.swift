import SwiftUI

struct GymDetailView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var exerciseStore: SwiftDataExerciseStore
    @EnvironmentObject var healthKitManager: HealthKitManager
    @EnvironmentObject var localizationManager: LocalizationManager
    let location: Location
    
    @State private var selectedType: ExerciseType = .running
    @State private var duration: Int = 30
    @State private var calories: Int = 200
    @State private var isSaving = false
    @State private var isSyncing = false
    @State private var syncedWorkouts: [WorkoutData] = []
    
    var body: some View {
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
                            .frame(maxWidth: .infinity)
                            .frame(height: 180)
                            .clipped()
                            .pixelBorderSmall()
                            .padding(.horizontal, 16)
                    }

                    // Exercise Log Section
                    VStack(spacing: 16) {
                        // Section Title
                        HStack(spacing: 8) {
                            Image(systemName: "dumbbell.fill")
                                .font(.system(size: 18))
                                .foregroundColor(Color("PixelBlue"))
                            Rectangle()
                                .fill(Color("PixelBlue"))
                                .frame(width: 4, height: 20)
                            Text("exercise_log".localized)
                                .font(.pixel(20))
                                .foregroundColor(Color("PixelBorder"))
                            Spacer()
                        }
                        .padding(.horizontal, 16)
                        
                        // HealthKit Sync Button
                        Button(action: syncFromHealthKit) {
                            HStack(spacing: 8) {
                                if isSyncing {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                } else {
                                    Image(systemName: "heart.fill")
                                }
                                Text(isSyncing ? "sleep_syncing".localized : "sleep_sync_health".localized)
                                    .font(.pixel(14))
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(Color.red.opacity(0.8))
                            .pixelBorderSmall(color: Color.red)
                        }
                        .disabled(isSyncing)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                        .padding(.horizontal, 16)
                        
                        // Synced Workouts from HealthKit
                        if !syncedWorkouts.isEmpty {
                            VStack(spacing: 8) {
                                ForEach(syncedWorkouts) { workout in
                                    HealthKitWorkoutRow(workout: workout)
                                        .padding(.horizontal, 16)
                                }
                            }
                        }
                        
                        // Exercise Type Picker
                        VStack(spacing: 16) {
                            // Type Selection
                            VStack(alignment: .leading, spacing: 8) {
                                Text("exercise_type".localized)
                                    .font(.pixel(14))
                                    .foregroundColor(Color("PixelBorder").opacity(0.7))
                                
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 10) {
                                        ForEach(ExerciseType.allCases, id: \.self) { type in
                                            Button(action: { selectedType = type }) {
                                                VStack(spacing: 6) {
                                                    Image(systemName: type.icon)
                                                        .font(.system(size: 20))
                                                    Text(type.rawValue)
                                                        .font(.pixel(12))
                                                }
                                                .foregroundColor(selectedType == type ? .white : Color("PixelBorder"))
                                                .padding(.horizontal, 12)
                                                .padding(.vertical, 10)
                                                .background(selectedType == type ? Color("PixelBlue") : Color.white)
                                                .pixelBorderSmall(color: selectedType == type ? Color("PixelBlue") : Color("PixelBorder"))
                                            }
                                        }
                                    }
                                }
                            }
                            
                            Divider()
                            
                            // Duration Input
                            HStack {
                                Image(systemName: "timer")
                                    .foregroundColor(Color("PixelBlue"))
                                Text("exercise_duration".localized)
                                    .font(.pixel(16))
                                    .foregroundColor(Color("PixelBorder"))
                                Spacer()
                                
                                HStack(spacing: 8) {
                                    Button(action: { if duration > 5 { duration -= 5 } }) {
                                        Image(systemName: "minus")
                                            .font(.system(size: 14, weight: .bold))
                                            .foregroundColor(Color("PixelBorder"))
                                            .frame(width: 28, height: 28)
                                            .background(Color("PixelAccent"))
                                            .pixelBorderSmall()
                                    }
                                    
                                    Text("\(duration)")
                                        .font(.pixel(18))
                                        .foregroundColor(Color("PixelBlue"))
                                        .frame(width: 50)
                                    
                                    Button(action: { duration += 5 }) {
                                        Image(systemName: "plus")
                                            .font(.system(size: 14, weight: .bold))
                                            .foregroundColor(Color("PixelBorder"))
                                            .frame(width: 28, height: 28)
                                            .background(Color("PixelAccent"))
                                            .pixelBorderSmall()
                                    }
                                    
                                    Text("min")
                                        .font(.pixel(14))
                                        .foregroundColor(Color("PixelBorder").opacity(0.7))
                                }
                            }
                            
                            Divider()
                            
                            // Calories Input
                            HStack {
                                Image(systemName: "flame.fill")
                                    .foregroundColor(Color("PixelRed"))
                                Text("exercise_calories".localized)
                                    .font(.pixel(16))
                                    .foregroundColor(Color("PixelBorder"))
                                Spacer()
                                
                                HStack(spacing: 8) {
                                    Button(action: { if calories > 10 { calories -= 10 } }) {
                                        Image(systemName: "minus")
                                            .font(.system(size: 14, weight: .bold))
                                            .foregroundColor(Color("PixelBorder"))
                                            .frame(width: 28, height: 28)
                                            .background(Color("PixelAccent"))
                                            .pixelBorderSmall()
                                    }
                                    
                                    Text("\(calories)")
                                        .font(.pixel(18))
                                        .foregroundColor(Color("PixelRed"))
                                        .frame(width: 60)
                                    
                                    Button(action: { calories += 10 }) {
                                        Image(systemName: "plus")
                                            .font(.system(size: 14, weight: .bold))
                                            .foregroundColor(Color("PixelBorder"))
                                            .frame(width: 28, height: 28)
                                            .background(Color("PixelAccent"))
                                            .pixelBorderSmall()
                                    }
                                    
                                    Text("kcal")
                                        .font(.pixel(14))
                                        .foregroundColor(Color("PixelBorder").opacity(0.7))
                                }
                            }
                        }
                        .padding()
                        .background(Color.white)
                        .pixelBorderSmall()
                        .padding(.horizontal, 16)

                        // Save Button
                        Button(action: saveExercise) {
                            HStack(spacing: 8) {
                                if isSaving {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                }
                                Image(systemName: "plus.circle.fill")
                                Text("exercise_record".localized)
                                    .font(.pixel(18))
                            }
                            .foregroundColor(Color("PixelBorder"))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color("PixelAccent"))
                            .pixelBorderSmall()
                        }
                        .disabled(isSaving)
                        .padding(.horizontal, 16)
                    }

                    // Weekly Stats Section
                    VStack(spacing: 16) {
                        HStack(spacing: 8) {
                            Image(systemName: "chart.bar.fill")
                                .font(.system(size: 18))
                                .foregroundColor(Color("PixelBlue"))
                            Rectangle()
                                .fill(Color("PixelBlue"))
                                .frame(width: 4, height: 20)
                            Text("exercise_week_stats".localized)
                                .font(.pixel(20))
                                .foregroundColor(Color("PixelBorder"))
                            Spacer()
                        }
                        .padding(.horizontal, 16)
                        
                        // Stats Cards
                        HStack(spacing: 12) {
                            ExerciseStatCard(
                                icon: "timer",
                                value: formatDuration(exerciseStore.weekTotalDuration),
                                label: "exercise_total_duration".localized,
                                color: Color("PixelBlue")
                            )
                            .frame(maxWidth: .infinity)
                            
                            ExerciseStatCard(
                                icon: "flame.fill",
                                value: "\(exerciseStore.weekTotalCalories)",
                                label: "exercise_total_calories".localized,
                                color: Color("PixelRed")
                            )
                            .frame(maxWidth: .infinity)
                        }
                        .padding(.horizontal, 16)
                    }

                    // Today's Records Section
                    if !exerciseStore.todayEntries.isEmpty {
                        VStack(spacing: 16) {
                            HStack(spacing: 8) {
                                Image(systemName: "list.bullet")
                                    .font(.system(size: 18))
                                    .foregroundColor(Color("PixelBlue"))
                                Rectangle()
                                    .fill(Color("PixelBlue"))
                                    .frame(width: 4, height: 20)
                                Text("今日记录")
                                    .font(.pixel(20))
                                    .foregroundColor(Color("PixelBorder"))
                                Spacer()
                            }
                            .padding(.horizontal, 16)
                            
                            ForEach(exerciseStore.todayEntries) { entry in
                                ExerciseEntryRow(entry: entry)
                                    .padding(.horizontal, 16)
                            }
                        }
                    }
                }
                .padding(.vertical, 16)
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
                        Text("back".localized)
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
        .onAppear {
            // Data is loaded automatically on configure
        }
    }
    
    func saveExercise() {
        isSaving = true
        exerciseStore.addEntry(type: selectedType, duration: duration, calories: calories)
        isSaving = false
    }
    
    func formatDuration(_ minutes: Int) -> String {
        if minutes >= 60 {
            let hours = minutes / 60
            let mins = minutes % 60
            return mins > 0 ? "\(hours)h\(mins)m" : "\(hours)h"
        }
        return "\(minutes)m"
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
            isSyncing = false
        }
    }
}

// MARK: - Exercise Stat Card

struct ExerciseStatCard: View {
    let icon: String
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(color)
            Text(value)
                .font(.pixel(22))
                .foregroundColor(color)
            Text(label)
                .font(.pixel(12))
                .foregroundColor(Color("PixelBorder").opacity(0.7))
        }
        .padding()
        .background(Color.white)
        .pixelBorderSmall()
    }
}

// MARK: - Exercise Entry Row

struct ExerciseEntryRow: View {
    let entry: ExerciseEntryData
    
    // Convert String type to ExerciseType enum
    private var exerciseType: ExerciseType {
        ExerciseType(rawValue: entry.type) ?? .running
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // Type Icon
            Image(systemName: exerciseType.icon)
                .font(.system(size: 24))
                .foregroundColor(Color("PixelBlue"))
                .frame(width: 44, height: 44)
                .background(Color("PixelBlue").opacity(0.1))
                .pixelBorderSmall(color: Color("PixelBlue").opacity(0.3))
            
            // Details
            VStack(alignment: .leading, spacing: 4) {
                Text(exerciseType.rawValue)
                    .font(.pixel(16))
                    .foregroundColor(Color("PixelBorder"))
                
                HStack(spacing: 12) {
                    HStack(spacing: 4) {
                        Image(systemName: "timer")
                            .font(.system(size: 12))
                        Text(entry.formattedDuration)
                            .font(.pixel(12))
                    }
                    .foregroundColor(Color("PixelBlue"))
                    
                    HStack(spacing: 4) {
                        Image(systemName: "flame.fill")
                            .font(.system(size: 12))
                        Text("\(entry.calories)kcal")
                            .font(.pixel(12))
                    }
                    .foregroundColor(Color("PixelRed"))
                }
            }
            
            Spacer()
        }
        .padding()
        .background(Color.white)
        .pixelBorderSmall()
    }
}

// MARK: - HealthKit Workout Row

struct HealthKitWorkoutRow: View {
    let workout: WorkoutData
    
    var body: some View {
        HStack(spacing: 12) {
            // Type Icon
            Image(systemName: workout.typeIcon)
                .font(.system(size: 24))
                .foregroundColor(.red)
                .frame(width: 44, height: 44)
                .background(Color.red.opacity(0.1))
                .pixelBorderSmall(color: Color.red.opacity(0.3))
            
            // Details
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(workout.typeName)
                        .font(.pixel(16))
                        .foregroundColor(Color("PixelBorder"))
                    
                    Image(systemName: "heart.fill")
                        .font(.system(size: 10))
                        .foregroundColor(.red)
                }
                
                HStack(spacing: 12) {
                    HStack(spacing: 4) {
                        Image(systemName: "timer")
                            .font(.system(size: 12))
                        Text(workout.formattedDuration)
                            .font(.pixel(12))
                    }
                    .foregroundColor(Color("PixelBlue"))
                    
                    HStack(spacing: 4) {
                        Image(systemName: "flame.fill")
                            .font(.system(size: 12))
                        Text("\(Int(workout.calories))kcal")
                            .font(.pixel(12))
                    }
                    .foregroundColor(Color("PixelRed"))
                    
                    if workout.distance > 0 {
                        HStack(spacing: 4) {
                            Image(systemName: "location.fill")
                                .font(.system(size: 12))
                            Text(String(format: "%.1fkm", workout.distanceKM))
                                .font(.pixel(12))
                        }
                        .foregroundColor(Color("PixelGreen"))
                    }
                }
            }
            
            Spacer()
        }
        .padding()
        .background(Color.white)
        .pixelBorderSmall()
    }
}
