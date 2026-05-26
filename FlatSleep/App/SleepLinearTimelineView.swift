//
//  SleepLinearTimelineView.swift
//  FlatSleep
//
//  Created by Radomyr Sidenko on 26.05.2026.
//

import SwiftUI
import HealthKit

struct SleepLinearTimelineView: View {
    let samples: [SleepInterval]
    
    @State private var isScrubbing: Bool = false
    @State private var touchX: CGFloat = 0.0
    @State private var activeSample: SleepInterval? = nil
    @State private var activeTime: Date? = nil
    
    private func color(for value: Int) -> Color {
        switch value {
        case HKCategoryValueSleepAnalysis.awake.rawValue: return .orange
        case HKCategoryValueSleepAnalysis.asleepREM.rawValue: return .purple
        case HKCategoryValueSleepAnalysis.asleepCore.rawValue, HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue: return .blue
        case HKCategoryValueSleepAnalysis.asleepDeep.rawValue: return .indigo
        default: return .blue
        }
    }
    
    private func stageName(for value: Int) -> String {
        switch value {
        case HKCategoryValueSleepAnalysis.awake.rawValue: return "Awake"
        case HKCategoryValueSleepAnalysis.asleepREM.rawValue: return "REM"
        case HKCategoryValueSleepAnalysis.asleepCore.rawValue, HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue: return "Core"
        case HKCategoryValueSleepAnalysis.asleepDeep.rawValue: return "Deep"
        default: return "Unknown"
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            
            HStack {
                Text("SLEEP TIMELINE")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .bold()
                
                Spacer()
                
                if isScrubbing, let sample = activeSample, let time = activeTime {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(color(for: sample.value))
                            .frame(width: 8, height: 8)
                        Text("\(stageName(for: sample.value)) at \(formatShortTime(time))")
                            .font(.caption)
                            .bold()
                            .foregroundColor(.primary)
                    }
                    .transition(.opacity.combined(with: .scale))
                }
            }
            .frame(height: 18)
            
            if samples.isEmpty {
                Text("No timeline data available")
                    .font(.footnote)
                    .foregroundColor(.secondary)
            } else {
                let firstStart = samples.first?.startDate ?? Date()
                let lastEnd = samples.last?.endDate ?? Date()
                let totalTimelineDuration = lastEnd.timeIntervalSince(firstStart)
                
                VStack(spacing: 8) {
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            
                            HStack(spacing: 0) {
                                ForEach(samples) { sample in
                                    let duration = sample.endDate.timeIntervalSince(sample.startDate)
                                    let relativeWidth = totalTimelineDuration > 0 ? CGFloat(duration / totalTimelineDuration) * geo.size.width : 0
                                    
                                    Rectangle()
                                        .fill(color(for: sample.value))
                                        .frame(width: max(1.5, relativeWidth))
                                }
                            }
                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                            
                            if isScrubbing {
                                RoundedRectangle(cornerRadius: 1)
                                    .fill(Color.white)
                                    .shadow(color: .black.opacity(0.4), radius: 2)
                                    .frame(width: 3, height: geo.size.height + 6)
                                    .offset(x: touchX - 1.5, y: -3)
                            }
                        }
                        .contentShape(Rectangle())
                        .gesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged { value in
                                    isScrubbing = true
                                    
                                    let x = max(0, min(value.location.x, geo.size.width))
                                    self.touchX = x
                                    
                                    let percentage = x / geo.size.width
                                    let secondsFromStart = totalTimelineDuration * Double(percentage)
                                    let calculatedTime = firstStart.addingTimeInterval(secondsFromStart)
                                    self.activeTime = calculatedTime
                                    
                                    if let matchingSample = samples.first(where: { calculatedTime >= $0.startDate && calculatedTime <= $0.endDate }) {
                                        self.activeSample = matchingSample
                                    }
                                }
                                .onEnded { _ in
                                    withAnimation(.easeOut(duration: 0.2)) {
                                        isScrubbing = false
                                        activeSample = nil
                                        activeTime = nil
                                    }
                                }
                        )
                    }
                    .frame(height: 32)
                    
                    HStack {
                        Text(formatShortTime(firstStart))
                        Spacer()
                        Text(formatShortTime(lastEnd))
                    }
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .bold()
                }
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
