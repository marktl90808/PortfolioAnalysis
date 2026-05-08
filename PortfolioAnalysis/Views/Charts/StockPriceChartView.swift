//
//  StockPriceChartView.swift
//  PortfolioAnalysis
//

//
//  StockPriceChartView.swift
//  PortfolioAnalysis
//

import SwiftUI
import Charts

struct StockPriceChartView: View {
    let history: [PricePoint]
    let range: TimeRange
    let showMA20: Bool      // currently unused
    let showMA200: Bool     // currently unused
    let referenceHigh: Double?
    let referenceHighColor: Color
    let quantity: Double
    let costBasis: Double?
    let purchaseDate: Date?
    let unitCost: Double?

    @State private var dragLocation: PricePoint?
    @State private var dragX: CGFloat = 0
    @State private var isDragging = false
    @State private var blink = false

    private var currencyCode: String {
        Locale.current.currency?.identifier ?? "USD"
    }

    // MARK: - Filtered history

    private var filtered: [PricePoint] {
        guard !history.isEmpty else { return [] }
        let sorted = history.sorted { $0.date < $1.date }

        if range == .sincePurchase {
            return sorted
        }

        let now = sorted.last!.date
        let start = range.dateWindow(from: now)
        return sorted.filter { $0.date >= start }
    }

    // MARK: - Domains

    private var xDomain: ClosedRange<Date>? {
        guard let first = filtered.first?.date,
              let last = filtered.last?.date,
              first < last else { return nil }
        return first...last
    }

    private var yDomain: ClosedRange<Double>? {
        let prices = filtered.map(\.close)
        guard !prices.isEmpty else { return nil }

        var minPrice = prices.min()!
        var maxPrice = prices.max()!

        maxPrice *= 1.02
        minPrice *= 0.98

        if minPrice >= maxPrice {
            let c = minPrice
            let d = max(c * 0.02, 1)
            return (c - d)...(c + d)
        }

        return minPrice...maxPrice
    }

    // MARK: - Performance color

    private var performanceColor: Color {
        let closes = filtered.map(\.close)
        guard closes.count >= 2 else { return .gray }

        let first = closes.first!
        let last = closes.last!
        let pct = (last - first) / first

        if pct > 0.0001 { return .green }
        if pct < -0.0001 { return .red }
        return .gray
    }

    var body: some View {
        VStack(spacing: 10) {

            // MARK: - 52WH LABEL ABOVE CHART
            if let high = referenceHigh,
               let highPoint = history.max(by: { $0.close < $1.close }) {

                HStack {
                    Text("52WH:")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text(high, format: .currency(code: currencyCode))
                        .font(.caption.weight(.semibold))

                    Text(highPoint.date, format: .dateTime.month().day())
                        .font(.caption2)
                        .foregroundStyle(.secondary)

                    Spacer()
                }
                .padding(.horizontal, 4)
            }

            // MARK: - UNIT COST LABEL ABOVE CHART
            if let unitCost {
                HStack {
                    Text("Unit Cost:")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text(unitCost, format: .currency(code: currencyCode))
                        .font(.caption.weight(.semibold))

                    if let purchaseDate {
                        Text(purchaseDate, format: .dateTime.month().day().year())
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()
                }
                .padding(.horizontal, 4)
            }

            GeometryReader { geo in
                ZStack {

                    if let xDomain, let yDomain {

                        Chart {

                            // PRICE LINE
                            ForEach(filtered) { p in
                                LineMark(
                                    x: .value("Date", p.date),
                                    y: .value("Price", p.close)
                                )
                                .interpolationMethod(.catmullRom)
                                .foregroundStyle(performanceColor)
                                .lineStyle(StrokeStyle(lineWidth: 2.5))
                            }

                            // 52WH LINE
                            if let high = referenceHigh {
                                RuleMark(y: .value("52WH", high))
                                    .foregroundStyle(referenceHighColor.opacity(0.45))
                                    .lineStyle(StrokeStyle(lineWidth: 3.0, dash: [4, 4]))
                            }

                            // UNIT COST LINE + LABEL
                            if let unitCost {
                                RuleMark(y: .value("Unit Cost", unitCost))
                                    .foregroundStyle(Color.blue.opacity(blink ? 0.95 : 0.35))
                                    .lineStyle(StrokeStyle(lineWidth: 2, dash: [5, 4]))
                                    .annotation(position: .topLeading, alignment: .leading) {
                                        HStack(spacing: 4) {
                                            Text("Unit Cost")
                                            Text(unitCost, format: .currency(code: currencyCode))
                                        }
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                        .padding(4)
                                        .background(.thinMaterial)
                                        .cornerRadius(4)
                                        .offset(x: 2, y: -2)
                                    }
                            }
                        }
                        .chartXScale(domain: xDomain)
                        .chartYScale(domain: yDomain)
                        .chartPlotStyle { plot in
                            plot.padding(.trailing, 32)   // keep line away from Y-axis labels
                        }
                        .chartXAxis {
                            AxisMarks(values: .automatic(desiredCount: 6))
                        }
                        .padding(.vertical, 8)
                        .clipped()                       // prevent drawing under axes

                    } else {
                        ProgressView()
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }

                    // MARK: - TOUCH POPUP
                    if let drag = dragLocation {
                        let positionValue = drag.close * quantity
                        let isLeft = dragX < geo.size.width * 0.5

                        VStack(alignment: isLeft ? .trailing : .leading, spacing: 4) {

                            Text(drag.close, format: .currency(code: currencyCode))
                                .font(.caption.bold())

                            Text(drag.date, format: .dateTime.month().day().year())
                                .font(.caption2)

                            Text(positionValue, format: .currency(code: currencyCode))
                                .font(.caption2.weight(.semibold))
                                .foregroundColor(.secondary)
                        }
                        .padding(6)
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                        .shadow(radius: 2)
                        .frame(maxWidth: .infinity, alignment: isLeft ? .trailing : .leading)
                        .padding(isLeft ? .trailing : .leading, 8)
                        .padding(.top, 4)
                        .zIndex(10)

                        Rectangle()
                            .fill(Color.secondary.opacity(0.35))
                            .frame(width: 1)
                            .position(x: dragX, y: geo.size.height / 2)
                            .zIndex(9)
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
        .onAppear {
            withAnimation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true)) {
                blink = true
            }
        }
    }

    // MARK: - Touch helpers

    private func approximateDate(atX x: CGFloat, width: CGFloat) -> Date? {
        guard !filtered.isEmpty else { return nil }
        guard width > 0 else { return filtered.first?.date }
        let idx = Int((x / width) * CGFloat(filtered.count))
        return filtered.indices.contains(idx) ? filtered[idx].date : nil
    }

    private func nearestPoint(to date: Date) -> PricePoint? {
        filtered.min { abs($0.date.timeIntervalSince(date)) < abs($1.date.timeIntervalSince(date)) }
    }
}
// End of StockPriceChartView.swift

