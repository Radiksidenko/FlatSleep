//
//  SleepDurationMetricsView.swift
//  FlatSleep
//
//  Created by Radomyr Sidenko on 27.05.2026.
//

import SwiftUI

struct SleepDurationMetricsView: View {
    let totalSleepTime: TimeInterval
    let awakeDuration: TimeInterval
    
    var body: some View {
        HStack(spacing: 20) {
            VStack(alignment: .leading, spacing: 4) {
                Text("TIME IN BED")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .bold()
                
                let totalInBed = totalSleepTime + awakeDuration
                Text(formatTimeInHoursAndMinutes(totalInBed))
                    .font(.title3)
                    .bold()
                    .foregroundColor(.primary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("TIME ASLEEP")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .bold()
                
                Text(formatTimeInHoursAndMinutes(totalSleepTime))
                    .font(.title3)
                    .bold()
                    .foregroundColor(.indigo)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
    
    private func formatTimeInHoursAndMinutes(_ interval: TimeInterval) -> String {
        let hours = Int(interval) / 3600
        let minutes = (Int(interval) % 3600) / 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}
