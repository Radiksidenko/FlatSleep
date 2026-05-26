//
//  SleepCalendarView.swift
//  FlatSleep
//
//  Created by Radomyr Sidenko on 26.05.2026.
//

import SwiftUI

struct SleepCalendarView: View {
    @StateObject private var hkManager = DebugHealthKitManager()
    
    let calendar = Calendar.current
    let daysInMonth: [Date]
    
    init() {
        let now = Date()
        let currentCalendar = Calendar.current
        
        guard let range = currentCalendar.range(of: .day, in: .month, for: now) else {
            self.daysInMonth = []
            return
        }
        
        let components = currentCalendar.dateComponents([.year, .month], from: now)
        guard let startOfMonth = currentCalendar.date(from: components) else {
            self.daysInMonth = []
            return
        }
        
        let generatedDays = range.compactMap { day -> Date? in
            currentCalendar.date(byAdding: .day, value: day - 1, to: startOfMonth)
        }
        
        self.daysInMonth = generatedDays
    }
    
    let columns = Array(repeating: GridItem(.flexible(), spacing: 10), count: 7)
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    
                    HStack(spacing: 12) {
                        HStack(spacing: 4) {
                            Image(systemName: "circle.fill").foregroundColor(.orange)
                            Text("Awake").font(.caption2)
                        }
                        HStack(spacing: 4) {
                            Image(systemName: "circle.fill").foregroundColor(.blue)
                            Text("Core").font(.caption2)
                        }
                        HStack(spacing: 4) {
                            Image(systemName: "circle.fill").foregroundColor(.indigo)
                            Text("Deep").font(.caption2)
                        }
                        HStack(spacing: 4) {
                            Image(systemName: "circle.fill").foregroundColor(.purple)
                            Text("REM").font(.caption2)
                        }
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(10)
                    
                    LazyVGrid(columns: columns, spacing: 15) {
                        ForEach(daysInMonth, id: \.self) { date in
                            let startOfDay = calendar.startOfDay(for: date)
                            let daySummary = hkManager.monthlySleepData[startOfDay]
                            
                            VStack(spacing: 6) {
                                Text("\(calendar.component(.day, from: date))")
                                    .font(.footnote)
                                    .bold()
                                    .foregroundColor(calendar.isDateInToday(date) ? .indigo : .primary)
                                
                                SleepRingView(summary: daySummary, size: 42)
                            }
                            .frame(height: 75)
                            .background(calendar.isDateInToday(date) ? Color.indigo.opacity(0.05) : Color.clear)
                            .cornerRadius(8)
                        }
                    }
                    .padding()
                    
                }
            }
            .navigationTitle("Sleep Analytics")
            .onAppear {
                hkManager.fetchMonthlySleepData()
            }
        }
    }
}
