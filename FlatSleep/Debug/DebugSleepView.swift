//
//  DebugSleepView.swift
//  FlatSleep
//
//  Created by Radomyr Sidenko on 26.05.2026.
//

import SwiftUI

struct DebugSleepView: View {
    @StateObject private var hkManager = DebugHealthKitManager()
    @State private var selectedDate: Date = Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date()
    
    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 20) {
                
                HStack(spacing: 15) {
                    Image(systemName: "calendar.badge.plus")
                        .font(.system(size: 36))
                        .foregroundColor(.indigo)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("HealthKit Simulator Tool")
                            .font(.title3)
                            .bold()
                        Text("Generate phased sleep or wipe data clean")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.top, 15)
                
                Divider()
                    .padding(.horizontal)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Date of sleep:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .bold()
                        .padding(.horizontal, 5)
                    
                    DatePicker(
                        "Select a day",
                        selection: $selectedDate,
                        in: ...Date(),
                        displayedComponents: [.date]
                    )
                    .datePickerStyle(.graphical)
                    .accentColor(.indigo)
                    .padding(10)
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 3)
                }
                .padding(.horizontal, 16)
                
                HStack {
                    Text(hkManager.statusMessage)
                        .font(.footnote)
                        .foregroundColor(.indigo)
                        .bold()
                        .lineLimit(2)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .padding(.horizontal, 15)
                .background(Color.indigo.opacity(0.08))
                .cornerRadius(10)
                .padding(.horizontal, 16)
                .id(hkManager.statusMessage)
                
                VStack(spacing: 12) {
                    Button(action: {
                        hkManager.generateMockSleepData(for: selectedDate)
                    }) {
                        HStack {
                            Image(systemName: "bed.double.fill")
                            Text("Generate Phased Sleep")
                                .bold()
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.indigo)
                        .cornerRadius(12)
                        .shadow(color: Color.indigo.opacity(0.2), radius: 4, x: 0, y: 2)
                    }
                    
                    Button(action: {
                        hkManager.clearSleepData(for: selectedDate)
                    }) {
                        HStack {
                            Image(systemName: "trash.fill")
                            Text("Clear Data for Selected Day")
                                .bold()
                        }
                        .foregroundColor(.red)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.red.opacity(0.06))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.red.opacity(0.8), lineWidth: 1)
                        )
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 20)
                
            }
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
    }
}
