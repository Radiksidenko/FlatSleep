//
//  SleepDetailView.swift
//  FlatSleep
//
//  Created by Radomyr Sidenko on 26.05.2026.
//

import SwiftUI

struct SleepDetailView: View {
    let initialDate: Date
    
    @StateObject private var manager = HealthKitManager()
    
    @State private var selectedDate: Date
    
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
    
    init(date: Date, summary: DailySleepSummary?) {
        self.initialDate = date
        self._selectedDate = State(initialValue: Calendar.current.startOfDay(for: date))
    }
    
    private var swipeableDates: [Date] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: initialDate)
        return (-15...15).compactMap { dayOffset in
            calendar.date(byAdding: .day, value: dayOffset, to: startOfDay)
        }
    }
    
    private func summary(for date: Date) -> DailySleepSummary? {
        let startOfDay = Calendar.current.startOfDay(for: date)
        return manager.monthlySleepData[startOfDay]
    }
    
    var body: some View {
        TabView(selection: $selectedDate) {
            ForEach(swipeableDates, id: \.self) { day in
                SleepDayDetailContent(
                    summary: summary(for: day),
                    selectedChartView: selectedChartView,
                    enableHeartRateAnalysis: enableHeartRateAnalysis,
                    enableRespiratoryRateAnalysis: enableRespiratoryRateAnalysis,
                    realAverageHeartRate: realAverageHeartRate,
                    realAverageRespiratoryRate: realAverageRespiratoryRate,
                    manager: manager
                )
                .tag(day)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .navigationTitle(formatter.string(from: selectedDate))
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
            let calendar = Calendar.current
            if let oneMonthAgo = calendar.date(byAdding: .month, value: -1, to: initialDate) {
                manager.fetchMonthlySleepData(from: oneMonthAgo)
            }
            loadHealthMetricsForCurrentDate()
        }
        .onChange(of: manager.monthlySleepData) { _, _ in
            loadHealthMetricsForCurrentDate()
        }
        .onChange(of: selectedDate) { _, _ in
            realAverageHeartRate = nil
            realAverageRespiratoryRate = nil
            loadHealthMetricsForCurrentDate()
        }
        .onChange(of: AnalysisFlags(enableHeartRateAnalysis, enableRespiratoryRateAnalysis, enablePenalties)) {
            if enableHeartRateAnalysis || enableRespiratoryRateAnalysis || enablePenalties {
                loadHealthMetricsForCurrentDate()
            }
        }
    }
    
    private func loadHealthMetricsForCurrentDate() {
        guard let currentSummary = summary(for: selectedDate), !currentSummary.samples.isEmpty else { return }
        
        let startSleep = currentSummary.samples.map { $0.startDate }.min() ?? selectedDate
        let endSleep = currentSummary.samples.map { $0.endDate }.max() ?? selectedDate
        
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

struct SleepDayDetailContent: View {
    let summary: DailySleepSummary?
    let selectedChartView: String
    let enableHeartRateAnalysis: Bool
    let enableRespiratoryRateAnalysis: Bool
    let realAverageHeartRate: Double?
    let realAverageRespiratoryRate: Double?
    let manager: HealthKitManager
    
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
                        Spacer(minLength: 120)
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
    }
}
