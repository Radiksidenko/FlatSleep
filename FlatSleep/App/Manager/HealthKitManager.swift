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
    
    func generateMockSleepData(for targetDate: Date) {
        #if targetEnvironment(simulator)
        guard HKHealthStore.isHealthDataAvailable() else {
            self.updateStatus("HealthKit unavailable")
            return
        }
        
        guard let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else {
            self.updateStatus("Failed to create type SleepAnalysis")
            return
        }
        
        healthStore.requestAuthorization(toShare: [sleepType], read: [sleepType]) { [weak self] success, error in
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
            
            var samples: [HKCategorySample] = []
            
            let inBedSample = HKCategorySample(
                type: sleepType,
                value: HKCategoryValueSleepAnalysis.inBed.rawValue,
                start: timeInBedStart,
                end: timeInBedEnd
            )
            samples.append(inBedSample)
            
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
                samples.append(phaseSample)
                
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
                    samples.append(awakeSample)
                    
                    currentPhaseStart = awakeEnd
                } else {
                    currentPhaseStart = currentPhaseEnd
                }
            }
            
            self.healthStore.save(samples) { success, error in
                if success {
                    let formatter = DateFormatter()
                    formatter.dateStyle = .short
                    let dateString = formatter.string(from: targetDate)
                    let hoursString = String(format: "%.1f", totalSleepHours)
                    self.updateStatus("🎉 Generated \(hoursString)h of sleep (with Awakes) for \(dateString)!")
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
    
    @Published var monthlySleepData: [Date: DailySleepSummary] = [:]

    func fetchMonthlySleepData(from startDate: Date) {
        
        guard HKHealthStore.isHealthDataAvailable() else { return }
        
        guard let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else { return }
        
        healthStore.requestAuthorization(toShare: [sleepType], read: [sleepType]) { [weak self] success, error in
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
