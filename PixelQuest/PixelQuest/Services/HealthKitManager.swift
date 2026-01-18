import Foundation
import HealthKit

@MainActor
class HealthKitManager: ObservableObject {
    private let healthStore = HKHealthStore()
    
    @Published var isAuthorized = false
    @Published var isLoading = false
    @Published var error: String?
    
    // MARK: - Authorization
    
    /// 检查 HealthKit 是否可用
    var isHealthKitAvailable: Bool {
        HKHealthStore.isHealthDataAvailable()
    }
    
    /// 请求 HealthKit 授权
    func requestAuthorization() async -> Bool {
        guard isHealthKitAvailable else {
            error = "此设备不支持 HealthKit"
            return false
        }

        // 需要读取的数据类型
        var typesToRead: Set<HKObjectType> = [HKObjectType.workoutType()]

        // 安全添加可选类型
        if let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) {
            typesToRead.insert(sleepType)
        }
        if let heartRateType = HKObjectType.quantityType(forIdentifier: .heartRate) {
            typesToRead.insert(heartRateType)
        }
        if let energyType = HKObjectType.quantityType(forIdentifier: .activeEnergyBurned) {
            typesToRead.insert(energyType)
        }
        if let distanceType = HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning) {
            typesToRead.insert(distanceType)
        }
        
        do {
            try await healthStore.requestAuthorization(toShare: [], read: typesToRead)
            isAuthorized = true
            return true
        } catch {
            self.error = "授权失败: \(error.localizedDescription)"
            return false
        }
    }
    
    // MARK: - Sleep Data
    
    /// 获取昨晚的睡眠数据
    func fetchLastNightSleep() async -> SleepData? {
        guard isHealthKitAvailable,
              let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else {
            return nil
        }

        // 获取昨天晚上到今天早上的时间范围
        let calendar = Calendar.current
        let now = Date()

        guard let yesterday = calendar.date(byAdding: .day, value: -1, to: now),
              let yesterday6PM = calendar.date(bySettingHour: 18, minute: 0, second: 0, of: yesterday),
              let today12PM = calendar.date(bySettingHour: 12, minute: 0, second: 0, of: now) else {
            return nil
        }
        
        let predicate = HKQuery.predicateForSamples(withStart: yesterday6PM, end: today12PM, options: .strictStartDate)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)
        
        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: sleepType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [sortDescriptor]
            ) { _, samples, error in
                guard let samples = samples as? [HKCategorySample], !samples.isEmpty else {
                    continuation.resume(returning: nil)
                    return
                }
                
                let sleepData = self.processSleepSamples(samples)
                continuation.resume(returning: sleepData)
            }
            healthStore.execute(query)
        }
    }
    
    /// 处理睡眠数据样本
    private func processSleepSamples(_ samples: [HKCategorySample]) -> SleepData {
        var deepSleep: TimeInterval = 0
        var coreSleep: TimeInterval = 0
        var remSleep: TimeInterval = 0
        var awakeTime: TimeInterval = 0
        var inBedStart: Date?
        var inBedEnd: Date?
        
        for sample in samples {
            let duration = sample.endDate.timeIntervalSince(sample.startDate)
            
            if #available(iOS 16.0, *) {
                switch sample.value {
                case HKCategoryValueSleepAnalysis.asleepDeep.rawValue:
                    deepSleep += duration
                case HKCategoryValueSleepAnalysis.asleepCore.rawValue:
                    coreSleep += duration
                case HKCategoryValueSleepAnalysis.asleepREM.rawValue:
                    remSleep += duration
                case HKCategoryValueSleepAnalysis.awake.rawValue:
                    awakeTime += duration
                case HKCategoryValueSleepAnalysis.inBed.rawValue:
                    if inBedStart == nil { inBedStart = sample.startDate }
                    inBedEnd = sample.endDate
                default:
                    // 旧版本的睡眠数据格式
                    if sample.value == HKCategoryValueSleepAnalysis.asleep.rawValue {
                        coreSleep += duration
                    }
                }
            } else {
                // iOS 15 及以下只有 asleep 和 inBed
                if sample.value == HKCategoryValueSleepAnalysis.asleep.rawValue {
                    coreSleep += duration
                }
            }
            
            // 更新入睡和起床时间
            if let currentStart = inBedStart {
                if sample.startDate < currentStart {
                    inBedStart = sample.startDate
                }
            } else {
                inBedStart = sample.startDate
            }

            if let currentEnd = inBedEnd {
                if sample.endDate > currentEnd {
                    inBedEnd = sample.endDate
                }
            } else {
                inBedEnd = sample.endDate
            }
        }
        
        let totalSleep = deepSleep + coreSleep + remSleep
        let score = calculateSleepScore(
            totalSleep: totalSleep,
            deepSleep: deepSleep,
            remSleep: remSleep,
            awakeTime: awakeTime
        )
        
        return SleepData(
            bedTime: inBedStart ?? Date(),
            wakeTime: inBedEnd ?? Date(),
            deepSleep: deepSleep,
            coreSleep: coreSleep,
            remSleep: remSleep,
            awakeTime: awakeTime,
            sleepScore: score
        )
    }
    
    /// 计算睡眠分数
    private func calculateSleepScore(totalSleep: TimeInterval, deepSleep: TimeInterval, remSleep: TimeInterval, awakeTime: TimeInterval) -> Int {
        var score = 0
        let totalHours = totalSleep / 3600
        
        // 基础分 (最高60分) - 7-9小时最佳
        if totalHours >= 7 && totalHours <= 9 {
            score += 60
        } else if totalHours >= 6 && totalHours < 7 {
            score += 50
        } else if totalHours > 9 && totalHours <= 10 {
            score += 50
        } else if totalHours >= 5 {
            score += 40
        } else {
            score += 30
        }
        
        // 深睡加分 (最高20分)
        let deepPercent = totalSleep > 0 ? (deepSleep / totalSleep) * 100 : 0
        if deepPercent >= 20 && deepPercent <= 25 {
            score += 20
        } else if deepPercent >= 15 && deepPercent < 20 || deepPercent > 25 && deepPercent <= 30 {
            score += 15
        } else if deepPercent > 0 {
            score += 10
        }
        
        // REM加分 (最高15分)
        let remPercent = totalSleep > 0 ? (remSleep / totalSleep) * 100 : 0
        if remPercent >= 20 && remPercent <= 25 {
            score += 15
        } else if remPercent >= 15 && remPercent < 20 {
            score += 10
        } else if remPercent > 0 {
            score += 5
        }
        
        // 清醒扣分 (最多扣15分)
        let awakeMinutes = awakeTime / 60
        let awakeDeduction = min(Int(awakeMinutes / 10) * 3, 15)
        score -= awakeDeduction
        
        return max(0, min(100, score))
    }
    
    // MARK: - Workout Data
    
    /// 获取今日运动数据
    func fetchTodayWorkouts() async -> [WorkoutData] {
        guard isHealthKitAvailable else { return [] }

        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())

        guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else {
            return []
        }
        
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: endOfDay, options: .strictStartDate)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
        
        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: HKObjectType.workoutType(),
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [sortDescriptor]
            ) { _, samples, error in
                guard let workouts = samples as? [HKWorkout] else {
                    continuation.resume(returning: [])
                    return
                }
                
                let workoutDataList = workouts.map { workout -> WorkoutData in
                    WorkoutData(
                        type: workout.workoutActivityType,
                        startTime: workout.startDate,
                        endTime: workout.endDate,
                        duration: workout.duration,
                        calories: workout.totalEnergyBurned?.doubleValue(for: .kilocalorie()) ?? 0,
                        distance: workout.totalDistance?.doubleValue(for: .meter()) ?? 0
                    )
                }
                
                continuation.resume(returning: workoutDataList)
            }
            healthStore.execute(query)
        }
    }
}

