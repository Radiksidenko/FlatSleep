//
//  MonthSection.swift
//  FlatSleep
//
//  Created by Radomyr Sidenko on 26.05.2026.
//

import Foundation

struct MonthSection: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let days: [Date]
    let leadingSpaces: Int
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
