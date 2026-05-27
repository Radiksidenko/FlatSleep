//
//  FlatSleepApp.swift
//  FlatSleep
//
//  Created by Radomyr Sidenko on 26.05.2026.
//

import SwiftUI

@main
struct FlatSleepApp: App {
    var body: some Scene {
        WindowGroup {
            #if targetEnvironment(simulator)
            TabView {
                SleepCalendarView()
                    .tabItem {
                        Label("Сalendar", systemImage: "calendar")
                    }
                
                DebugSleepView()
                    .tabItem {
                        Label("Debug", systemImage: "hammer.fill")
                    }
            }
            #else
            SleepCalendarView()
            #endif
        }
    }
}
