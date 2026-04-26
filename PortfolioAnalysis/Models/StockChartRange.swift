//
//  StockChartRange.swift
//  PortfolioAnalysis
//
//  Created by Mark Leonard on 4/23/2026.
//

import Foundation

/// Stock-style chart ranges used by the detail view and Yahoo chart requests.
enum StockChartRange: String, CaseIterable, Identifiable, Sendable {
    case oneDay
    case oneWeek
    case oneMonth
    case threeMonth
    case sixMonth
    case oneYear
    case fiveYear

    var id: String { rawValue }

    var label: String {
        switch self {
        case .oneDay: return "1D"
        case .oneWeek: return "1W"
        case .oneMonth: return "1M"
        case .threeMonth: return "3M"
        case .sixMonth: return "6M"
        case .oneYear: return "1Y"
        case .fiveYear: return "5Y"
        }
    }

    var yahooRange: String {
        switch self {
        case .oneDay: return "1d"
        case .oneWeek: return "5d"
        case .oneMonth: return "1mo"
        case .threeMonth: return "3mo"
        case .sixMonth: return "6mo"
        case .oneYear: return "1y"
        case .fiveYear: return "5y"
        }
    }

    var yahooInterval: String {
        switch self {
        case .oneDay: return "5m"
        case .oneWeek: return "15m"
        case .oneMonth: return "1d"
        case .threeMonth: return "1d"
        case .sixMonth: return "1d"
        case .oneYear: return "1d"
        case .fiveYear: return "1wk"
        }
    }
}
