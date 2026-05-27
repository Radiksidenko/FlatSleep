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
    
    @StateObject private var manager = HealthKitManager()
    
    @AppStorage("enablePenalties") private var enablePenalties = false
    @AppStorage("enableHeartRateAnalysis") private var enableHeartRateAnalysis = false
    @AppStorage("enableRespiratoryRateAnalysis") private var enableRespiratoryRateAnalysis = false
    
    @AppStorage("selectedChartView") private var selectedChartView = "Timeline"
    
    @State private var realAverageHeartRate: Double? = nil
    @State private var realAverageRespiratoryRate: Double? = nil
    
    private let formatter: DateFormatter = {
        let df = DateFormatter()
        df.dateFormat = "d MMMM yyyy"
        return df
    }()
    
    private var scoreResult: (score: Int, verdict: String) {
        if var currentSummary = summary {
            currentSummary.averageHeartRate = realAverageHeartRate
            currentSummary.averageRespiratoryRate = realAverageRespiratoryRate
            return manager.calculateSleepScore(for: currentSummary, config: SleepAnalysisConfig.current)
        }
        return (0, "")
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                
                if let summary = summary, summary.totalSleepTime > 0 {
                    
                    SleepScoreCircleView(score: scoreResult.score, verdict: scoreResult.verdict)
                        .padding(.horizontal)
                    
                    SleepDurationMetricsView(
                        totalSleepTime: summary.totalSleepTime,
                        awakeDuration: summary.awakeDuration
                    )
                    .padding(.horizontal)
                    
                    if selectedChartView == "Timeline" {
                        SleepLinearTimelineView(samples: summary.samples)
                            .padding(.horizontal)
                    } else {
                        SleepHypnogramView(samples: summary.samples)
                            .padding(.horizontal)
                    }
                    
                    VStack(spacing: 0) {
                        Text("SLEEP STAGES & METRICS")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .bold()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 4)
                            .padding(.bottom, 8)
                        
                        VStack(spacing: 12) {
                            DetailedPhaseRow(title: "Awake", duration: summary.awakeDuration, color: .orange)
                            Divider()
                            DetailedPhaseRow(title: "REM (Быстрый)", duration: summary.remDuration, color: .purple)
                            Divider()
                            DetailedPhaseRow(title: "Core (Базовый)", duration: summary.coreDuration, color: .blue)
                            Divider()
                            DetailedPhaseRow(title: "Deep (Глубокий)", duration: summary.deepDuration, color: .indigo)
                            
                            if enableHeartRateAnalysis {
                                Divider()
                                if let hr = realAverageHeartRate {
                                    DetailedPhaseRow(title: "Pulse (Average)", duration: nil, customValue: "\(Int(hr)) beats/min", color: .red)
                                } else {
                                    DetailedPhaseRow(title: "Pulse (Average)", duration: nil, customValue: "No data", color: .gray)
                                }
                            }
                            
                            if enableRespiratoryRateAnalysis {
                                Divider()
                                if let rr = realAverageRespiratoryRate {
                                    DetailedPhaseRow(title: "Respiratory rate", duration: nil, customValue: String(format: "%.1f in/min", rr), color: .cyan)
                                } else {
                                    DetailedPhaseRow(title: "Respiratory rate", duration: nil, customValue: "No data", color: .gray)
                                }
                            }
                        }
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(12)
                    }
                    .padding(.horizontal)
                    
                } else {
                    VStack(spacing: 15) {
                        Spacer(minLength: 50)
                        Image(systemName: "moon.stars.fill")
                            .font(.system(size: 64))
                            .foregroundColor(.secondary.opacity(0.5))
                        Text("No Sleep Data")
                            .font(.headline)
                        Spacer()
                    }
                }
            }
            .padding(.top, 10)
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .navigationTitle(formatter.string(from: date))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                NavigationLink(destination: SleepSettingsView()) {
                    Image(systemName: "gearshape")
                        .font(.body)
                }
            }
        }
        .onAppear {
            loadHealthMetricsIfNeeded()
        }
        .onChange(of: AnalysisFlags(enableHeartRateAnalysis, enableRespiratoryRateAnalysis, enablePenalties)) {
            if enableHeartRateAnalysis || enableRespiratoryRateAnalysis || enablePenalties {
                loadHealthMetricsIfNeeded()
            }
        }
    }
    
    private func loadHealthMetricsIfNeeded() {
        guard let samples = summary?.samples, !samples.isEmpty else { return }
        
        let startSleep = samples.map { $0.startDate }.min() ?? date
        let endSleep = samples.map { $0.endDate }.max() ?? date
        
        if enableHeartRateAnalysis && realAverageHeartRate == nil {
            manager.fetchAverageHeartRate(from: startSleep, to: endSleep) { avgHR in
                self.realAverageHeartRate = avgHR
            }
        }
        
        if enableRespiratoryRateAnalysis && realAverageRespiratoryRate == nil {
            manager.fetchAverageRespiratoryRate(from: startSleep, to: endSleep) { avgRR in
                self.realAverageRespiratoryRate = avgRR
            }
        }
    }
}
