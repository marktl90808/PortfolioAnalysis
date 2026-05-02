//
//  PolygonMarketDataService.swift
//  PortfolioAnalysis
//
//  Created by Mark Leonard on 4/30/2026.
//


//
//  PolygonMarketDataService.swift
//  PortfolioAnalysis
//

import Foundation

/// Secondary provider using Polygon.io
/// Conforms to your MarketDataService protocol.
struct PolygonMarketDataService: MarketDataService, Sendable {

    private let apiKey: String

    init(apiKey: String) {
        self.apiKey = apiKey
    }

    // MARK: - Fetch Quote

    func fetchQuote(for symbol: String) async throws -> MarketQuote {
        let urlString =
        "https://api.polygon.io/v2/last/nbbo/\(symbol)?apiKey=\(apiKey)"

        guard let url = URL(string: urlString) else {
            throw NSError(domain: "Polygon", code: -1,
                          userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
        }

        let (data, _) = try await URLSession.shared.data(from: url)

        let decoded = try JSONDecoder().decode(PolygonNBBOResponse.self, from: data)

        // Polygon NBBO gives bid/ask and last price
        let lastPrice = decoded.last.price ?? decoded.last.ask ?? decoded.last.bid ?? 0

        // Polygon does NOT give change/changePercent directly
        // So we compute them as zero (fallback)
        return MarketQuote(
            symbol: symbol,
            price: lastPrice,
            change: 0,
            changePercent: 0
        )
    }

    // MARK: - Fetch Historical Prices

    func fetchPrices(for symbol: String) async throws -> [PricePoint] {
        // Fetch last 1 year of daily candles
        let urlString =
        "https://api.polygon.io/v2/aggs/ticker/\(symbol)/range/1/day/2023-01-01/2026-12-31?adjusted=true&sort=asc&limit=50000&apiKey=\(apiKey)"

        guard let url = URL(string: urlString) else {
            throw NSError(domain: "Polygon", code: -1,
                          userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
        }

        let (data, _) = try await URLSession.shared.data(from: url)

        let decoded = try JSONDecoder().decode(PolygonAggsResponse.self, from: data)

        return decoded.results.map { candle in
            PricePoint(
                date: Date(timeIntervalSince1970: candle.t / 1000),
                close: candle.c
            )
        }
    }

    // MARK: - Cache (Polygon does not cache)

    func cachedPrice(for symbol: String) -> Double? { nil }

    func cachedQuote(for symbol: String) -> MarketQuote? { nil }
}

// MARK: - Polygon Response Models

private struct PolygonNBBOResponse: Codable {
    struct NBBO: Codable {
        let bid: Double?
        let ask: Double?
        let price: Double?
    }
    let last: NBBO
}

private struct PolygonAggsResponse: Codable {
    struct Candle: Codable {
        let t: TimeInterval   // timestamp (ms)
        let c: Double         // close
    }
    let results: [Candle]
}
