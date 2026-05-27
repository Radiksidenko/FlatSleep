//
//  HealthKitManager.swift
//  FlatSleep
//
//  Created by Radomyr Sidenko on 26.05.2026.
//

import Foundation
import HealthKit

class HealthKitManager: ObservableObject {
    let healthStore = HKHealthStore()
    
    @Published var statusMessage: String = "Ready to generate"
    @Published var monthlySleepData: [Date: DailySleepSummary] = [:]
    
    func fetchAverageHeartRate(from start: Date, to end: Date, completion: @escaping (Double?) -> Void) {
        guard let heartRateType = HKObjectType.quantityType(forIdentifier: .heartRate) else {
            completion(nil)
            return
        }
        
        let predicate = HKQuery.predicateForSamples(withStart: start, end: end, options: .strictStartDate)
        let countUnit = HKUnit.count().unitDivided(by: HKUnit.minute())
        
        let query = HKStatisticsQuery(quantityType: heartRateType, quantitySamplePredicate: predicate, options: .discreteAverage) { _, statistics, _ in
            guard let averageQuantity = statistics?.averageQuantity() else {
                completion(nil)
                return
            }
            let bpm = averageQuantity.doubleValue(for: countUnit)
            DispatchQueue.main.async {
                completion(bpm)
            }
        }
        healthStore.execute(query)
    }
    
    func fetchAverageRespiratoryRate(from start: Date, to end: Date, completion: @escaping (Double?) -> Void) {
        guard let respiratoryType = HKObjectType.quantityType(forIdentifier: .respiratoryRate) else {
            completion(nil)
            return
        }
        
        let predicate = HKQuery.predicateForSamples(withStart: start, end: end, options: .strictStartDate)
        let countUnit = HKUnit.count().unitDivided(by: HKUnit.minute())
        
        let query = HKStatisticsQuery(quantityType: respiratoryType, quantitySamplePredicate: predicate, options: .discreteAverage) { _, statistics, _ in
            guard let averageQuantity = statistics?.averageQuantity() else {
                completion(nil)
                return
            }
            let breathsPerMinute = averageQuantity.doubleValue(for: countUnit)
            DispatchQueue.main.async {
                completion(breathsPerMinute)
            }
        }
        healthStore.execute(query)
    }
    
    func calculateSleepScore(for summary: DailySleepSummary, config: SleepAnalysisConfig) -> (score: Int, verdict: String) {
        let totalAsleep = summary.totalSleepTime
        let totalInBed = totalAsleep + summary.awakeDuration
        
        guard totalAsleep > 0, totalInBed > 0 else {
            return (0, "No data")
        }
        
        var baseScore = 0
        
        let hoursAsleep = totalAsleep / 3600
        if hoursAsleep >= 7.0 && hoursAsleep <= 9.0 { baseScore += 40 }
        else if hoursAsleep >= 6.0 || hoursAsleep > 9.0 { baseScore += 25 }
        else { baseScore += 10 }
        
        let efficiency = totalAsleep / totalInBed
        if efficiency >= 0.90 { baseScore += 30 }
        else if efficiency >= 0.85 { baseScore += 20 }
        else { baseScore += 10 }
        
        if summary.deepDuration > 0 || summary.remDuration > 0 {
            let deepRatio = summary.deepDuration / totalAsleep
            let remRatio = summary.remDuration / totalAsleep
            if deepRatio >= 0.10 && deepRatio <= 0.25 { baseScore += 15 }
            if remRatio >= 0.20 && remRatio <= 0.30 { baseScore += 15 }
        } else {
            baseScore += 15
        }
        
        var penalties = 0
        
        if config.enablePenalties {
            let awakeSegments = summary.samples.filter { $0.value == HKCategoryValueSleepAnalysis.awake.rawValue && $0.endDate.timeIntervalSince($0.startDate) > 30 }
            if awakeSegments.count > 2 {
                penalties += min((awakeSegments.count - 2) * 4, 20)
            }
            
            let sleepSamples = summary.samples.filter { $0.value != HKCategoryValueSleepAnalysis.inBed.rawValue && $0.value != HKCategoryValueSleepAnalysis.awake.rawValue }
            if let firstSleep = sleepSamples.first {
                let hour = Calendar.current.component(.hour, from: firstSleep.startDate)
                if hour >= 1 && hour < 6 {
                    penalties += min((hour - 1) * 6 + 3, 24)
                }
            }
        }
        
        if config.enableHeartRateAnalysis, let realHR = summary.averageHeartRate {
            if realHR > 68.0 {
                penalties += 10
            } else if realHR > 62.0 {
                penalties += 4
            }
        }
        
        if config.enableRespiratoryRateAnalysis, let realRR = summary.averageRespiratoryRate {
            if realRR > 18.5 {
                penalties += 8
            } else if realRR < 11.5 {
                penalties += 5
            }
        }
        
        let finalScore = max(0, baseScore - penalties)
        
        var verdict = "Normal sleep"
        switch finalScore {
        case 85...100: verdict = "Great sleep! You're fully recovered."
        case 70..<85:  verdict = "Good sleep. The body is normal."
        case 50..<70:  verdict = "Mediocre sleep. Physiological stress or a disruption in biorhythms may have contributed."
        default:       verdict = "Poor sleep. Severe fragmentation or strain on the heart.."
        }
        
        return (finalScore, verdict)
    }
    
