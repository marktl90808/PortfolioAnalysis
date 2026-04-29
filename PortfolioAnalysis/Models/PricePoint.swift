import Foundation

// MARK: - Price Point

struct PricePoint: Identifiable {
    var id = UUID()
    var date: Date
    var open: Double
    var high: Double
    var low: Double
    var close: Double
    var volume: Int
}

// MARK: - Chart Time Range

enum ChartTimeRange: String, CaseIterable, Identifiable {
    case oneWeek     = "1W"
    case oneMonth    = "1M"
    case threeMonths = "3M"
    case sixMonths   = "6M"
    case oneYear     = "1Y"
    case threeYears  = "3Y"
    case fiveYears   = "5Y"

    var id: String { rawValue }

    var yahooRange: String {
        switch self {
        case .oneWeek:     return "5d"
        case .oneMonth:    return "1mo"
        case .threeMonths: return "3mo"
        case .sixMonths:   return "6mo"
        case .oneYear:     return "1y"
        case .threeYears:  return "3y"
        case .fiveYears:   return "5y"
        }
    }

    var interval: String {
        switch self {
        case .oneWeek, .oneMonth, .threeMonths, .sixMonths: return "1d"
        case .oneYear, .threeYears:                         return "1wk"
        case .fiveYears:                                    return "1mo"
        }
    }
}