// MARK: - Data Models

struct SleepData {
    let bedTime: Date
    let wakeTime: Date
    let deepSleep: TimeInterval
    let coreSleep: TimeInterval
    let remSleep: TimeInterval
    let awakeTime: TimeInterval
    let sleepScore: Int
    
    var totalSleep: TimeInterval {
        deepSleep + coreSleep + remSleep
    }
    
    var totalSleepHours: Double {
        totalSleep / 3600
    }
    
    // 格式化时长
    func formatDuration(_ interval: TimeInterval) -> String {
        let hours = Int(interval / 3600)
        let minutes = Int((interval.truncatingRemainder(dividingBy: 3600)) / 60)
        if hours > 0 {
            return "\(hours)h\(minutes)m"
        }
        return "\(minutes)m"
    }
    
    // 各阶段占比
    var deepPercent: Double { totalSleep > 0 ? (deepSleep / totalSleep) * 100 : 0 }
    var corePercent: Double { totalSleep > 0 ? (coreSleep / totalSleep) * 100 : 0 }
    var remPercent: Double { totalSleep > 0 ? (remSleep / totalSleep) * 100 : 0 }
    var awakePercent: Double { totalSleep > 0 ? (awakeTime / totalSleep) * 100 : 0 }
    
    // 睡眠分数等级
    var scoreLevel: String {
        switch sleepScore {
        case 85...100: return "优秀"
        case 70..<85: return "良好"
        case 55..<70: return "一般"
        default: return "较差"
        }
    }
}

struct WorkoutData: Identifiable {
    let id = UUID()
    let type: HKWorkoutActivityType
    let startTime: Date
    let endTime: Date
    let duration: TimeInterval
    let calories: Double
    let distance: Double // 米
    
    var durationMinutes: Int {
        Int(duration / 60)
    }
    
    var distanceKM: Double {
        distance / 1000
    }
    
    var formattedDuration: String {
        let minutes = Int(duration / 60)
        if minutes >= 60 {
            let hours = minutes / 60
            let mins = minutes % 60
            return mins > 0 ? "\(hours)h\(mins)m" : "\(hours)h"
        }
        return "\(minutes)min"
    }
    
    // 运动类型中文名称
    var typeName: String {
        WorkoutTypeMapper.getName(for: type)
    }
    
