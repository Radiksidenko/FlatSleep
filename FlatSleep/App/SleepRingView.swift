//
//  SleepRingView.swift
//  FlatSleep
//
//  Created by Radomyr Sidenko on 26.05.2026.
//

import SwiftUI

struct SleepRingView: View {
    let summary: DailySleepSummary?
    var size: CGFloat = 40
    
    private let lineWidth: CGFloat = 3
    private let ringSpacing: CGFloat = 4.5
    
    var body: some View {
        ZStack {
            Group {
                Circle().stroke(Color.gray.opacity(0.08), lineWidth: lineWidth)
                    .frame(width: size)
                Circle().stroke(Color.gray.opacity(0.08), lineWidth: lineWidth)
                    .frame(width: size - (ringSpacing * 2))
                Circle().stroke(Color.gray.opacity(0.08), lineWidth: lineWidth)
                    .frame(width: size - (ringSpacing * 4))
                Circle().stroke(Color.gray.opacity(0.08), lineWidth: lineWidth)
                    .frame(width: size - (ringSpacing * 6))
            }
            
            if let summary = summary, summary.totalSleepTime > 0 {
                let target: TimeInterval = 8 * 3600
                
                Circle()
                    .trim(from: 0, to: min(summary.awakeDuration / target, 1.0))
                    .stroke(Color.orange, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                    .frame(width: size)
                    .rotationEffect(.degrees(-90))
                
                Circle()
                    .trim(from: 0, to: min(summary.coreDuration / target, 1.0))
                    .stroke(Color.blue, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                    .frame(width: size - (ringSpacing * 2))
                    .rotationEffect(.degrees(-90))
                
                Circle()
                    .trim(from: 0, to: min(summary.deepDuration / target, 1.0))
                    .stroke(Color.indigo, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                    .frame(width: size - (ringSpacing * 4))
                    .rotationEffect(.degrees(-90))
                
                Circle()
                    .trim(from: 0, to: min(summary.remDuration / target, 1.0))
                    .stroke(Color.purple, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                    .frame(width: size - (ringSpacing * 6))
                    .rotationEffect(.degrees(-90))
            }
        }
        .padding(lineWidth / 2)
    }
}
