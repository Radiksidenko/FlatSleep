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
    
    var body: some View {
        Form {
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

struct SleepSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            SleepSettingsView()
        }
    }
}
