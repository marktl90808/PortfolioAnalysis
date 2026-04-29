import Foundation
import Combine

class Portfolio: ObservableObject {
    @Published var holdings: [Holding] = []
    @Published var lastImportDate: Date?

    // MARK: - Computed Properties

    var nonCashHoldings: [Holding] {
        holdings.filter { $0.assetType != .cash }
    }

    var cashHoldings: [Holding] {
        holdings.filter { $0.assetType == .cash }
    }

    var totalMarketValue: Double {
        nonCashHoldings.reduce(0) { $0 + $1.marketValue }
    }

    var totalCashValue: Double {
        cashHoldings.reduce(0) { $0 + $1.marketValue }
    }

    var totalPortfolioValue: Double {
        totalMarketValue + totalCashValue
    }

    var totalCostBasis: Double {
        nonCashHoldings.reduce(0) { $0 + $1.costBasis }
    }

    var totalGainLoss: Double {
        nonCashHoldings.reduce(0) { $0 + $1.gainLoss }
    }

    var totalGainLossPercent: Double {
        guard totalCostBasis > 0 else { return 0 }
        return (totalGainLoss / totalCostBasis) * 100
    }

    var iraHoldings: [Holding] {
        holdings.filter { $0.accountType == .traditionalIRA }
    }

    var nonIRAHoldings: [Holding] {
        holdings.filter { $0.accountType == .nonIRA }
    }

    var holdingsByAccount: [(key: String, value: [Holding])] {
        let grouped = Dictionary(grouping: holdings) { $0.accountName }
        return grouped.sorted { $0.key < $1.key }
    }

    var accounts: [String] {
        Array(Set(holdings.map { $0.accountName })).sorted()
    }

    // MARK: - Actions

    func importHoldings(_ newHoldings: [Holding]) {
        holdings = newHoldings
        lastImportDate = Date()
    }

    func updatePrice(for symbol: String, price: Double) {
        for i in holdings.indices where holdings[i].symbol == symbol {
            holdings[i].currentPrice = price
        }
    }
}

// MARK: - Preview Data

extension Portfolio {
    static var preview: Portfolio {
        let p = Portfolio()
        p.holdings = [
            Holding(symbol: "AAPL",  name: "Apple Inc.",                     shares: 100, costBasisPerShare: 150.00, currentPrice: 185.50,  accountName: "Fidelity Brokerage",  accountType: .nonIRA,        assetType: .stock),
            Holding(symbol: "MSFT",  name: "Microsoft Corp.",                shares: 50,  costBasisPerShare: 280.00, currentPrice: 420.00,  accountName: "Fidelity Brokerage",  accountType: .nonIRA,        assetType: .stock),
            Holding(symbol: "NVDA",  name: "NVIDIA Corp.",                   shares: 30,  costBasisPerShare: 400.00, currentPrice: 875.00,  accountName: "Fidelity Brokerage",  accountType: .nonIRA,        assetType: .stock),
            Holding(symbol: "INTC",  name: "Intel Corp.",                    shares: 200, costBasisPerShare: 48.00,  currentPrice: 22.00,   accountName: "Fidelity Brokerage",  accountType: .nonIRA,        assetType: .stock),
            Holding(symbol: "VOO",   name: "Vanguard S&P 500 ETF",          shares: 40,  costBasisPerShare: 350.00, currentPrice: 480.00,  accountName: "Fidelity IRA",        accountType: .traditionalIRA, assetType: .etf),
            Holding(symbol: "QQQ",   name: "Invesco QQQ Trust",              shares: 20,  costBasisPerShare: 300.00, currentPrice: 450.00,  accountName: "Schwab IRA",          accountType: .traditionalIRA, assetType: .etf),
            Holding(symbol: "VTSAX", name: "Vanguard Total Stock Market",    shares: 200, costBasisPerShare: 95.00,  currentPrice: 115.00,  accountName: "Schwab IRA",          accountType: .traditionalIRA, assetType: .mutualFund),
            Holding(symbol: "CASH",  name: "Cash & Equivalents",             shares: 1,   costBasisPerShare: 5000.00, currentPrice: 5000.00, accountName: "Fidelity Brokerage", accountType: .nonIRA,        assetType: .cash),
            Holding(symbol: "CASH",  name: "Cash & Equivalents",             shares: 1,   costBasisPerShare: 1200.00, currentPrice: 1200.00, accountName: "Schwab Brokerage",   accountType: .nonIRA,        assetType: .cash),
            Holding(symbol: "CASH",  name: "Cash & Equivalents",             shares: 1,   costBasisPerShare: 3000.00, currentPrice: 3000.00, accountName: "Fidelity IRA",       accountType: .traditionalIRA, assetType: .cash),
            Holding(symbol: "CASH",  name: "Cash & Equivalents",             shares: 1,   costBasisPerShare: 800.00,  currentPrice: 800.00,  accountName: "Schwab IRA",         accountType: .traditionalIRA, assetType: .cash),
        ]
        return p
    }
}
