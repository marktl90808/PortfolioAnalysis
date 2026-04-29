//
//  DeveloperLabel.swift
//  PortfolioAnalysis
//
//  Updated: smaller, more transparent, lighter fill, regular-weight text
//

import SwiftUI

struct DeveloperLabelModifier: ViewModifier {
    let text: String

    // Visual tuning
    var font: Font = .system(size: 13, weight: .regular, design: .rounded)
    var horizontalPadding: CGFloat = 8
    var verticalPadding: CGFloat = 4
    var backgroundColor: Color = Color.black.opacity(0.08) // very light, semi-transparent
    var materialOpacity: Double = 0.0 // keep material subtle; using plain color primarily
    var cornerRadius: CGFloat = 6
    var offsetX: CGFloat = 10
    var offsetY: CGFloat = 10

    func body(content: Content) -> some View {
        content
            .overlay(
                HStack(spacing: 6) {
                    Text(text)
                        .font(font)
                        .foregroundColor(Color.primary.opacity(0.85))
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                }
                .padding(.vertical, verticalPadding)
                .padding(.horizontal, horizontalPadding)
                .background(
                    // subtle layered background: light color + ultraThinMaterial (very faint)
                    ZStack {
                        backgroundColor
                        Color(.systemBackground)
                            .opacity(materialOpacity)
                    }
                )
                .cornerRadius(cornerRadius)
                .shadow(color: Color.black.opacity(0.06), radius: 2, x: 0, y: 1)
                .padding(.trailing, offsetX)
                .padding(.bottom, offsetY)
                , alignment: .bottomTrailing
            )
    }
}

extension View {
    /// Adds a small, subtle developer label in the bottom-right corner.
    /// - Parameter text: The label text to display.
    func developerLabel(_ text: String) -> some View {
        modifier(
            DeveloperLabelModifier(
                text: text,
                font: .system(size: 13, weight: .regular, design: .rounded),
                horizontalPadding: 8,
                verticalPadding: 4,
                backgroundColor: Color.black.opacity(0.06),
                materialOpacity: 0.0,
                cornerRadius: 6,
                offsetX: 10,
                offsetY: 10
            )
        )
    }
}
