//
//  AnalysisFlags.swift
//  FlatSleep
//
//  Created by Radomyr Sidenko on 27.05.2026.
//

import Foundation

struct AnalysisFlags: Equatable {
    let hrEnabled: Bool
    let rrEnabled: Bool
    let penaltiesEnabled: Bool
    
    init(_ hrEnabled: Bool, _ rrEnabled: Bool, _ penaltiesEnabled: Bool) {
        self.hrEnabled = hrEnabled
        self.rrEnabled = rrEnabled
        self.penaltiesEnabled = penaltiesEnabled
    }
}
