//
//  TimeRange.swift
//  PortfolioAnalysis
//
//  Created by Mark Leonard on 4/28/2026.
//
//
//  TimeRange.swift
//  PortfolioAnalysis
//
//  Created by Mark Leonard on 4/28/2026.
//

import Foundation

enum TimeRange: String, CaseIterable, Identifiable {
    case oneDay = "1D"
    case oneWeek = "1W"
    case oneMonth = "1M"
    case threeMonths = "3M"
    case sixMonths = "6M"
    case oneYear = "1Y"
    case ytd = "YTD"

    var id: String { rawValue }

    // Existing function you already had
    func dateWindow(from now: Date = Date()) -> Date {
        let cal = Calendar.current
        switch self {
        case .oneDay:
            return cal.date(byAdding: .day, value: -1, to: now) ?? now
        case .oneWeek:
            return cal.date(byAdding: .day, value: -7, to: now) ?? now
        case .oneMonth:
            return cal.date(byAdding: .month, value: -1, to: now) ?? now
        case .threeMonths:
            return cal.date(byAdding: .month, value: -3, to: now) ?? now
        case .sixMonths:
            return cal.date(byAdding: .month, value: -6, to: now) ?? now
        case .oneYear:
            return cal.date(byAdding: .year, value: -1, to: now) ?? now
        case .ytd:
            return cal.date(from: cal.dateComponents([.year], from: now)) ?? now
        }
    }
}

// MARK: - Extension for chart compatibility
extension TimeRange {
    func toDateRange() -> ClosedRange<Date> {
        let now = Date()
        let start = self.dateWindow(from: now)
        return start...now
    }
}
