//
//  PricePoint.swift
//  PortfolioAnalysis
//
//  Created by Mark Leonard on 4/22/2026.
//
import Foundation

/// A single historical price point for a security.
struct PricePoint: Identifiable {
    let id = UUID()
    let date: Date
    let close: Double
}

