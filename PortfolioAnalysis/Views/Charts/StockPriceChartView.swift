//
//  StockPriceChartView.swift
//  PortfolioAnalysis
//

import SwiftUI
import Charts

struct StockPriceChartView: View {
    let history: [PricePoint]
    let range: TimeRange
    let showMA20: Bool      // ignored
    let showMA200: Bool     // ignored
    let referenceHigh: Double?   // ignored for now
    let referenceHighColor: Color
    let quantity: Double    // ignored
    let costBasis: Double?
    let purchaseDate: Date? // ignored for now

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

    // MARK: - Domains (prices only)

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

        // small padding
        maxPrice *= 1.02
        minPrice *= 0.98

        if minPrice >= maxPrice {
            let c = minPrice
            let d = max(c * 0.02, 1)
            return (c - d)...(c + d)
        }

        return minPrice...maxPrice
    }

    // MARK: - Improved performance color logic

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

    // MARK: - Cost basis color

    private var costBasisColor: Color {
        guard let costBasis else { return .clear }
        let last = filtered.last?.close ?? costBasis
        return last >= costBasis ? .green : .red
    }

    var body: some View {
        VStack(spacing: 10) {

            HStack(spacing: 14) {
                legendItem(color: performanceColor, title: "Price")
                if costBasis != nil {
                    legendItem(color: costBasisColor, title: "Cost Basis")
                }
                Spacer()
            }
            .font(.caption2)

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

                            // COST BASIS OVERLAY (does NOT affect domain)
                            if let costBasis {
                                RuleMark(y: .value("Cost Basis", costBasis))
                                    .foregroundStyle(costBasisColor.opacity(blink ? 0.95 : 0.35))
                                    .lineStyle(StrokeStyle(lineWidth: 2, dash: [5, 4]))
                                    .annotation(position: .topLeading, alignment: .leading) {
                                        HStack(spacing: 4) {
                                            Text("Cost")
                                            Text(costBasis, format: .currency(code: currencyCode))
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
                        .padding(.vertical, 8)

                    } else {
                        ProgressView()
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }

                    if let drag = dragLocation {
                        VStack(alignment: .trailing, spacing: 4) {
                            Text(drag.close, format: .currency(code: currencyCode))
                                .font(.caption.bold())
                            Text(drag.date, format: .dateTime.month().day().year())
                                .font(.caption2)
                        }
                        .padding(6)
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                        .shadow(radius: 2)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                        .padding(.trailing, 8)
                        .padding(.top, 4)

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

    // MARK: - Legend

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
