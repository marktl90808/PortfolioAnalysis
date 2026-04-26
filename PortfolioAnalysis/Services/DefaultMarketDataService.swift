//
//  DefaultMarketDataService.swift
//  PortfolioAnalysis
//

import Foundation
import Combine

// MARK: - Yahoo Finance Response Models

private struct YahooQuoteResponse: Codable {
    struct QuoteResult: Codable {
        let regularMarketPrice: Double?
        let regularMarketChange: Double?
        let regularMarketChangePercent: Double?
        let symbol: String
    }

    struct QuoteContainer: Codable {
        let result: [QuoteResult]
    }

    let quoteResponse: QuoteContainer
}

private struct YahooChartResponse: Codable {
    struct ChartResult: Codable {
        let timestamp: [Int]?
        let indicators: Indicators
    }

    struct Indicators: Codable {
        let quote: [Quote]
    }

    struct Quote: Codable {
        let close: [Double?]
    }

    struct ChartContainer: Codable {
        let result: [ChartResult]
    }

    let chart: ChartContainer
}

// MARK: - DefaultMarketDataService

public final class DefaultMarketDataService: MarketDataService {

    // MARK: - Cache
    private var priceCache: [String: Double] = [:]
    private let cacheQueue = DispatchQueue(label: "PriceCacheQueue")

    // MARK: - Fetch Quote
    func fetchQuote(for symbol: String) async throws -> MarketQuote {
        let url = URL(string:
            "https://query1.finance.yahoo.com/v7/finance/quote?symbols=\(symbol)"
        )!

        let (data, _) = try await URLSession.shared.data(from: url)
        let decoded = try JSONDecoder().decode(YahooQuoteResponse.self, from: data)

        guard let q = decoded.quoteResponse.result.first else {
            throw NSError(domain: "QuoteError", code: -1, userInfo: [
                NSLocalizedDescriptionKey: "No quote data for \(symbol)"
            ])
        }

        let price = q.regularMarketPrice ?? 0

        // Cache the price
        cacheQueue.sync {
            priceCache[symbol] = price
        }

        return MarketQuote(
            symbol: q.symbol,
            price: price,
            change: q.regularMarketChange ?? 0,
            changePercent: q.regularMarketChangePercent ?? 0
        )
    }

    // MARK: - Fetch Historical Prices
    func fetchPrices(for symbol: String) async throws -> [PricePoint] {
        let url = URL(string:
            "https://query1.finance.yahoo.com/v8/finance/chart/\(symbol)?range=1y&interval=1d"
        )!

        let (data, _) = try await URLSession.shared.data(from: url)
        let decoded = try JSONDecoder().decode(YahooChartResponse.self, from: data)

        guard
            let result = decoded.chart.result.first,
            let timestamps = result.timestamp
        else {
            return []
        }

        let closes = result.indicators.quote.first?.close ?? []

        var points: [PricePoint] = []

        for (i, ts) in timestamps.enumerated() {
            if let close = closes[safe: i] ?? nil {
                let date = Date(timeIntervalSince1970: TimeInterval(ts))
                points.append(PricePoint(date: date, close: close))
            }
        }

        return points
    }

    // MARK: - Cached Price
    func cachedPrice(for symbol: String) -> Double? {
        cacheQueue.sync {
            priceCache[symbol]
        }
    }
}

// MARK: - Safe Array Indexing
private extension Array {
    subscript(safe index: Int) -> Element? {
        guard index >= 0 && index < count else { return nil }
        return self[index]
    }
}

// End of DefaultMarketDataService.swift

