//
//  SleepCalendarView.swift
//  FlatSleep
//
//  Created by Radomyr Sidenko on 26.05.2026.
//

import SwiftUI

struct SleepCalendarView: View {
    @StateObject private var hkManager = HealthKitManager()
    
    @State private var isFirstLoad = true
    
    let calendar = Calendar.current
    let monthsData: [MonthSection]
    let startDateLimit: Date
    let currentMonthSectionID: UUID
    
    private let daysOfWeek = ["M", "T", "W", "T", "F", "S", "S"]
    let columns = Array(repeating: GridItem(.flexible(), spacing: 10), count: 7)
    
    init() {
        let currentCalendar = Calendar.current
        let now = Date()
        
        var sections: [MonthSection] = []
        let totalMonthsToDisplay = 6
        
        let earliestMonthDate = currentCalendar.date(byAdding: .month, value: -(totalMonthsToDisplay - 1), to: now) ?? now
        let earliestComponents = currentCalendar.dateComponents([.year, .month], from: earliestMonthDate)
        let globalStart = currentCalendar.date(from: earliestComponents) ?? now
        self.startDateLimit = globalStart
        
        for monthOffset in 0..<totalMonthsToDisplay {
            guard let monthDate = currentCalendar.date(byAdding: .month, value: monthOffset, to: globalStart) else { continue }
            
            let components = currentCalendar.dateComponents([.year, .month], from: monthDate)
            guard let startOfMonth = currentCalendar.date(from: components),
                  let range = currentCalendar.range(of: .day, in: .month, for: startOfMonth) else { continue }
            
            let generatedDays = range.compactMap { day -> Date? in
                currentCalendar.date(byAdding: .day, value: day - 1, to: startOfMonth)
            }
            
            let weekday = currentCalendar.component(.weekday, from: startOfMonth)
            let shiftedWeekday = (weekday + 5) % 7
            
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "en_US")
            formatter.dateFormat = "MMMM yyyy"
            let monthName = formatter.string(from: startOfMonth)
            
            sections.append(MonthSection(name: monthName, days: generatedDays, leadingSpaces: shiftedWeekday))
        }
        
        self.monthsData = sections
        self.currentMonthSectionID = sections.last?.id ?? UUID()
    }
    
    var body: some View {
        NavigationView {
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(spacing: 25) {
                        
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
                        .padding(.horizontal)
                        
                        ForEach(monthsData) { monthSection in
                            VStack(alignment: .leading, spacing: 8) {
                                MonthHeaderView(title: monthSection.name, daysOfWeek: daysOfWeek)
                                
                                LazyVGrid(columns: columns, spacing: 15) {
                                    ForEach(0..<monthSection.leadingSpaces, id: \.self) { _ in
                                        Color.clear
                                            .frame(height: 75)
                                    }
                                    
                                    ForEach(monthSection.days, id: \.self) { date in
                                        let startOfDay = calendar.startOfDay(for: date)
                                        let daySummary = hkManager.monthlySleepData[startOfDay]
                                        
                                        NavigationLink(destination: SleepDetailView(date: date, summary: daySummary)) {
                                            VStack(spacing: 6) {
                                                Text("\(calendar.component(.day, from: date))")
                                                    .font(.footnote)
                                                    .bold()
                                                    .foregroundColor(calendar.isDateInToday(date) ? .white : .primary)
                                                    .frame(width: 24, height: 24)
                                                    .background(calendar.isDateInToday(date) ? Color.red : Color.clear)
                                                    .clipShape(Circle())
                                                
                                                SleepRingView(summary: daySummary, size: 42)
                                            }
                                            .frame(height: 75)
                                            .frame(maxWidth: .infinity)
                                            .background(calendar.isDateInToday(date) ? Color.red.opacity(0.05) : Color.clear)
                                            .cornerRadius(8)
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                    }
                                }
                                .padding(.horizontal)
                            }
                            .id(monthSection.id)
                        }
                    }
                    .padding(.top)
                }
                .navigationTitle("Sleep Analytics")
                .onAppear {
                    hkManager.fetchMonthlySleepData(from: startDateLimit)
                    
                    if isFirstLoad {
                        proxy.scrollTo(currentMonthSectionID, anchor: .top)
                        isFirstLoad = false
                    }
                }
            }
        }
    }
}
