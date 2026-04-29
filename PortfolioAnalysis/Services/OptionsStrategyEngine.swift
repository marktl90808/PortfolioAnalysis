import Foundation
import SwiftUI

// MARK: - Options Strategy

struct OptionsStrategy {
    let name: String
    let description: String
    let systemImage: String
    let color: Color
    let suitability: Suitability
    let estimatedMonthlyIncome: String?

    enum Suitability: String {
        case excellent = "Excellent"
        case good      = "Good"
        case consider  = "Consider"

        var color: Color {
            switch self {
            case .excellent: return .green
            case .good:      return .blue
            case .consider:  return .orange
            }
        }
    }
}

// MARK: - Options Strategy Engine

enum OptionsStrategyEngine {

    static func strategies(for holding: Holding) -> [OptionsStrategy] {
        guard holding.isOptionable else { return [] }

        var result: [OptionsStrategy] = []
        let pct = holding.gainLossPercent

        // 1. Covered Call — when stock is flat or slightly up, generates monthly income
        if pct >= -5 {
            let income = estimatedCoveredCallIncome(price: holding.currentPrice, shares: holding.shares)
            result.append(OptionsStrategy(
                name: "Covered Call",
                description: "Sell a call option above current price to collect premium. Best when you expect the stock to stay flat or rise slowly. Caps upside in exchange for income.",
                systemImage: "arrow.up.right.circle.fill",
                color: .green,
                suitability: pct >= 5 ? .excellent : .good,
                estimatedMonthlyIncome: income
            ))
        }

        // 2. Protective Put — when stock is up significantly and you want downside protection
        if pct >= 15 {
            result.append(OptionsStrategy(
                name: "Protective Put",
                description: "Buy a put option below current price to limit downside risk. Acts like insurance on your position. Good for locking in gains while staying long.",
                systemImage: "shield.fill",
                color: .blue,
                suitability: pct >= 30 ? .excellent : .good,
                estimatedMonthlyIncome: nil
            ))
        }

        // 3. Bull Put Spread — when moderately bullish, sell put spread for income
        if pct >= -15 && pct < 30 {
            let income = estimatedPutSpreadIncome(price: holding.currentPrice)
            result.append(OptionsStrategy(
                name: "Bull Put Spread",
                description: "Sell an out-of-the-money put and buy a further OTM put. Collect credit if the stock stays above the short strike. Defined-risk income strategy.",
                systemImage: "arrow.up.and.down.circle.fill",
                color: .indigo,
                suitability: .good,
                estimatedMonthlyIncome: income
            ))
        }

        // 4. Bear Call Spread — when stock is extended and might pull back
        if pct >= 25 {
            result.append(OptionsStrategy(
                name: "Bear Call Spread",
                description: "Sell a call at or above current price and buy a higher-strike call. Profit if the stock stays below the short strike. Good hedge on large winners.",
                systemImage: "arrow.down.right.circle.fill",
                color: .orange,
                suitability: .consider,
                estimatedMonthlyIncome: nil
            ))
        }

        // 5. Cash-Secured Put — when stock is down and you'd buy more at a lower price
        if pct <= -5 {
            let income = estimatedCashSecuredPutIncome(price: holding.currentPrice)
            result.append(OptionsStrategy(
                name: "Cash-Secured Put",
                description: "Sell a put option below current price. If assigned, you buy shares at the strike (your target entry). Collect premium either way.",
                systemImage: "dollarsign.circle.fill",
                color: .teal,
                suitability: pct <= -15 ? .excellent : .good,
                estimatedMonthlyIncome: income
            ))
        }

        // 6. Iron Condor — when stock is range-bound (flat gain/loss)
        if abs(pct) < 10 {
            result.append(OptionsStrategy(
                name: "Iron Condor",
                description: "Sell both a put spread and a call spread around the current price. Maximum profit if the stock stays within your range. Pure income in a sideways market.",
                systemImage: "arrow.left.and.right.circle.fill",
                color: .purple,
                suitability: .good,
                estimatedMonthlyIncome: estimatedIronCondorIncome(price: holding.currentPrice)
            ))
        }

        return result
    }

    // MARK: - Income Estimators (rough heuristics, ~1% of notional per month for ATM options)

    private static func estimatedCoveredCallIncome(price: Double, shares: Double) -> String {
        let contracts = max(1, Int(shares / 100))
        let income = price * 0.015 * Double(contracts) * 100
        return "$\(Int(income))/mo (est. for \(contracts) contract\(contracts > 1 ? "s" : ""))"
    }

    private static func estimatedPutSpreadIncome(price: Double) -> String {
        let income = price * 0.008 * 100
        return "$\(Int(income))/contract/mo (est.)"
    }

    private static func estimatedCashSecuredPutIncome(price: Double) -> String {
        let income = price * 0.012 * 100
        return "$\(Int(income))/contract/mo (est.)"
    }

    private static func estimatedIronCondorIncome(price: Double) -> String {
        let income = price * 0.01 * 100
        return "$\(Int(income))/contract/mo (est.)"
    }
}
