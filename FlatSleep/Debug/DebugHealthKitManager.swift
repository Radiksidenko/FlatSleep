//
//  DebugHealthKitManager.swift
//  FlatSleep
//
//  Created by Radomyr Sidenko on 26.05.2026.
//

import Foundation
import HealthKit

class DebugHealthKitManager: ObservableObject {
    let healthStore = HKHealthStore()
    
    @Published var statusMessage: String = "Ready to generate"
    
    func generateMockSleepData() {
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
            let now = Date()
            guard let yesterday = calendar.date(byAdding: .day, value: -1, to: now) else { return }
            
            let timeInBedStart = calendar.date(bySettingHour: 23, minute: 0, second: 0, of: yesterday)!
            let timeAsleepStart = calendar.date(bySettingHour: 23, minute: 30, second: 0, of: yesterday)!
            let timeAsleepEnd = calendar.date(bySettingHour: 7, minute: 0, second: 0, of: now)!
            let timeInBedEnd = calendar.date(bySettingHour: 7, minute: 15, second: 0, of: now)!
            
            let inBedSample = HKCategorySample(
                type: sleepType,
                value: HKCategoryValueSleepAnalysis.inBed.rawValue,
                start: timeInBedStart,
                end: timeInBedEnd
            )
            
            let asleepSample = HKCategorySample(
                type: sleepType,
                value: HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue,
                start: timeAsleepStart,
                end: timeAsleepEnd
            )
            
            // Сохранение
            self.healthStore.save([inBedSample, asleepSample]) { success, error in
                if success {
                    self.updateStatus("🎉 The dream has been successfully added to the Simulator.!")
                } else {
                    self.updateStatus("Saving error: \(error?.localizedDescription ?? "")")
                }
            }
        }
        #else
        updateStatus("Generation is only available in the Simulator.")
        #endif
    }
    
    private func updateStatus(_ message: String) {
        DispatchQueue.main.async {
            self.statusMessage = message
        }
    }
}
