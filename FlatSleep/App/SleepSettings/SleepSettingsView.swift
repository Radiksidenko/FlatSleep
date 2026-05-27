//
//  SleepSettingsView.swift
//  FlatSleep
//
//  Created by Radomyr Sidenko on 27.05.2026.
//

import SwiftUI

struct SleepSettingsView: View {
    @AppStorage("enablePenalties") private var enablePenalties = true
    @AppStorage("enableHeartRateAnalysis") private var enableHeartRateAnalysis = false
    @AppStorage("enableRespiratoryRateAnalysis") private var enableRespiratoryRateAnalysis = false
    @AppStorage("selectedChartView") private var selectedChartView = "Timeline"
    
    private var mockSamples: [SleepInterval] {
        let base = Date()
        return [
            SleepInterval(startDate: base, endDate: base.addingTimeInterval(2400), value: 0),
            SleepInterval(startDate: base.addingTimeInterval(2400), endDate: base.addingTimeInterval(7200), value: 1),
            SleepInterval(startDate: base.addingTimeInterval(7200), endDate: base.addingTimeInterval(10800), value: 2),
            SleepInterval(startDate: base.addingTimeInterval(10800), endDate: base.addingTimeInterval(13000), value: 3),
            SleepInterval(startDate: base.addingTimeInterval(13000), endDate: base.addingTimeInterval(16000), value: 1)
        ]
    }
    
    var body: some View {
        Form {
            Section(header: Text("Sleep chart style")) {
                VStack(spacing: 16) {
                    
                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selectedChartView = "Timeline"
                        }
                    }) {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Label("Linear timeline", systemImage: "chart.bar.fill")
                                    .font(.headline)
                                Spacer()
                                Image(systemName: selectedChartView == "Timeline" ? "checkmark.circle.fill" : "circle")
                                    .font(.title3)
                                    .foregroundColor(selectedChartView == "Timeline" ? .indigo : .secondary)
                            }
                            .foregroundColor(.primary)
                            
                            TimelinePreviewContainer(samples: mockSamples)
                        }
                        .padding()
                        .background(Color(.secondarySystemGroupedBackground))
                        .cornerRadius(14)
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(selectedChartView == "Timeline" ? Color.indigo : Color.clear, lineWidth: 2)
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selectedChartView = "Hypnogram"
                        }
                    }) {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Label("Hypnogram", systemImage: "waveform.path")
                                    .font(.headline)
                                Spacer()
                                Image(systemName: selectedChartView == "Hypnogram" ? "checkmark.circle.fill" : "circle")
                                    .font(.title3)
                                    .foregroundColor(selectedChartView == "Hypnogram" ? .indigo : .secondary)
                            }
                            .foregroundColor(.primary)
                            
                            HypnogramPreviewContainer(samples: mockSamples)
                        }
                        .padding()
                        .background(Color(.secondarySystemGroupedBackground))
                        .cornerRadius(14)
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(selectedChartView == "Hypnogram" ? Color.indigo : Color.clear, lineWidth: 2)
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                }
                .padding(.vertical, 8)
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets())
            }
            
            Section(header: Text("Sleep Score calculation algorithm")) {
                Toggle(isOn: $enablePenalties) {
                    Label("Fines for awakenings and biorhythms", systemImage: "clock.badge.exclamationmark")
                }
            }
            
            Section(header: Text("Advanced health metrics")) {
                Toggle(isOn: $enableHeartRateAnalysis) {
                    Label("Pulse rate (HR) analysis", systemImage: "heart.text.square")
                }
                
                Toggle(isOn: $enableRespiratoryRateAnalysis) {
                    Label("Breathing rate analysis (RR)", systemImage: "waveform.path.ecg")
                }
            }
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct TimelinePreviewContainer: View {
    let samples: [SleepInterval]
    
    var body: some View {
        VStack {
            SleepLinearTimelineView(samples: samples)
                .frame(height: 70)
                .disabled(true)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(Color(.systemGroupedBackground))
        .cornerRadius(8)
    }
}

struct HypnogramPreviewContainer: View {
    let samples: [SleepInterval]
    
    var body: some View {
        VStack {
            SleepHypnogramView(samples: samples)
                .frame(height: 120)
                .disabled(true)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(Color(.systemGroupedBackground))
        .cornerRadius(8)
    }
}
