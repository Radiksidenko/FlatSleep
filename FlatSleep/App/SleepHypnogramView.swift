//
//  SleepHypnogramView.swift
//  FlatSleep
//
//  Created by Radomyr Sidenko on 26.05.2026.
//

import SwiftUI
import HealthKit

struct SleepHypnogramView: View {
    let samples: [SleepInterval]
    
    private func level(for value: Int) -> CGFloat {
        switch value {
        case HKCategoryValueSleepAnalysis.awake.rawValue:
            return 0.0
        case HKCategoryValueSleepAnalysis.asleepREM.rawValue:
            return 0.33
        case HKCategoryValueSleepAnalysis.asleepCore.rawValue, HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue:
            return 0.66
        case HKCategoryValueSleepAnalysis.asleepDeep.rawValue:
            return 1.0
        default:
            return 0.66
        }
    }
    
    private func color(for value: Int) -> Color {
        switch value {
        case HKCategoryValueSleepAnalysis.awake.rawValue: return .orange
        case HKCategoryValueSleepAnalysis.asleepREM.rawValue: return .purple
        case HKCategoryValueSleepAnalysis.asleepCore.rawValue, HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue: return .blue
        case HKCategoryValueSleepAnalysis.asleepDeep.rawValue: return .indigo
        default: return .blue
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("SLEEP STRUCTURE")
                .font(.caption)
                .foregroundColor(.secondary)
                .bold()
            
            if samples.isEmpty {
                Text("No timeline data available")
                    .font(.footnote)
                    .foregroundColor(.secondary)
            } else {
                let firstStart = samples.first?.startDate ?? Date()
                let lastEnd = samples.last?.endDate ?? Date()
                let totalTimelineDuration = lastEnd.timeIntervalSince(firstStart)
                
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        VStack(spacing: 0) {
                            ForEach(0..<4) { i in
                                Divider()
                                if i < 3 { Spacer() }
                            }
                        }
                        
                        Path { path in
                            guard totalTimelineDuration > 0 else { return }
                            
                            for (index, sample) in samples.enumerated() {
                                let startOffset = sample.startDate.timeIntervalSince(firstStart)
                                let endOffset = sample.endDate.timeIntervalSince(firstStart)
                                
                                let xStart = CGFloat(startOffset / totalTimelineDuration) * geo.size.width
                                let xEnd = CGFloat(endOffset / totalTimelineDuration) * geo.size.width
                                
                                let yLevel = level(for: sample.value) * geo.size.height
                                
                                if index == 0 {
                                    path.move(to: CGPoint(x: xStart, y: yLevel))
                                } else {
                                    path.addLine(to: CGPoint(x: xStart, y: yLevel))
                                }
                                
                                path.addLine(to: CGPoint(x: xEnd, y: yLevel))
                            }
                        }
                        .stroke(
                            LinearGradient(colors: [.orange, .purple, .blue, .indigo], startPoint: .top, endPoint: .bottom),
                            style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round)
                        )
                        
                        ForEach(samples) { sample in
                            let startOffset = sample.startDate.timeIntervalSince(firstStart)
                            let endOffset = sample.endDate.timeIntervalSince(firstStart)
                            
                            let xStart = CGFloat(startOffset / totalTimelineDuration) * geo.size.width
                            let xEnd = CGFloat(endOffset / totalTimelineDuration) * geo.size.width
                            let width = max(4, xEnd - xStart)
                            
                            let yLevel = level(for: sample.value) * geo.size.height
                            
                            RoundedRectangle(cornerRadius: 3)
                                .fill(color(for: sample.value).opacity(0.8))
                                .frame(width: width, height: 14)
                                .position(x: xStart + (width / 2), y: yLevel)
                        }
                    }
                }
                .frame(height: 150)
                .padding(.vertical, 5)
                
                HStack {
                    Text(formatShortTime(firstStart))
                    Spacer()
                    Text(formatShortTime(lastEnd))
                }
                .font(.caption2)
                .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
    
    private func formatShortTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
}