    func generateMockSleepData(for targetDate: Date) {
        #if targetEnvironment(simulator)
        guard HKHealthStore.isHealthDataAvailable() else {
            self.updateStatus("HealthKit unavailable")
            return
        }
        
        guard let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis),
              let heartRateType = HKObjectType.quantityType(forIdentifier: .heartRate),
              let respiratoryType = HKObjectType.quantityType(forIdentifier: .respiratoryRate) else {
            self.updateStatus("Failed to create HealthKit types")
            return
        }
        
        let typesToShare: Set<HKSampleType> = [sleepType, heartRateType, respiratoryType]
        let typesToRead: Set<HKObjectType> = [sleepType, heartRateType, respiratoryType]
        
        healthStore.requestAuthorization(toShare: typesToShare, read: typesToRead) { [weak self] success, error in
            guard let self = self else { return }
            
            if !success {
                self.updateStatus("Authorization error: \(error?.localizedDescription ?? "unknown")")
                return
            }
            
            let calendar = Calendar.current
            
            let randomMinuteOffset = Int.random(in: -30...30)
            let baseBedTime = calendar.date(bySettingHour: 23, minute: 0, second: 0, of: targetDate)!
            let timeInBedStart = calendar.date(byAdding: .minute, value: randomMinuteOffset, to: baseBedTime)!
            
            let timeAsleepStart = calendar.date(byAdding: .minute, value: Int.random(in: 15...25), to: timeInBedStart)!
            
            let totalSleepHours = Double.random(in: 5.0...9.0)
            let totalSleepSeconds = totalSleepHours * 3600
            let timeAsleepEnd = timeAsleepStart.addingTimeInterval(totalSleepSeconds)
            
            let timeInBedEnd = calendar.date(byAdding: .minute, value: Int.random(in: 10...15), to: timeAsleepEnd)!
            
            var objectsToSave: [HKSample] = []
            
            let inBedSample = HKCategorySample(
                type: sleepType,
                value: HKCategoryValueSleepAnalysis.inBed.rawValue,
                start: timeInBedStart,
                end: timeInBedEnd
            )
            objectsToSave.append(inBedSample)
            
            var currentPhaseStart = timeAsleepStart
            let sleepPhases: [HKCategoryValueSleepAnalysis] = [.asleepCore, .asleepCore, .asleepDeep, .asleepREM]
            
            while currentPhaseStart < timeAsleepEnd {
                let phaseDuration = TimeInterval(Int.random(in: 25...50) * 60)
                var currentPhaseEnd = currentPhaseStart.addingTimeInterval(phaseDuration)
                
                if currentPhaseEnd > timeAsleepEnd {
                    currentPhaseEnd = timeAsleepEnd
                }
                
                let randomPhase = sleepPhases.randomElement() ?? .asleepCore
                
                let phaseSample = HKCategorySample(
                    type: sleepType,
                    value: randomPhase.rawValue,
                    start: currentPhaseStart,
                    end: currentPhaseEnd
                )
                objectsToSave.append(phaseSample)
                
                if Bool.random() && currentPhaseEnd < timeAsleepEnd {
                    let awakeDuration = TimeInterval(Int.random(in: 2...6) * 60)
                    var awakeEnd = currentPhaseEnd.addingTimeInterval(awakeDuration)
                    
                    if awakeEnd > timeAsleepEnd { awakeEnd = timeAsleepEnd }
                    
                    let awakeSample = HKCategorySample(
                        type: sleepType,
                        value: HKCategoryValueSleepAnalysis.awake.rawValue,
                        start: currentPhaseEnd,
                        end: awakeEnd
                    )
                    objectsToSave.append(awakeSample)
                    
                    currentPhaseStart = awakeEnd
                } else {
                    currentPhaseStart = currentPhaseEnd
                }
            }
            
            let randomBPM = Double.random(in: 55.0...75.0)
            let heartRateUnit = HKUnit.count().unitDivided(by: HKUnit.minute())
            let heartRateQuantity = HKQuantity(unit: heartRateUnit, doubleValue: randomBPM)
            
            let heartRateSample = HKQuantitySample(
                type: heartRateType,
                quantity: heartRateQuantity,
                start: timeAsleepStart,
                end: timeAsleepEnd
            )
            objectsToSave.append(heartRateSample)
            
            let randomBreaths = Double.random(in: 12.0...19.0)
            let respiratoryUnit = HKUnit.count().unitDivided(by: HKUnit.minute())
            let respiratoryQuantity = HKQuantity(unit: respiratoryUnit, doubleValue: randomBreaths)
            
            let respiratorySample = HKQuantitySample(
                type: respiratoryType,
                quantity: respiratoryQuantity,
                start: timeAsleepStart,
                end: timeAsleepEnd
            )
            objectsToSave.append(respiratorySample)
            
            self.healthStore.save(objectsToSave) { success, error in
                if success {
                    let formatter = DateFormatter()
                    formatter.dateStyle = .short
                    let dateString = formatter.string(from: targetDate)
                    let hoursString = String(format: "%.1f", totalSleepHours)
                    self.updateStatus("🎉 Generated \(hoursString)h sleep, Pulse (\(Int(randomBPM)) bpm) & Breath (\(String(format: "%.1f", randomBreaths)) rr) for \(dateString)!")
                } else {
                    self.updateStatus("Saving error: \(error?.localizedDescription ?? "")")
                }
            }
        }
        #else
        updateStatus("Generation is only available in the Simulator.")
        #endif
    }
    
    func clearSleepData(for targetDate: Date) {
        #if targetEnvironment(simulator)
        guard let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else { return }
        
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: targetDate)
        guard let endOfNextDay = calendar.date(byAdding: .day, value: 2, to: startOfDay) else { return }
        
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: endOfNextDay, options: [.strictStartDate])
        
        healthStore.requestAuthorization(toShare: [sleepType], read: [sleepType]) { [weak self] success, error in
            guard let self = self else { return }
            
            if !success {
                self.updateStatus("Authorization error: \(error?.localizedDescription ?? "")")
                return
            }
            
            self.healthStore.deleteObjects(of: sleepType, predicate: predicate) { success, count, error in
                let formatter = DateFormatter()
                formatter.dateStyle = .short
                let dateString = formatter.string(from: targetDate)
                
                if success {
                    self.updateStatus("🗑 Deleted \(count) sleep records around \(dateString)!")
                } else {
                    self.updateStatus("Deletion error: \(error?.localizedDescription ?? "")")
                }
            }
        }
        #else
        updateStatus("Deletion is only available in the Simulator.")
        #endif
    }

    func fetchMonthlySleepData(from startDate: Date) {
        
        guard HKHealthStore.isHealthDataAvailable() else { return }
        
        guard let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis),
              let heartRateType = HKObjectType.quantityType(forIdentifier: .heartRate),
              let respiratoryRateType = HKObjectType.quantityType(forIdentifier: .respiratoryRate) else { return }
        
        let typesToRead: Set<HKObjectType> = [sleepType, heartRateType, respiratoryRateType]
        
        healthStore.requestAuthorization(toShare: [sleepType], read: typesToRead) { [weak self] success, error in
            guard let self = self else { return }
            
            if !success {
                self.updateStatus("Auth failed for fetching: \(error?.localizedDescription ?? "")")
                return
            }
            
            let calendar = Calendar.current
            let predicate = HKQuery.predicateForSamples(withStart: startDate, end: Date(), options: .strictStartDate)
            let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)
            
            let query = HKSampleQuery(sampleType: sleepType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: [sortDescriptor]) { _, samples, error in
                guard let categorySamples = samples as? [HKCategorySample] else { return }
                
                var newSummaries: [Date: DailySleepSummary] = [:]
                
                for sample in categorySamples {
                    if sample.value == HKCategoryValueSleepAnalysis.inBed.rawValue {
                        continue
                    }
                    
                    let endDate = sample.endDate
                    let hour = calendar.component(.hour, from: endDate)
                    
                    let targetDate: Date
                    if hour >= 18 {
                        targetDate = calendar.date(byAdding: .day, value: 1, to: endDate) ?? endDate
                    } else {
                        targetDate = endDate
                    }
                    
                    let startOfTargetDay = calendar.startOfDay(for: targetDate)
                    
                    var summary = newSummaries[startOfTargetDay] ?? DailySleepSummary(date: startOfTargetDay)
                    let duration = sample.endDate.timeIntervalSince(sample.startDate)
                    
                    switch sample.value {
                    case HKCategoryValueSleepAnalysis.asleepCore.rawValue:
                        summary.coreDuration += duration
                    case HKCategoryValueSleepAnalysis.asleepDeep.rawValue:
                        summary.deepDuration += duration
                    case HKCategoryValueSleepAnalysis.asleepREM.rawValue:
                        summary.remDuration += duration
                    case HKCategoryValueSleepAnalysis.awake.rawValue:
                        summary.awakeDuration += duration
                    case HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue:
                        summary.coreDuration += duration
                    default:
                        break
                    }
                    
                    let interval = SleepInterval(startDate: sample.startDate, endDate: sample.endDate, value: sample.value)
                    summary.samples.append(interval)
                    
                    newSummaries[startOfTargetDay] = summary
                }
                
                for (date, var summary) in newSummaries {
                    summary.samples.sort { $0.startDate < $1.startDate }
                    newSummaries[date] = summary
                }
                
                DispatchQueue.main.async {
                    self.monthlySleepData = newSummaries
                    self.statusMessage = "Synced with Apple Health"
                }
            }
            
            self.healthStore.execute(query)
        }
    }
    
    private func updateStatus(_ message: String) {
        DispatchQueue.main.async {
            self.statusMessage = message
        }
    }
}
