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
    
    @State private var isScrubbing: Bool = false
    @State private var touchX: CGFloat = 0.0
    @State private var activeSample: SleepInterval? = nil
    @State private var activeTime: Date? = nil
    
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
        VStack(alignment: .leading, spacing: 10) {
            
            HStack {
                Text("SLEEP STRUCTURE")
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
                            
                            VStack(spacing: 0) {
                                ForEach(0..<4) { i in
                                    Divider()
                                        .opacity(0.4)
                                    if i < 3 { Spacer() }
                                }
                            }
                            
                            Path { path in
                                guard totalTimelineDuration > 0 else { return }
                                var lastX: CGFloat = 0
                                var lastY: CGFloat = 0
                                
                                for (index, sample) in samples.enumerated() {
                                    let startOffset = sample.startDate.timeIntervalSince(firstStart)
                                    let endOffset = sample.endDate.timeIntervalSince(firstStart)
                                    
                                    let xStart = CGFloat(startOffset / totalTimelineDuration) * geo.size.width
                                    let xEnd = CGFloat(endOffset / totalTimelineDuration) * geo.size.width
                                    let yLevel = level(for: sample.value) * geo.size.height
                                    
                                    if index == 0 {
                                        path.move(to: CGPoint(x: xStart, y: yLevel))
                                    } else {
                                        let controlPointX1 = lastX + (xStart - lastX) * 0.5
                                        let controlPointX2 = lastX + (xStart - lastX) * 0.5
                                        
                                        path.addCurve(
                                            to: CGPoint(x: xStart, y: yLevel),
                                            control1: CGPoint(x: controlPointX1, y: lastY),
                                            control2: CGPoint(x: controlPointX2, y: yLevel)
                                        )
                                    }
                                    
                                    path.addLine(to: CGPoint(x: xEnd, y: yLevel))
                                    
                                    lastX = xEnd
                                    lastY = yLevel
                                }
                            }
                            .stroke(
                                LinearGradient(
                                    colors: [.orange.opacity(0.8), .purple.opacity(0.8), .blue.opacity(0.8), .indigo.opacity(0.8)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                ),
                                style: StrokeStyle(lineWidth: 3.5, lineCap: .round, lineJoin: .round)
                            )
                            
                            ForEach(samples) { sample in
                                let startOffset = sample.startDate.timeIntervalSince(firstStart)
                                let endOffset = sample.endDate.timeIntervalSince(firstStart)
                                
                                let xStart = CGFloat(startOffset / totalTimelineDuration) * geo.size.width
                                let xEnd = CGFloat(endOffset / totalTimelineDuration) * geo.size.width
                                let width = max(6, xEnd - xStart)
                                let yLevel = level(for: sample.value) * geo.size.height
                                
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(color(for: sample.value))
                                    .frame(width: width, height: 10)
                                    .position(x: xStart + (width / 2), y: yLevel)
                            }
                            
                            if isScrubbing, let sample = activeSample {
                                let currentY = level(for: sample.value) * geo.size.height
                                
                                RoundedRectangle(cornerRadius: 1)
                                    .fill(Color.white.opacity(0.4))
                                    .frame(width: 1.5, height: geo.size.height)
                                    .offset(x: touchX - 0.75)
                                
                                Circle()
                                    .fill(Color.white)
                                    .frame(width: 14, height: 14)
                                    .shadow(color: color(for: sample.value).opacity(0.8), radius: 4)
                                    .overlay(
                                        Circle()
                                            .stroke(color(for: sample.value), lineWidth: 3)
                                    )
                                    .position(x: touchX, y: currentY)
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
                    .frame(height: 140)
                    .padding(.vertical, 10)
                    
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
