//
//  ImportedPosition.swift
//  PortfolioAnalysis
//
//  Created by Mark Leonard on 4/22/2026.
//

import Foundation

// MARK: - ImportedPosition Model

struct ImportedPosition: Identifiable, Codable, Sendable {
    let id = UUID()

    let ticker: String
    let name: String

    // LPL rounded quantity (for UI)
    let quantity: Double?

    // High‑precision inferred quantity (for calculations)
    let effectiveQuantity: Double?

    let costBasisPerShare: Double?
    let cashValue: Double?
    let dayChangeAmount: Double?
    let acquisitionDate: Date?
    let accountId: String

    private enum CodingKeys: String, CodingKey {
        case ticker
        case name
        case quantity
        case effectiveQuantity
        case costBasisPerShare
        case cashValue
        case dayChangeAmount
        case acquisitionDate
        case accountId
    }

    var isCash: Bool {
        let t = ticker.lowercased()
        let n = name.lowercased()

        return cashValue != nil
            || t == "cash"
            || n == "cash"
            || t == "----"
            || n.contains("money market")
            || n.contains("insured cash")
    }
}

