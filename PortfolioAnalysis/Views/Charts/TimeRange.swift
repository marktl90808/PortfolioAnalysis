//
//  TimeRange.swift
//  PortfolioAnalysis
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
    case sincePurchase = "Since Purchase"

    var id: String { rawValue }

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

        case .sincePurchase:
            // We override this in StockDetailPage using full history,
            // but we must return *something* to satisfy the switch.
            return .distantPast
        }
    }
}

extension TimeRange {
    func toDateRange() -> ClosedRange<Date> {
        let now = Date()
        let start = self.dateWindow(from: now)
        return start...now
    }
}
// End of TimeRange.swift
