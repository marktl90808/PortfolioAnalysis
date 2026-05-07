//
//  DeveloperOverlay.swift
//  PortfolioAnalysis
//

import SwiftUI

// MARK: - Developer Overlay Registry

final class DeveloperOverlayRegistry {
    static let shared = DeveloperOverlayRegistry()

    private(set) var entries: [(id: Int, name: String)] = []
    private var nextID = 1

    func register(_ name: String) -> Int {
        let id = nextID
        nextID += 1
        entries.append((id, name))
        return id
    }

    func reset() {
        entries.removeAll()
        nextID = 1
    }
}

// MARK: - Developer Overlay Modifier

struct DeveloperOverlay: ViewModifier {
    let fileName: String
    @State private var id: Int = 0

    func body(content: Content) -> some View {
        ZStack(alignment: .topLeading) {
            content

            Text("\(id)")
                .font(.caption.bold())
                .foregroundColor(.red)
                .padding(4)
                .offset(x: -8, y: -8)   // push into margin
                .allowsHitTesting(false)
        }
        .onAppear {
            if id == 0 {
                id = DeveloperOverlayRegistry.shared.register(fileName)
            }
        }
    }
}

// MARK: - Footer Legend

struct DeveloperOverlayFooter: View {
    @State private var entries: [(id: Int, name: String)] = []

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Divider().padding(.vertical, 4)

            ForEach(entries, id: \.id) { entry in
                Text("\(entry.id)* \(entry.name)")
                    .font(.footnote)
                    .foregroundColor(.red)
            }
        }
        .padding(.horizontal)
        .onAppear {
            entries = DeveloperOverlayRegistry.shared.entries
        }
    }
}

// MARK: - View Extension

extension View {
    func developerOverlay(_ fileName: String) -> some View {
        self.modifier(DeveloperOverlay(fileName: fileName))
    }

    func developerOverlayFooter() -> some View {
        DeveloperOverlayFooter()
    }
}
