//
//  StockPriceChartView.swift
//  PortfolioAnalysis
//

import SwiftUI
import Charts

struct StockPriceChartView: View {
    let history: [PricePoint]
    let range: TimeRange
    let showMA20: Bool
    let showMA200: Bool
    let referenceHigh: Double?
    let referenceHighColor: Color
    let quantity: Double   // ← NEW

    @State private var dragLocation: PricePoint?
    @State private var isDragging = false
    @State private var dragX: CGFloat = 0

    private var currencyCode: String {
        Locale.current.currency?.identifier ?? "USD"
    }

    private func wholeDollarText(_ value: Double) -> Text {
        Text(value, format: .currency(code: currencyCode).precision(.fractionLength(0)))
    }

    private var filtered: [PricePoint] {
        guard !history.isEmpty else { return [] }
        let sorted = history.sorted { $0.date < $1.date }
        let now = sorted.last!.date
        let start = range.dateWindow(from: now)
        return sorted.filter { $0.date >= start }
    }

    private var performanceColor: Color {
        guard let first = filtered.first?.close,
              let last = filtered.last?.close else { return .gray }
        if last > first { return .green }
        if last < first { return .red }
        return .gray
    }

    private func movingAverage(_ window: Int) -> [PricePoint] {
        guard filtered.count >= window else { return [] }
        var result: [PricePoint] = []
        for i in window..<filtered.count {
            let slice = filtered[(i-window)..<i]
            let avg = slice.map { $0.close }.reduce(0, +) / Double(window)
            result.append(PricePoint(date: filtered[i].date, close: avg))
        }
        return result
    }

    private var yDomain: ClosedRange<Double>? {
        let closes = filtered.map(\.close)
        guard let minPrice = closes.min(), let maxPrice = closes.max() else { return nil }

        let anchorHigh = referenceHigh.map { max($0, maxPrice) } ?? maxPrice
        let upper = max(maxPrice, anchorHigh * 1.05)
        let lower = min(minPrice, anchorHigh * 0.95)
        return lower < upper ? lower...upper : nil
    }

    private var xDomain: ClosedRange<Date>? {
        guard let first = filtered.first?.date,
              let last = filtered.last?.date,
              first < last else { return nil }
        return first...last
    }

    var body: some View {
        VStack(spacing: 10) {

            // Legend
            HStack(spacing: 14) {
                legendItem(color: performanceColor, title: "Price")
                if showMA20 { legendItem(color: .orange.opacity(0.85), title: "MA20") }
                if showMA200 { legendItem(color: .blue.opacity(0.85), title: "MA200") }
                Spacer()
            }
            .font(.caption2)

            GeometryReader { geo in
                ZStack {

                    // MARK: - Chart
                    Chart {
                        // Main line
                        ForEach(filtered) { p in
                            LineMark(
                                x: .value("Date", p.date),
                                y: .value("Price", p.close)
                            )
                            .interpolationMethod(.catmullRom)
                            .foregroundStyle(performanceColor)
                            .lineStyle(StrokeStyle(lineWidth: 2.5))
                        }

                        // MA20
                        if showMA20 {
                            let ma20 = movingAverage(20)
                            ForEach(ma20) { p in
                                LineMark(
                                    x: .value("Date", p.date),
                                    y: .value("MA20", p.close)
                                )
                                .interpolationMethod(.catmullRom)
                                .foregroundStyle(.orange.opacity(0.8))
                                .lineStyle(StrokeStyle(lineWidth: 1.5, dash: [4, 4]))
                            }
                        }

                        // MA200
                        if showMA200 {
                            let ma200 = movingAverage(200)
                            ForEach(ma200) { p in
                                LineMark(
                                    x: .value("Date", p.date),
                                    y: .value("MA200", p.close)
                                )
                                .interpolationMethod(.catmullRom)
                                .foregroundStyle(.blue.opacity(0.8))
                                .lineStyle(StrokeStyle(lineWidth: 1.5, dash: [6, 4]))
                            }
                        }

                        // 52WH line
                        if let referenceHigh {
                            RuleMark(y: .value("52WH", referenceHigh))
                                .foregroundStyle(referenceHighColor.opacity(0.6))
                                .lineStyle(StrokeStyle(lineWidth: 2.4, dash: [5, 4]))
                                .annotation(position: .topLeading, alignment: .leading) {
                                    HStack(spacing: 4) {
                                        Text("52WH")
                                        wholeDollarText(referenceHigh)
                                    }
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                    .offset(x: 2, y: -2)
                                }
                        }
                    }
                    .chartXScale(domain: xDomain ?? Date.distantPast...Date.distantFuture)
                    .chartYScale(domain: yDomain ?? 0...1)
                    .padding(.vertical, 8)

                    // MARK: - Touch Inspector Overlay
                    if let drag = dragLocation {
                        let value = drag.close * quantity

                        VStack(alignment: .trailing, spacing: 4) {
                            Text(drag.close, format: .currency(code: currencyCode))
                                .font(.caption.bold())

                            Text(drag.date, format: .dateTime.month().day().year())
                                .font(.caption2)

                            Text(value, format: .currency(code: currencyCode))
                                .font(.caption2.weight(.semibold))
                                .foregroundColor(.secondary)
                        }
                        .padding(6)
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                        .shadow(radius: 2)
                        .frame(maxWidth: .infinity, alignment: .trailing)   // ← RIGHT ALIGNED
                        .padding(.trailing, 8)
                        .padding(.top, 4)

                        // Vertical crosshair
                        Rectangle()
                            .fill(Color.secondary.opacity(0.35))
                            .frame(width: 1)
                            .position(x: dragX, y: geo.size.height / 2)
                    }
                }
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            isDragging = true
                            dragX = value.location.x

                            if let date = approximateDate(atX: value.location.x, width: geo.size.width),
                               let nearest = nearestPoint(to: date) {
                                dragLocation = nearest
                            }
                        }
                        .onEnded { _ in
                            isDragging = false
                            dragLocation = nil
                        }
                )
            }
        }
    }

    private func approximateDate(atX x: CGFloat, width: CGFloat) -> Date? {
        guard !filtered.isEmpty else { return nil }
        guard width > 0 else { return filtered.first?.date }
        let idx = Int((x / width) * CGFloat(filtered.count))
        return filtered.indices.contains(idx) ? filtered[idx].date : nil
    }

    private func nearestPoint(to date: Date) -> PricePoint? {
        filtered.min { abs($0.date.timeIntervalSince(date)) < abs($1.date.timeIntervalSince(date)) }
    }

    private func legendItem(color: Color, title: String) -> some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 7, height: 7)
            Text(title)
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: End of StockPriceChartView.swift
