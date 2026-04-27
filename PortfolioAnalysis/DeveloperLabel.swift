//
//  DeveloperLabel.swift
//  PortfolioAnalysis
//

import SwiftUI

struct DeveloperLabel: ViewModifier {
    let name: String

    func body(content: Content) -> some View {
        content
            .overlay(
                Text(name)
                    .font(.system(size: 8, weight: .regular, design: .monospaced))
                    .padding(2)
                    .background(Color.black.opacity(0.25))
                    .foregroundColor(.white.opacity(0.9))
                    .cornerRadius(3)
                    .padding(4),
                alignment: .topLeading   // moved so it never covers data
            )
    }
}

extension View {
    func developerLabel(_ name: String) -> some View {
        self.modifier(DeveloperLabel(name: name))
    }
}
