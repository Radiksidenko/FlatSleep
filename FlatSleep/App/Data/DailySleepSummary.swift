//
//  DailySleepSummary.swift
//  FlatSleep
//
//  Created by Radomyr Sidenko on 26.05.2026.
//

import Foundation

struct SleepInterval: Identifiable {
    let id = UUID()
    let startDate: Date
    let endDate: Date
    let value: Int
}

struct DailySleepSummary {
    let date: Date
    var coreDuration: TimeInterval = 0
    var deepDuration: TimeInterval = 0
    var remDuration: TimeInterval = 0
    var awakeDuration: TimeInterval = 0
    
    var samples: [SleepInterval] = []
    
    var totalSleepTime: TimeInterval {
        return coreDuration + deepDuration + remDuration
    }
}
