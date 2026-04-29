import Foundation

// MARK: - Account Type

enum AccountType: String, CaseIterable, Codable, Identifiable {
    case nonIRA = "Non-IRA"
    case traditionalIRA = "Traditional IRA"

    var id: String { rawValue }

    var shortName: String {
        switch self {
        case .nonIRA: return "Non-IRA"
        case .traditionalIRA: return "Trad. IRA"
        }
    }

    var isRetirement: Bool { self == .traditionalIRA }
}

// MARK: - Asset Type

enum AssetType: String, CaseIterable, Codable, Identifiable {
    case stock = "Stock"
    case etf = "ETF"
    case mutualFund = "Mutual Fund"
    case cash = "Cash"

    var id: String { rawValue }

    var systemImage: String {
        switch self {
        case .stock:      return "chart.line.uptrend.xyaxis"
        case .etf:        return "chart.bar.fill"
        case .mutualFund: return "dollarsign.circle.fill"
        case .cash:       return "banknote.fill"
        }
    }
}

// MARK: - Analysis Signal

enum AnalysisSignal: String {
    case considerSelling = "Consider Selling"
    case hold            = "Hold"
    case watchClosely    = "Watch Closely"
    case considerExiting = "Consider Exiting"
    case buyMore         = "Buy More"

    var color: String {
        switch self {
        case .considerSelling: return "green"
        case .hold:            return "blue"
        case .watchClosely:    return "orange"
        case .considerExiting: return "red"
        case .buyMore:         return "green"
        }
    }

    var systemImage: String {
        switch self {
        case .considerSelling: return "arrow.up.circle.fill"
        case .hold:            return "equal.circle.fill"
        case .watchClosely:    return "exclamationmark.circle.fill"
        case .considerExiting: return "arrow.down.circle.fill"
        case .buyMore:         return "plus.circle.fill"
        }
    }
}

// MARK: - Holding

struct Holding: Identifiable, Codable, Equatable {
    var id = UUID()
    var symbol: String
    var name: String
    var shares: Double
    var costBasisPerShare: Double
    var currentPrice: Double
    var accountName: String
    var accountType: AccountType
    var assetType: AssetType

    // MARK: Computed Properties

    var costBasis: Double {
        guard assetType != .cash else { return currentPrice }
        return shares * costBasisPerShare
    }

    var marketValue: Double {
        guard assetType != .cash else { return currentPrice }
        return shares * currentPrice
    }

    var gainLoss: Double {
        guard assetType != .cash else { return 0 }
        return marketValue - costBasis
    }

    var gainLossPercent: Double {
        guard assetType != .cash, costBasis > 0 else { return 0 }
        return (gainLoss / costBasis) * 100
    }

    var isOptionable: Bool {
        assetType == .stock || assetType == .etf
    }

    var analysisSignal: AnalysisSignal {
        guard assetType != .cash else { return .hold }
        switch gainLossPercent {
        case let x where x >= 30:  return .considerSelling
        case let x where x >= 10:  return .hold
        case let x where x >= -10: return .hold
        case let x where x >= -20: return .watchClosely
        default:                   return .considerExiting
        }
    }
}
