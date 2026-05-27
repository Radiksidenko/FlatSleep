//
//  SleepAnalysisConfig.swift
//  FlatSleep
//
//  Created by Radomyr Sidenko on 27.05.2026.
//

import Foundation

struct SleepAnalysisConfig {
    var enablePenalties: Bool
    var enableHeartRateAnalysis: Bool
    var enableRespiratoryRateAnalysis: Bool
    
    static var current: SleepAnalysisConfig {
        return SleepAnalysisConfig(
            enablePenalties: UserDefaults.standard.object(forKey: "enablePenalties") as? Bool ?? true,
            enableHeartRateAnalysis: UserDefaults.standard.bool(forKey: "enableHeartRateAnalysis"),
            enableRespiratoryRateAnalysis: UserDefaults.standard.bool(forKey: "enableRespiratoryRateAnalysis")
        )
    }
}
