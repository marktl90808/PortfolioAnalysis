import SwiftUI
import Charts

struct StockChartView: View {
    let priceHistory: [PricePoint]
    let timeRange: ChartTimeRange

    @State private var selectedPoint: PricePoint?

    private var firstClose: Double { priceHistory.first?.close ?? 0 }
    private var lastClose:  Double { priceHistory.last?.close  ?? 0 }
    private var change:     Double { lastClose - firstClose }
    private var changePct:  Double { firstClose > 0 ? (change / firstClose) * 100 : 0 }
    private var chartColor: Color  { change >= 0 ? .green : .red }
    private var minPrice:   Double { (priceHistory.map(\.low).min()  ?? 0) * 0.99 }
    private var maxPrice:   Double { (priceHistory.map(\.high).max() ?? 0) * 1.01 }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Floating data label when dragging
            if let pt = selectedPoint {
                HStack(spacing: 6) {
                    Text(pt.close, format: .currency(code: "USD"))
                        .font(.title3.bold())
                    Text(pt.date, format: .dateTime.month(.abbreviated).day().year())
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            } else {
                HStack(spacing: 6) {
                    Text("\(changePct >= 0 ? "+" : "")\(String(format: "%.2f", changePct))%")
                        .font(.subheadline.bold())
                        .foregroundStyle(chartColor)
                    Text("·")
                        .foregroundStyle(.secondary)
                    Text("H: \(priceHistory.map(\.high).max() ?? 0, format: .currency(code: "USD"))")
                        .font(.caption).foregroundStyle(.secondary)
                    Text("L: \(priceHistory.map(\.low).min() ?? 0, format: .currency(code: "USD"))")
                        .font(.caption).foregroundStyle(.secondary)
                }
            }

            // Chart
            Chart {
                ForEach(priceHistory) { pt in
                    // Area fill
                    AreaMark(
                        x: .value("Date",     pt.date),
                        yStart: .value("Min", minPrice),
                        yEnd:   .value("Close", pt.close)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [chartColor.opacity(0.3), chartColor.opacity(0.04)],
                            startPoint: .top, endPoint: .bottom
                        )
                    )
                    .interpolationMethod(.catmullRom)

                    // Line
                    LineMark(
                        x: .value("Date",  pt.date),
                        y: .value("Close", pt.close)
                    )
                    .foregroundStyle(chartColor)
                    .lineStyle(StrokeStyle(lineWidth: 2))
                    .interpolationMethod(.catmullRom)
                }

                // Selected-point annotation
                if let pt = selectedPoint {
                    RuleMark(x: .value("Selected", pt.date))
                        .foregroundStyle(Color(.systemGray3))
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [5]))

                    PointMark(
                        x: .value("Date",  pt.date),
                        y: .value("Close", pt.close)
                    )
                    .foregroundStyle(chartColor)
                    .symbolSize(64)
                    .annotation(position: .top, overflowResolution: .init(x: .fit, y: .fit)) {
                        Text(pt.close, format: .currency(code: "USD").precision(.fractionLength(2)))
                            .font(.caption.bold())
                            .padding(4)
                            .background(.regularMaterial)
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                    }
                }
            }
            .chartYScale(domain: minPrice...maxPrice)
            .chartXAxis {
                AxisMarks(values: .automatic(desiredCount: xAxisTickCount)) { _ in
                    AxisGridLine()
                    AxisValueLabel(format: xAxisFormat)
                }
            }
            .chartYAxis {
                AxisMarks(position: .trailing, values: .automatic(desiredCount: 4)) { _ in
                    AxisGridLine()
                    AxisValueLabel(format: .currency(code: "USD").precision(.fractionLength(0)))
                }
            }
            .chartOverlay { proxy in
                GeometryReader { geo in
                    Rectangle()
                        .fill(Color.clear)
                        .contentShape(Rectangle())
                        .gesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged { drag in
                                    let x = drag.location.x - geo.frame(in: .local).minX
                                    if let date = proxy.value(atX: x, as: Date.self) {
                                        selectedPoint = priceHistory.min(by: {
                                            abs($0.date.timeIntervalSince(date)) <
                                            abs($1.date.timeIntervalSince(date))
                                        })
                                    }
                                }
                                .onEnded { _ in selectedPoint = nil }
                        )
                }
            }
        }
    }

    private var xAxisTickCount: Int {
        switch timeRange {
        case .oneWeek:                          return 5
        case .oneMonth, .threeMonths:           return 4
        case .sixMonths, .oneYear:              return 4
        case .threeYears, .fiveYears:           return 4
        }
    }

    private var xAxisFormat: Date.FormatStyle {
        switch timeRange {
        case .oneWeek:               return .dateTime.month(.abbreviated).day()
        case .oneMonth:              return .dateTime.month(.abbreviated).day()
        case .threeMonths:           return .dateTime.month(.abbreviated).day()
        case .sixMonths:             return .dateTime.month(.abbreviated).day()
        case .oneYear:               return .dateTime.month(.abbreviated).year(.twoDigits)
        case .threeYears, .fiveYears: return .dateTime.month(.abbreviated).year()
        }
    }
}
