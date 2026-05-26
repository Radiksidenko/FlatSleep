//
//  MonthHeaderView.swift
//  FlatSleep
//
//  Created by Radomyr Sidenko on 26.05.2026.
//

import SwiftUI

struct MonthHeaderView: View {
    let title: String
    let daysOfWeek: [String]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .bold()
                .foregroundColor(.primary)
                .padding(.horizontal)
                .padding(.top, 10)
            
            HStack(spacing: 0) {
                ForEach(Array(daysOfWeek.enumerated()), id: \.offset) { index, day in
                    Text(day)
                        .font(.caption2)
                        .bold()
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.bottom, 6)
            
            Divider()
                .padding(.horizontal)
        }
    }
}
