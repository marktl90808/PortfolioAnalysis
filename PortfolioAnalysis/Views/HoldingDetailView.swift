import SwiftUI

struct HoldingDetailView: View {
    let holding: Holding

    @State private var timeRange: ChartTimeRange = .threeMonths
    @State private var priceHistory: [PricePoint] = []
    @State private var isLoading     = false
    @State private var errorMessage: String?

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                headerCard
                if holding.assetType != .cash {
                    chartCard
                }
                positionCard
                if holding.isOptionable {
                    optionsCard
                }
                taxCard
            }
            .padding()
        }
        .navigationTitle(holding.symbol)
        .navigationBarTitleDisplayMode(.large)
        .task { await loadChart() }
        .onChange(of: timeRange) { Task { await loadChart() } }
    }

    // MARK: Header Card

    private var headerCard: some View {
        VStack(spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(holding.name).font(.title3.bold()).lineLimit(2)
                    HStack(spacing: 6) {
                        Label(holding.assetType.rawValue,
                              systemImage: holding.assetType.systemImage)
                        Text("·")
                        Text(holding.accountType.shortName)
                        Text("·")
                        Text(holding.accountName)
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    Text(holding.currentPrice, format: .currency(code: "USD"))
                        .font(.title2.bold())
                    if holding.assetType != .cash {
                        HStack(spacing: 4) {
                            Image(systemName: holding.gainLoss >= 0
                                  ? "arrow.up.right" : "arrow.down.right")
                            Text("\(holding.gainLoss >= 0 ? "+" : "")\(String(format: "%.2f", holding.gainLossPercent))%")
                        }
                        .font(.subheadline.bold())
                        .foregroundStyle(holding.gainLoss >= 0 ? .green : .red)
                    }
                }
            }

            if holding.assetType != .cash {
                HStack(spacing: 6) {
                    MetricPill(title: "Shares",
                               value: "\(holding.shares, specifier: "%.4g")")
                    MetricPill(title: "Avg Cost",
                               value: holding.costBasisPerShare.formatted(.currency(code: "USD")))
                    MetricPill(title: "Mkt Value",
                               value: holding.marketValue.formatted(.currency(code: "USD")))
                    MetricPill(title: "G/L $",
                               value: holding.gainLoss.formatted(.currency(code: "USD")),
                               color: holding.gainLoss >= 0 ? .green : .red)
                }
            }
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: Chart Card

    private var chartCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Price History").font(.headline)

            // Time range picker
            Picker("Range", selection: $timeRange) {
                ForEach(ChartTimeRange.allCases) { r in
                    Text(r.rawValue).tag(r)
                }
            }
            .pickerStyle(.segmented)

            // Chart body
            if isLoading {
                ProgressView("Loading…")
                    .frame(maxWidth: .infinity, minHeight: 200)
            } else if let err = errorMessage {
                ContentUnavailableView(
                    "Chart Unavailable",
                    systemImage: "wifi.slash",
                    description: Text(err)
                )
                .frame(minHeight: 200)
            } else if priceHistory.isEmpty {
                ContentUnavailableView("No Data", systemImage: "chart.line.downtrend.xyaxis")
                    .frame(minHeight: 200)
            } else {
                StockChartView(priceHistory: priceHistory, timeRange: timeRange)
                    .frame(height: 250)
            }
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: Position Card

    private var positionCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Position Details").font(.headline)

            Grid(alignment: .leading, horizontalSpacing: 16, verticalSpacing: 10) {
                GridRow {
                    MetricRow(label: "Symbol",   value: holding.symbol)
                    MetricRow(label: "Account",  value: holding.accountName)
                }
                Divider().gridCellUnsizedAxes(.horizontal)
                GridRow {
                    MetricRow(label: "Account Type", value: holding.accountType.rawValue)
                    MetricRow(label: "Asset Type",   value: holding.assetType.rawValue)
                }
                if holding.assetType != .cash {
                    Divider().gridCellUnsizedAxes(.horizontal)
                    GridRow {
                        MetricRow(label: "Shares",   value: "\(holding.shares, specifier: "%.6g")")
                        MetricRow(label: "Avg Cost", value: holding.costBasisPerShare.formatted(.currency(code: "USD")))
                    }
                    Divider().gridCellUnsizedAxes(.horizontal)
                    GridRow {
                        MetricRow(label: "Cost Basis",
                                  value: holding.costBasis.formatted(.currency(code: "USD")))
                        MetricRow(label: "Market Value",
                                  value: holding.marketValue.formatted(.currency(code: "USD")))
                    }
                    Divider().gridCellUnsizedAxes(.horizontal)
                    GridRow {
                        MetricRow(label: "Gain / Loss $",
                                  value: holding.gainLoss.formatted(.currency(code: "USD")),
                                  color: holding.gainLoss >= 0 ? .green : .red)
                        MetricRow(label: "Gain / Loss %",
                                  value: "\(String(format: "%.2f", holding.gainLossPercent))%",
                                  color: holding.gainLoss >= 0 ? .green : .red)
                    }
                }
            }

            // Signal badge
            if holding.assetType != .cash {
                Divider()
                HStack {
                    Image(systemName: holding.analysisSignal.systemImage)
                    Text(holding.analysisSignal.rawValue)
                        .font(.subheadline.bold())
                }
                .foregroundStyle(signalColor(holding.analysisSignal))
            }
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: Options Card

    private var optionsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Options Strategies for Monthly Income", systemImage: "chart.bar.xaxis.ascending")
                .font(.headline)

            Text("Strategies ranked by suitability based on current gain/loss position.")
                .font(.caption)
                .foregroundStyle(.secondary)

            ForEach(OptionsStrategyEngine.strategies(for: holding), id: \.name) { strategy in
                OptionsStrategyCard(strategy: strategy)
            }
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: Tax Card

    private var taxCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Tax Considerations", systemImage: "doc.text.magnifyingglass")
                .font(.headline)

            if holding.accountType == .traditionalIRA {
                InfoRow(icon: "info.circle", text: "In a Traditional IRA — gains grow tax-deferred. All withdrawals are taxed as ordinary income. No capital gains rates apply.")
                InfoRow(icon: "lightbulb", text: "Required Minimum Distributions (RMDs) begin at age 73.")
            } else {
                InfoRow(icon: "info.circle", text: "In a taxable account — realized gains are subject to capital gains tax.")
                if holding.gainLoss > 0 {
                    InfoRow(icon: "exclamationmark.triangle", text: "Selling would realize a gain of \(holding.gainLoss.formatted(.currency(code: "USD"))). Consider whether you've held >1 year for long-term rates.")
                } else if holding.gainLoss < 0 {
                    InfoRow(icon: "lightbulb", text: "Tax-loss harvesting: selling this position could offset gains elsewhere. Loss: \(abs(holding.gainLoss).formatted(.currency(code: "USD"))).")
                } else {
                    InfoRow(icon: "checkmark.circle", text: "No unrealized gain or loss at this time.")
                }
                InfoRow(icon: "arrow.triangle.2.circlepath", text: "Wash-sale rule: avoid repurchasing the same security within 30 days of selling at a loss.")
            }
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: Helpers

    private func loadChart() async {
        guard holding.assetType != .cash else { return }
        isLoading    = true
        errorMessage = nil
        do {
            priceHistory = try await MarketDataService.shared.fetchPriceHistory(
                symbol: holding.symbol, timeRange: timeRange)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    private func signalColor(_ signal: AnalysisSignal) -> Color {
        switch signal {
        case .considerSelling: return .green
        case .hold:            return .blue
        case .watchClosely:    return .orange
        case .considerExiting: return .red
        case .buyMore:         return .green
        }
    }
}

// MARK: - Reusable sub-views

struct MetricPill: View {
    let title: String
    let value: String
    var color: Color = .primary

    var body: some View {
        VStack(spacing: 2) {
            Text(title).font(.system(size: 9)).foregroundStyle(.secondary)
            Text(value).font(.system(size: 10, weight: .semibold)).foregroundStyle(color)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 6)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

struct MetricRow: View {
    let label: String
    let value: String
    var color: Color = .primary

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label).font(.caption).foregroundStyle(.secondary)
            Text(value).font(.subheadline.bold()).foregroundStyle(color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct InfoRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(width: 16)
            Text(text)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

struct OptionsStrategyCard: View {
    let strategy: OptionsStrategy

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: strategy.systemImage)
                .font(.title3)
                .foregroundStyle(strategy.color)
                .frame(width: 30)

            VStack(alignment: .leading, spacing: 4) {
                Text(strategy.name).font(.subheadline.bold())
                Text(strategy.description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                if let income = strategy.estimatedMonthlyIncome {
                    Text("Est. income: \(income)")
                        .font(.caption.bold())
                        .foregroundStyle(.green)
                }
            }

            Spacer(minLength: 0)

            Text(strategy.suitability.rawValue)
                .font(.caption.bold())
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(strategy.suitability.color.opacity(0.15))
                .foregroundStyle(strategy.suitability.color)
                .clipShape(Capsule())
        }
        .padding(10)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}