    // 运动类型图标
    var typeIcon: String {
        WorkoutTypeMapper.getIcon(for: type)
    }
}

// MARK: - Workout Type Mapper

struct WorkoutTypeMapper {
    static func getName(for type: HKWorkoutActivityType) -> String {
        switch type {
        // 有氧运动
        case .running: return "跑步"
        case .walking: return "步行"
        case .cycling: return "骑行"
        case .swimming: return "游泳"
        case .hiking: return "徒步"
        case .elliptical: return "椭圆机"
        case .rowing: return "划船"
        case .stairClimbing: return "爬楼梯"
        case .jumpRope: return "跳绳"
        case .highIntensityIntervalTraining: return "HIIT"
        case .mixedCardio: return "混合有氧"
        
        // 力量训练
        case .traditionalStrengthTraining: return "力量训练"
        case .functionalStrengthTraining: return "功能性训练"
        case .coreTraining: return "核心训练"
        case .flexibility: return "柔韧训练"
        
        // 身心运动
        case .yoga: return "瑜伽"
        case .pilates: return "普拉提"
        case .mindAndBody: return "身心训练"
        
        // 球类运动
        case .basketball: return "篮球"
        case .soccer: return "足球"
        case .tennis: return "网球"
        case .badminton: return "羽毛球"
        case .tableTennis: return "乒乓球"
        case .golf: return "高尔夫"
        case .volleyball: return "排球"
        case .baseball: return "棒球"
        case .softball: return "垒球"
        
        // 格斗运动
        case .boxing: return "拳击"
        case .martialArts: return "武术"
        case .wrestling: return "摔跤"
        case .kickboxing: return "跆拳道"
        
        // 水上运动
        case .surfingSports: return "冲浪"
        case .waterFitness: return "水中健身"
        case .paddleSports: return "桨板运动"
        case .waterPolo: return "水球"
        case .sailing: return "帆船"
        
        // 冬季运动
        case .snowboarding: return "滑雪板"
        case .snowSports: return "雪上运动"
        case .skatingSports: return "滑冰"
        case .crossCountrySkiing: return "越野滑雪"
        case .downhillSkiing: return "高山滑雪"
        
        // 舞蹈
        case .dance: return "舞蹈"
        case .socialDance: return "社交舞"
        case .cardioDance: return "有氧舞蹈"
        
        // 其他
        case .climbing: return "攀岩"
        case .fishing: return "钓鱼"
        case .hunting: return "打猎"
        case .play: return "自由活动"
        case .crossTraining: return "交叉训练"
        case .fitnessGaming: return "健身游戏"
        
        default: return "其他运动"
        }
    }
    
    static func getIcon(for type: HKWorkoutActivityType) -> String {
        switch type {
        // 有氧运动
        case .running: return "figure.run"
        case .walking: return "figure.walk"
        case .cycling: return "bicycle"
        case .swimming: return "figure.pool.swim"
        case .hiking: return "figure.hiking"
        case .elliptical: return "figure.elliptical"
        case .rowing: return "figure.rower"
        case .stairClimbing: return "figure.stairs"
        case .jumpRope: return "figure.jumprope"
        case .highIntensityIntervalTraining: return "flame.fill"
        case .mixedCardio: return "figure.mixed.cardio"
        
        // 力量训练
        case .traditionalStrengthTraining, .functionalStrengthTraining: return "dumbbell.fill"
        case .coreTraining: return "figure.core.training"
        case .flexibility: return "figure.flexibility"
        
        // 身心运动
        case .yoga: return "figure.yoga"
        case .pilates: return "figure.pilates"
        case .mindAndBody: return "figure.mind.and.body"
        
        // 球类运动
        case .basketball: return "basketball.fill"
        case .soccer: return "soccerball"
        case .tennis: return "tennis.racket"
        case .badminton: return "figure.badminton"
        case .tableTennis: return "figure.table.tennis"
        case .golf: return "figure.golf"
        case .volleyball: return "volleyball.fill"
        case .baseball, .softball: return "baseball.fill"
        
        // 格斗运动
        case .boxing, .kickboxing: return "figure.boxing"
        case .martialArts: return "figure.martial.arts"
        case .wrestling: return "figure.wrestling"
        
        // 水上运动
        case .surfingSports: return "figure.surfing"
        case .waterFitness: return "figure.water.fitness"
        case .paddleSports: return "oar.2.crossed"
        case .waterPolo: return "figure.waterpolo"
        case .sailing: return "sailboat.fill"
        
        // 冬季运动
        case .snowboarding: return "figure.snowboarding"
        case .snowSports, .crossCountrySkiing, .downhillSkiing: return "figure.skiing.downhill"
        case .skatingSports: return "figure.skating"
        
        // 舞蹈
        case .dance, .socialDance, .cardioDance: return "figure.dance"
        
        // 其他
        case .climbing: return "figure.climbing"
        case .fishing: return "fish.fill"
        case .play: return "gamecontroller.fill"
        case .crossTraining: return "figure.cross.training"
        case .fitnessGaming: return "gamecontroller.fill"
        
        default: return "figure.mixed.cardio"
        }
    }
}
