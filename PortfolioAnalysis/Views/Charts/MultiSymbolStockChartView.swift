//
//  MultiSymbolStockChartView.swift
//  PortfolioAnalysis
//

import SwiftUI
import Charts

struct MultiSymbolStockChartView: View {
    let symbols: [String]
    let histories: [String: [PricePoint]]
    let mode: CompareMode   // Performance | Price

    @State private var dragDate: Date?
    @State private var dragX: CGFloat = 0

    private let palette: [Color] = [
        .blue, .green, .orange, .purple, .red
    ]

    private func color(for symbol: String) -> Color {
        guard let idx = symbols.firstIndex(of: symbol) else { return .gray }
        return palette[idx % palette.count]
    }

    private var alignedData: [String: [PricePoint]] {
        var result: [String: [PricePoint]] = [:]
        for symbol in symbols {
            let sorted = (histories[symbol] ?? []).sorted { $0.date < $1.date }
            result[symbol] = sorted
        }
        return result
    }

    private var performanceData: [String: [(date: Date, pct: Double)]] {
        var dict: [String: [(Date, Double)]] = [:]

        for symbol in symbols {
            guard let series = alignedData[symbol], let first = series.first else { continue }
            let base = first.close
            dict[symbol] = series.map { ($0.date, (($0.close - base) / base) * 100.0) }
        }
        return dict
    }

    private var priceData: [String: [(date: Date, price: Double)]] {
        var dict: [String: [(Date, Double)]] = [:]
        for symbol in symbols {
            guard let series = alignedData[symbol] else { continue }
            dict[symbol] = series.map { ($0.date, $0.close) }
        }
        return dict
    }

    private var xDomain: ClosedRange<Date>? {
        let allDates = alignedData.values.flatMap { $0.map(\.date) }
        guard let minD = allDates.min(), let maxD = allDates.max(), minD < maxD else { return nil }
        return minD...maxD
    }

    private var yDomain: ClosedRange<Double>? {
        switch mode {
        case .performance:
            let all = performanceData.values.flatMap { $0.map(\.pct) }
            guard let minV = all.min(), let maxV = all.max(), minV < maxV else { return nil }
            return minV...maxV

        case .price:
            let all = priceData.values.flatMap { $0.map(\.price) }
            guard let minV = all.min(), let maxV = all.max(), minV < maxV else { return nil }
            return minV...maxV
        }
    }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                Chart {
                    switch mode {

                    // PERFORMANCE MODE
                    case .performance:
                        ForEach(symbols, id: \.self) { symbol in
                            if let series = performanceData[symbol] {
                                ForEach(series, id: \.date) { point in
                                    LineMark(
                                        x: .value("Date", point.date),
                                        y: .value("Pct", point.pct)
                                    )
                                    .interpolationMethod(.catmullRom)
                                    .foregroundStyle(color(for: symbol))
                                    .lineStyle(StrokeStyle(lineWidth: 2))
                                }

                                // Right-edge label
                                if let last = series.last {
                                    PointMark(
                                        x: .value("Date", last.date),
                                        y: .value("Pct", last.pct)
                                    )
                                    .annotation(position: .trailing) {
                                        Text("\(last.pct, specifier: "%.1f")%")
                                            .font(.caption2.bold())
                                            .foregroundColor(color(for: symbol))
                                    }
                                }
                            }
                        }

                    // PRICE MODE
                    case .price:
                        ForEach(symbols, id: \.self) { symbol in
                            if let series = priceData[symbol] {
                                ForEach(series, id: \.date) { point in
                                    LineMark(
                                        x: .value("Date", point.date),
                                        y: .value("Price", point.price)
                                    )
                                    .interpolationMethod(.catmullRom)
                                    .foregroundStyle(color(for: symbol))
                                    .lineStyle(StrokeStyle(lineWidth: 2))
                                }

                                // Right-edge label
                                if let last = series.last {
                                    PointMark(
                                        x: .value("Date", last.date),
                                        y: .value("Price", last.price)
                                    )
                                    .annotation(position: .trailing) {
                                        Text(last.price, format: .currency(code: Locale.current.currency?.identifier ?? "USD"))
                                            .font(.caption2.bold())
                                            .foregroundColor(color(for: symbol))
                                    }
                                }
                            }
                        }
                    }
                }
                .chartXScale(domain: xDomain ?? Date.distantPast...Date.distantFuture)
                .chartYScale(domain: yDomain ?? 0...1)
                .chartXAxis {
                    AxisMarks(values: .automatic(desiredCount: 5))
                }
                .chartYAxis {
                    AxisMarks(values: .automatic(desiredCount: 5))
                }
                .padding(.vertical, 8)

                // Touch inspector
                if dragDate != nil {
                        Rectangle()
                            .fill(Color.secondary.opacity(0.35))
                            .frame(width: 1)
                            .offset(x: dragX)
                    }
            }
            .gesture(
                DragGesture()
                    .onChanged { value in
                        dragX = value.location.x
                        dragDate = approximateDate(atX: value.location.x, width: geo.size.width)
                    }
                    .onEnded { _ in
                        dragDate = nil
                    }
            )
        }
    }

    private func approximateDate(atX x: CGFloat, width: CGFloat) -> Date? {
        guard let domain = xDomain else { return nil }
        let ratio = max(0, min(1, x / width))
        let interval = domain.upperBound.timeIntervalSince(domain.lowerBound)
        return domain.lowerBound.addingTimeInterval(interval * ratio)
    }
}
// MARK: End of MultiSymbolStockChartView.swift
