import SwiftUI
import Charts

struct StockPriceChartView: View {
    let history: [PricePoint]
    let range: TimeRange
    let showMA20: Bool
    let showMA200: Bool

    @State private var dragLocation: PricePoint?
    @State private var isDragging = false

    private var filtered: [PricePoint] {
        guard !history.isEmpty else { return [] }
        let sorted = history.sorted { $0.date < $1.date }
        let now = sorted.last!.date
        let start = range.dateWindow(from: now)

        // Auto density detection
        let grouped = Dictionary(grouping: sorted) { Calendar.current.startOfDay(for: $0.date) }
        let isIntraday = grouped.values.contains { $0.count > 5 }

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

    var body: some View {
        ZStack {
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

                // Crosshair
                if let drag = dragLocation {
                    RuleMark(x: .value("Drag", drag.date))
                        .foregroundStyle(.gray.opacity(0.4))

                    PointMark(
                        x: .value("Drag", drag.date),
                        y: .value("Price", drag.close)
                    )
                    .foregroundStyle(.white)
                    .symbolSize(40)
                    .annotation(position: .top) {
                        Text("\(drag.close, format: .currency(code: Locale.current.currencyCode ?? "USD"))")
                            .font(.caption)
                            .padding(6)
                            .background(.ultraThinMaterial)
                            .cornerRadius(6)
                    }
                }
            }
            .chartXAxis(.hidden)
            .chartYAxis(.hidden)
            .padding(.vertical, 8)
            .gesture(
                DragGesture()
                    .onChanged { value in
                        isDragging = true
                        if let date = approximateDate(atX: value.location.x),
                           let nearest = nearestPoint(to: date) {
                            dragLocation = nearest
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        }
                    }
                    .onEnded { _ in
                        isDragging = false
                        dragLocation = nil
                    }
            )
        }
    }

    private func approximateDate(atX x: CGFloat) -> Date? {
        guard !filtered.isEmpty else { return nil }
        let idx = Int((x / UIScreen.main.bounds.width) * CGFloat(filtered.count))
        return filtered.indices.contains(idx) ? filtered[idx].date : nil
    }

    private func nearestPoint(to date: Date) -> PricePoint? {
        filtered.min { abs($0.date.timeIntervalSince(date)) < abs($1.date.timeIntervalSince(date)) }
    }
}
