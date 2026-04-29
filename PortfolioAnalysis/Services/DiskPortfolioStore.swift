//
//  DiskPortfolioStore.swift
//  PortfolioAnalysis
//
//  Created by Mark Leonard on 4/24/2026.
//

import Foundation

actor DiskPortfolioStore {

    static let shared = DiskPortfolioStore()

    // MARK: - File Location

    private var fileURL: URL {
        let folder = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return folder.appendingPathComponent("portfolio.json")
    }

    // MARK: - Safety Limits

    private let maxBytes = 2_000_000        // 2 MB max file size
    private let maxPositions = 1000         // cap number of positions

    // MARK: - Save

    func save(_ positions: [ImportedPosition]) async {
        let safePositions = Array(positions.prefix(maxPositions))

        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted]

            let data = try encoder.encode(safePositions)

            // Reject oversized files
            guard data.count <= maxBytes else {
                print("⚠️ Portfolio too large to save to disk (\(data.count) bytes). Skipping.")
                return
            }

            try data.write(to: fileURL, options: [.atomic])
            print("💾 Portfolio saved to disk at \(fileURL.path)")

        } catch {
            print("❌ Failed to save portfolio to disk: \(error)")
        }
    }

    // MARK: - Load

    func load() async -> [ImportedPosition] {
        do {
            let data = try Data(contentsOf: fileURL)

            // Reject oversized files
            guard data.count <= maxBytes else {
                print("⚠️ Disk portfolio too large (\(data.count) bytes). Clearing.")
                try? FileManager.default.removeItem(at: fileURL)
                return []
            }

            let decoder = JSONDecoder()
            let positions = try decoder.decode([ImportedPosition].self, from: data)
            print("📂 Loaded \(positions.count) positions from disk")
            return positions

        } catch {
            print("⚠️ No valid disk portfolio found or failed to decode: \(error)")
            return []
        }
    }

    // MARK: - Clear

    func clear() async {
        do {
            try FileManager.default.removeItem(at: fileURL)
            print("🗑️ Cleared disk portfolio")
        } catch {
            print("⚠️ Failed to clear disk portfolio: \(error)")
        }
    }
}
