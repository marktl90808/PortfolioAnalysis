//
//  SymbolSeries.swift
//  PortfolioAnalysis
//
//  Created by Mark Leonard on 4/28/2026.
//
import Foundation
import SwiftUI
import Charts

struct SymbolSeries: Identifiable {
    let id = UUID()
    let symbol: String
    let history: [PricePoint]
    let color: Color
}

struct MultiSymbolStockChartView: View {
    let series: [SymbolSeries]
    let range: TimeRange

    @State private var dragDate: Date?
    @State private var isDragging = false

    private var filteredSeries: [(symbol: String, points: [PricePoint])] {
        series.compactMap { s in
            let sorted = s.history.sorted { $0.date < $1.date }
            guard !sorted.isEmpty else { return nil }
            let now = sorted.last!.date
            let start = range.dateWindow(from: now)
            let filtered = sorted.filter { $0.date >= start }
            guard filtered.count > 1 else { return nil }
            return (s.symbol, filtered)
        }
    }

    private func normalized(_ points: [PricePoint]) -> [PricePoint] {
        guard let first = points.first?.close else { return points }
        return points.map { p in
            let pct = (p.close - first) / first * 100
            return PricePoint(date: p.date, close: pct)
        }
    }

    private let palette: [Color] = [.blue, .green, .orange, .purple, .pink, .teal, .red]

    var body: some View {
        ZStack {
            Chart {
                ForEach(Array(filteredSeries.enumerated()), id: \.element.symbol) { index, entry in
                    let color = series.first(where: { $0.symbol == entry.symbol })?.color ?? palette[index % palette.count]
                    let norm = normalized(entry.points)

                    ForEach(norm) { p in
                        LineMark(
                            x: .value("Date", p.date),
                            y: .value("%", p.close)
                        )
                        .interpolationMethod(.catmullRom)
                        .foregroundStyle(color)
                        .lineStyle(StrokeStyle(lineWidth: 2))
                    }

                    if let dragDate,
                       let nearest = nearestPoint(in: norm, to: dragDate) {
                        RuleMark(x: .value("Drag", dragDate))
                            .foregroundStyle(.gray.opacity(0.3))

                        PointMark(
                            x: .value("Drag", nearest.date),
                            y: .value("%", nearest.close)
                        )
                        .foregroundStyle(.white)
                        .symbolSize(40)
                        .annotation(position: .top) {
                            VStack(spacing: 2) {
                                Text(entry.symbol)
                                    .font(.caption2.bold())
                                Text(String(format: "%.2f%%", nearest.close))
                                    .font(.caption2)
                            }
                            .padding(6)
                            .background(.ultraThinMaterial)
                            .cornerRadius(6)
                        }
                    }
                }
            }
            .chartXAxis(.hidden)
            .chartYAxis {
                AxisMarks(position: .leading) {
                    AxisGridLine()
                }
            }
            .padding(.vertical, 8)
            .chartOverlay { proxy in
                GeometryReader { geo in
                    Rectangle()
                        .fill(.clear)
                        .contentShape(Rectangle())
                        .gesture(
                            DragGesture()
                                .onChanged { value in
                                    isDragging = true
                                    if let date = approximateDate(atX: value.location.x, width: geo.size.width) {
                                        dragDate = date
                                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                    }
                                }
                                .onEnded { _ in
                                    isDragging = false
                                    dragDate = nil
                                }
                        )
                }
            }
        }
    }

    private func approximateDate(atX x: CGFloat, width: CGFloat) -> Date? {
        guard let firstSeries = filteredSeries.first?.points else { return nil }
        guard width > 0 else { return nil }
        let idx = Int((x / width) * CGFloat(firstSeries.count))
        return firstSeries.indices.contains(idx) ? firstSeries[idx].date : nil
    }

    private func nearestPoint(in points: [PricePoint], to date: Date) -> PricePoint? {
        points.min(by: {
            abs($0.date.timeIntervalSince(date)) < abs($1.date.timeIntervalSince(date))
        })
    }
}
