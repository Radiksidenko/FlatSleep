//
//  DebugSleepView.swift
//  FlatSleep
//
//  Created by Radomyr Sidenko on 26.05.2026.
//

import SwiftUI

struct DebugSleepView: View {
    @StateObject private var hkManager = DebugHealthKitManager()
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "moon.stars.fill")
                .font(.system(size: 60))
                .foregroundColor(.indigo)
                .padding(.top, 40)
            
            Text("HealthKit Simulator Tool")
                .font(.title2)
                .bold()
            
            Text("Click the button below to generate 7.5 hours of sleep for last night (11:00 PM - 7:15 AM).")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Spacer()
            
            Text(hkManager.statusMessage)
                .font(.footnote)
                .foregroundColor(.indigo)
                .bold()
                .multilineTextAlignment(.center)
                .padding()
                .background(Color.indigo.opacity(0.1))
                .cornerRadius(10)
            
            Button(action: {
                hkManager.generateMockSleepData()
            }) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("Upload sleep data")
                        .bold()
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.indigo)
                .cornerRadius(12)
                .shadow(radius: 4)
            }
            .padding(.horizontal, 30)
            .padding(.bottom, 40)
        }
    }
}
