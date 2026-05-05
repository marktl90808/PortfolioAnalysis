//
//  DeveloperLabel.swift
//  PortfolioAnalysis
//
//  Updated: smaller, more transparent, lighter fill, regular-weight text
//

import SwiftUI

struct DeveloperLabel: ViewModifier {
    let fileName: String

    func body(content: Content) -> some View {
        content
            .overlay(
                VStack {
                    Spacer()   // pushes label to the bottom
                    HStack {
                        Text(fileName)
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(.thinMaterial)
                            .cornerRadius(6)
                            .padding(.leading, 8)
                            .padding(.bottom, 8)   // safe zone above home indicator
                        Spacer()
                    }
                }
            )
    }
}

extension View {
    func developerLabel(_ name: String) -> some View {
        self.modifier(DeveloperLabel(fileName: name))
    }
}
