//
//  DetailedPhaseRow.swift
//  FlatSleep
//
//  Created by Radomyr Sidenko on 27.05.2026.
//
import SwiftUI

struct DetailedPhaseRow: View {
    let title: String
    let duration: TimeInterval?
    var customValue: String? = nil
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(color)
                .frame(width: 12, height: 12)
            
            Text(title)
                .font(.body)
                .foregroundColor(.primary)
            
            Spacer()
            
            if let customValue = customValue {
                Text(customValue)
                    .font(.body)
                    .bold()
                    .foregroundColor(.secondary)
            } else if let duration = duration {
                Text(formatTime(duration))
                    .font(.body)
                    .bold()
                    .foregroundColor(.secondary)
            }
        }
    }
    
    private func formatTime(_ interval: TimeInterval) -> String {
        let hours = Int(interval) / 3600
        let minutes = (Int(interval) % 3600) / 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}
