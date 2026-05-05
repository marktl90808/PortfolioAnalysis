//
//  BadgeStyleSettingsView.swift
//  PortfolioAnalysis
//
//  Created by Mark Leonard on 5/5/2026.
//

import SwiftUI

struct BadgeStyleSettingsView: View {
    @AppStorage("badgeStyle") private var badgeStyle: BadgeStyle = .expressive

    var body: some View {
        Form {
            Section(header: Text("Badge Style")) {
                Picker("Badge Style", selection: $badgeStyle) {
                    Text("Expressive").tag(BadgeStyle.expressive)
                    Text("Minimal").tag(BadgeStyle.minimal)
                }
                .pickerStyle(.segmented)
            }
        }
        .navigationTitle("Badge Style")
    }
}
