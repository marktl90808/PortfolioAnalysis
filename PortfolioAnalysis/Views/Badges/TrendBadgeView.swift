//
//  TrendBadgeView.swift
//  PortfolioAnalysis
//
//  Created by Mark Leonard on 4/28/2026.
//


import SwiftUI

struct TrendBadgeView: View {
    let trend: TrendClassification

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: trend.icon)
                .font(.caption2)
            Text(trend.shortLabel)
                .font(.caption2.bold())
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 8)
        .background(trend.color.opacity(0.15))
        .foregroundColor(trend.color)
        .clipShape(Capsule())
    }
}
