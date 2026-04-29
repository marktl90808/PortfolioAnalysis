import Foundation

// MARK: - Yahoo Finance Response Models

private struct YFResponse: Decodable {
    let chart: YFChart
}
private struct YFChart: Decodable {
    let result: [YFResult]?
    let error: YFError?
}
private struct YFError: Decodable {
    let code: String
    let description: String
}
private struct YFResult: Decodable {
    let meta: YFMeta
    let timestamp: [Int]?
    let indicators: YFIndicators
}
private struct YFMeta: Decodable {
    let symbol: String
    let regularMarketPrice: Double?
    let previousClose: Double?
    let fiftyTwoWeekHigh: Double?
    let fiftyTwoWeekLow: Double?
    let currency: String?
    let exchangeName: String?
}
private struct YFIndicators: Decodable {
    let quote: [YFQuote]
}
private struct YFQuote: Decodable {
    let open:   [Double?]?
    let high:   [Double?]?
    let low:    [Double?]?
    let close:  [Double?]?
    let volume: [Int?]?
}

// MARK: - Market Data Error

enum MarketDataError: LocalizedError {
    case invalidURL
    case badHTTPStatus(Int)
    case noData
    case apiError(String)

    var errorDescription: String? {
        switch self {
        case .invalidURL:           return "Invalid URL"
        case .badHTTPStatus(let c): return "HTTP \(c)"
        case .noData:               return "No data returned for this symbol"
        case .apiError(let msg):    return msg
        }
    }
}

// MARK: - Market Data Service

@MainActor
class MarketDataService: ObservableObject {

    static let shared = MarketDataService()

    @Published var isLoading = false
    @Published var errorMessage: String?

    private let session: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 15
        return URLSession(configuration: config)
    }()

    // MARK: - Fetch Price History

    func fetchPriceHistory(symbol: String, timeRange: ChartTimeRange) async throws -> [PricePoint] {
        let urlStr = "https://query1.finance.yahoo.com/v8/finance/chart/\(symbol)?range=\(timeRange.yahooRange)&interval=\(timeRange.interval)"
        guard let url = URL(string: urlStr) else { throw MarketDataError.invalidURL }

        var req = URLRequest(url: url)
        req.setValue("Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X)", forHTTPHeaderField: "User-Agent")

        let (data, response) = try await session.data(for: req)

        if let http = response as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
            throw MarketDataError.badHTTPStatus(http.statusCode)
        }

        let decoded = try JSONDecoder().decode(YFResponse.self, from: data)

        if let err = decoded.chart.error {
            throw MarketDataError.apiError(err.description)
        }

        guard let result    = decoded.chart.result?.first,
              let timestamps = result.timestamp,
              let quote      = result.indicators.quote.first else {
            throw MarketDataError.noData
        }

        var points: [PricePoint] = []
        for (i, ts) in timestamps.enumerated() {
            guard let close = quote.close?[safe: i] ?? nil else { continue }
            points.append(PricePoint(
                date:   Date(timeIntervalSince1970: TimeInterval(ts)),
                open:   quote.open?[safe: i]   ?? nil ?? close,
                high:   quote.high?[safe: i]   ?? nil ?? close,
                low:    quote.low?[safe: i]    ?? nil ?? close,
                close:  close,
                volume: quote.volume?[safe: i] ?? nil ?? 0
            ))
        }
        return points.sorted { $0.date < $1.date }
    }

    // MARK: - Fetch Current Price

    func fetchCurrentPrice(symbol: String) async throws -> Double {
        let points = try await fetchPriceHistory(symbol: symbol, timeRange: .oneMonth)
        guard let last = points.last else { throw MarketDataError.noData }
        return last.close
    }

    // MARK: - Refresh All Holdings

    func refreshAllPrices(portfolio: Portfolio) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        let symbols = Array(Set(portfolio.nonCashHoldings.map(\.symbol)))

        await withTaskGroup(of: (String, Double?).self) { group in
            for symbol in symbols {
                group.addTask { [weak self] in
                    guard let self else { return (symbol, nil) }
                    do {
                        let price = try await self.fetchCurrentPrice(symbol: symbol)
                        return (symbol, price)
                    } catch {
                        return (symbol, nil)
                    }
                }
            }
            for await (symbol, price) in group {
                if let price {
                    portfolio.updatePrice(for: symbol, price: price)
                }
            }
        }
    }
}

// MARK: - Safe Subscript

extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
