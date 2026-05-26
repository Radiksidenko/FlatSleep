//
//  SleepDetailView.swift
//  FlatSleep
//
//  Created by Radomyr Sidenko on 26.05.2026.
//

import SwiftUI

struct SleepDetailView: View {
    let date: Date
    let summary: DailySleepSummary?
    
    private let formatter: DateFormatter = {
        let df = DateFormatter()
        df.dateStyle = .long
        return df
    }()
    
    var body: some View {
        List {
            if let summary = summary, summary.totalSleepTime > 0 {
                Section(header: Text("Total Time")) {
                    HStack {
                        Text("Total Sleep")
                        Spacer()
                        Text(formatTime(summary.totalSleepTime))
                            .bold()
                            .foregroundColor(.indigo)
                    }
                }
                
                Section(header: Text("Sleep Phases")) {
                    PhaseRow(title: "Awake", duration: summary.awakeDuration, total: summary.totalSleepTime, color: .orange)
                    PhaseRow(title: "Core", duration: summary.coreDuration, total: summary.totalSleepTime, color: .blue)
                    PhaseRow(title: "Deep", duration: summary.deepDuration, total: summary.totalSleepTime, color: .indigo)
                    PhaseRow(title: "REM", duration: summary.remDuration, total: summary.totalSleepTime, color: .purple)
                }
            } else {
                VStack(spacing: 15) {
                    Spacer()
                    Image(systemName: "bed.double")
                        .font(.system(size: 50))
                        .foregroundColor(.secondary)
                    Text("No sleep data recorded for this day.")
                        .foregroundColor(.secondary)
                        .font(.subheadline)
                    Spacer()
                }
                .frame(maxWidth: .infinity, minHeight: 200)
                .listRowBackground(Color.clear)
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle(formatter.string(from: date))
        .navigationBarTitleDisplayMode(.inline)
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

struct PhaseRow: View {
    let title: String
    let duration: TimeInterval
    let total: TimeInterval
    let color: Color
    
    var percentage: Double {
        total > 0 ? (duration / total) : 0
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(title)
                    .font(.body)
                Spacer()
                Text(formatTime(duration))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(color.opacity(0.15))
                        .frame(height: 8)
                    
                    Capsule()
                        .fill(color)
                        .frame(width: geo.size.width * CGFloat(percentage), height: 8)
                }
            }
            .frame(height: 8)
        }
        .padding(.vertical, 4)
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
