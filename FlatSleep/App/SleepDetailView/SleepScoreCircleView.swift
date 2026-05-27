//
//  SleepScoreCircleView.swift
//  FlatSleep
//
//  Created by Radomyr Sidenko on 27.05.2026.
//

import SwiftUI

struct SleepScoreCircleView: View {
    let score: Int
    let verdict: String
    
    private var scoreColor: Color {
        switch score {
        case 85...100: return .green
        case 70..<85:  return .orange
        default:       return .red
        }
    }
    
    var body: some View {
        VStack(spacing: 14) {
            ZStack {
                Circle()
                    .stroke(Color(.label).opacity(0.1), lineWidth: 12)
                    .frame(width: 120, height: 120)
                
                Circle()
                    .trim(from: 0.0, to: CGFloat(score) / 100.0)
                    .stroke(scoreColor, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                    .frame(width: 120, height: 120)
                    .rotationEffect(Angle(degrees: -90))
                    .animation(.spring(), value: score)
                
                VStack {
                    Text("\(score)")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                    Text("points")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.top, 10)
            
            Text(verdict)
                .font(.subheadline)
                .fontWeight(.medium)
                .multilineTextAlignment(.center)
                .foregroundColor(.primary)
                .padding(.horizontal, 20)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(16)
    }
}
