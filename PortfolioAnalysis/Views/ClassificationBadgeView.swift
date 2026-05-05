//
//  ClassificationBadgeView.swift
//  PortfolioAnalysis
//
//  Created by Mark Leonard on 5/5/2026.
//

import SwiftUI

struct ClassificationBadgeView: View {
    let classification: PositionClassification
    @AppStorage("badgeStyle") private var badgeStyle: BadgeStyle = .expressive

    var body: some View {
        switch badgeStyle {
        case .expressive:
            expressiveBadge
        case .minimal:
            minimalBadge
        }
    }

    private var expressiveBadge: some View {
        HStack(spacing: 6) {
            Image(systemName: classification.icon)
                .font(.caption.bold())
            Text(classification.label)
                .font(.caption.bold())
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background(classification.color.opacity(0.15))
        .foregroundColor(classification.color)
        .clipShape(Capsule())
    }

    private var minimalBadge: some View {
        Image(systemName: classification.icon)
            .font(.caption.bold())
            .padding(6)
            .background(classification.color.opacity(0.15))
            .foregroundColor(classification.color)
            .clipShape(Circle())
    }
}
