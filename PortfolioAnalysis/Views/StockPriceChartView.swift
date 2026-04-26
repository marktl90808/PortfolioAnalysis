//
//  StockPriceChartView.swift
//  PortfolioAnalysis
//
//  Created by Mark Leonard on 4/24/2026.
//


import SwiftUI
public extension Comparable {
    func clamped(to range: ClosedRange<Self>) -> Self {
        min(max(self, range.lowerBound), range.upperBound)
    }
}

struct StockPriceChartView: View {
    private let points: [PricePoint]
    @State private var selectedIndex: Int?

    init(points: [PricePoint]) {
        let maxPoints = 300
        if points.count > maxPoints {
            let step = max(points.count / maxPoints, 1)
            self.points = stride(from: 0, to: points.count, by: step).map { points[$0] }
        } else {
            self.points = points
        }
    }

    var body: some View {
        GeometryReader { geometry in
            let size = geometry.size
            let values = points.map(\.close)

            if values.count > 1,
               let minValue = values.min(),
               let maxValue = values.max() {

                let padding = maxValue == minValue ? max(1, abs(maxValue) * 0.01) : 0
                let plottedMin = minValue - padding
                let plottedMax = maxValue + padding

                let linePoints = chartPoints(
                    in: size,
                    minValue: plottedMin,
                    maxValue: plottedMax
                )

                let selectedPoint = selectedIndex.flatMap { index -> ChartSelection? in
                    guard linePoints.indices.contains(index),
                          points.indices.contains(index) else { return nil }
                    return ChartSelection(point: points[index], location: linePoints[index])
                }

                let gesture = DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        selectedIndex = nearestIndex(
                            for: value.location.x,
                            width: size.width,
                            count: linePoints.count
                        )
                    }
                    .onEnded { _ in
                        selectedIndex = nil
                    }

                ZStack {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color(.systemBackground))

//                    gridLines(in: size, minValue: plottedMin, maxValue: plottedMax)

                    Path { path in
                        guard let first = linePoints.first else { return }
                        path.move(to: first)
                        for p in linePoints.dropFirst() { path.addLine(to: p) }
                    }
                    .stroke(Color.blue, lineWidth: 2.5)

                    areaFillPath(points: linePoints, height: size.height)
                        .fill(
                            LinearGradient(
                                colors: [Color.blue.opacity(0.30), Color.blue.opacity(0.03)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )

//                    edgeLabels(maxValue: plottedMax, minValue: plottedMin)

                    if let selected = selectedPoint {
                        crosshair(for: selected, height: size.height)
                        selectionDot(at: selected.location)
                        valueTooltip(for: selected, in: size)
                    }
                }
                .gesture(gesture)
            }
        }
    }

    // MARK: - Chart Math

    private func chartPoints(in size: CGSize, minValue: Double, maxValue: Double) -> [CGPoint] {
        let range = maxValue - minValue
        let stepX = size.width / CGFloat(max(points.count - 1, 1))

        return points.enumerated().map { index, point in
            let x = CGFloat(index) * stepX
            let yRatio = (point.close - minValue) / range
            let y = size.height - CGFloat(yRatio) * size.height
            return CGPoint(x: x, y: y)
        }
    }

    private func nearestIndex(for x: CGFloat, width: CGFloat, count: Int) -> Int {
        let step = width / CGFloat(max(count - 1, 1))
        return Int((x / step).rounded()).clamped(to: 0...(count - 1))
    }

    // MARK: - Drawing Helpers

    private func gridLines(in size: CGSize, minValue: Double, maxValue: Double) -> some View {
        let mid = (minValue + maxValue) / 2
        return VStack {
            Text(maxValue.formatted())
                .font(.caption2)
                .foregroundColor(.secondary)
            Spacer()
            Text(mid.formatted())
                .font(.caption2)
                .foregroundColor(.secondary)
            Spacer()
            Text(minValue.formatted())
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.leading, 4)
    }

    private func areaFillPath(points: [CGPoint], height: CGFloat) -> Path {
        Path { path in
            guard let first = points.first else { return }
            path.move(to: CGPoint(x: first.x, y: height))
            path.addLine(to: first)
            for p in points.dropFirst() { path.addLine(to: p) }
            if let last = points.last {
                path.addLine(to: CGPoint(x: last.x, y: height))
            }
            path.closeSubpath()
        }
    }

    private func edgeLabels(maxValue: Double, minValue: Double) -> some View {
        VStack {
            Text(maxValue.formatted())
                .font(.caption2)
                .foregroundColor(.secondary)
            Spacer()
            Text(minValue.formatted())
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(.leading, 4)
    }

    private func crosshair(for selection: ChartSelection, height: CGFloat) -> some View {
        Path { path in
            path.move(to: CGPoint(x: selection.location.x, y: 0))
            path.addLine(to: CGPoint(x: selection.location.x, y: height))
        }
        .stroke(Color.gray.opacity(0.4), lineWidth: 1)
    }

    private func selectionDot(at point: CGPoint) -> some View {
        Circle()
            .fill(Color.blue)
            .frame(width: 10, height: 10)
            .position(point)
    }

    private func valueTooltip(for selection: ChartSelection, in size: CGSize) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(selection.point.date.formatted(date: .abbreviated, time: .omitted))
                .font(.caption2)
            Text(selection.point.close.formatted(.currency(code: "USD")))
                .font(.caption2.bold())
        }
        .padding(6)
        .background(Color(.systemBackground))
        .cornerRadius(6)
        .shadow(radius: 2)
        .position(
            x: min(max(selection.location.x + 60, 60), size.width - 60),
            y: selection.location.y - 40
        )
    }
}
