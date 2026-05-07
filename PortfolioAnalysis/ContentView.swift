//
//  ContentView.swift
//  PortfolioAnalysis
//

import SwiftUI
import Foundation
import Combine

struct ContentView: View {
    @StateObject private var viewModel = PortfolioAnalysisViewModel()
    @State private var showingImportSheet = false
    @State private var showingAnalysisSheet = false
    @State private var showingComparisonSheet = false
    @State private var editMode: EditMode = .inactive
    @State private var showingAddPosition = false

    var body: some View {
        NavigationStack {
            ZStack {
                if viewModel.positions.isEmpty {
                    emptyStateView
                } else {
                    PortfolioListView(
                        viewModel: viewModel,
                        onViewAnalysis: { showingAnalysisSheet = true },
                        onCompareCharts: { showingComparisonSheet = true }
                    )
                }

                if viewModel.isLoading {
                    loadingOverlay
                        .transition(.opacity)
                        .zIndex(10)
                }
            }
            .navigationTitle("Portfolio")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {

                ToolbarItem(placement: .topBarTrailing) {
                    Button("Import Portfolio") {
                        showingImportSheet = true
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Text("Refresh")
                        .foregroundColor(.accentColor)
                        .onTapGesture {
                            Task { await viewModel.refreshMarketData() }
                        }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Text("Add Symbol")
                        .foregroundColor(.accentColor)
                        .onTapGesture { showingAddPosition = true }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Text(editMode.isEditing ? "Done" : "Edit")
                        .foregroundColor(.accentColor)
                        .onTapGesture {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                editMode = editMode.isEditing ? .inactive : .active
                            }
                        }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        NavigationLink("About This System") {
                            AboutThisSystemView()
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .imageScale(.large)
                    }
                }
            }

            .sheet(isPresented: $showingImportSheet) {
                PasteImportView(viewModel: viewModel)
            }
            .sheet(isPresented: $showingAnalysisSheet) {
                NavigationStack {
                    AnalysisResultsView(viewModel: viewModel)
                }
            }
            .sheet(isPresented: $showingComparisonSheet) {
                NavigationStack {
                    MultiSymbolComparisonView(viewModel: viewModel)
                }
            }
            .sheet(isPresented: $showingAddPosition) {
                AddPositionView(viewModel: viewModel)
            }
            .animation(.easeInOut(duration: 0.18), value: viewModel.isLoading)
            .task {
                await viewModel.startupLoad()
            }
            .environment(\.editMode, $editMode)
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 18) {
            Image(systemName: "square.and.arrow.down")
                .font(.system(size: 44, weight: .semibold))
                .foregroundColor(.accentColor)

            VStack(spacing: 8) {
                Text("Import your portfolio")
                    .font(.title2.bold())

                Text("Paste your brokerage table or choose a file to analyze your holdings.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }

            Button {
                showingImportSheet = true
            } label: {
                Label("Import Portfolio", systemImage: "doc.on.doc")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)

            Text("Your saved portfolio will appear here after import.")
                .font(.footnote)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(24)
        .background(.ultraThinMaterial)
        .cornerRadius(16)
        .shadow(radius: 8)
        .padding(.horizontal, 24)
    }

    private var loadingOverlay: some View {
        VStack(spacing: 12) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle())
                .scaleEffect(1.2)

            Text("Loading… Please wait.")
                .font(.headline)
                .foregroundColor(.secondary)
        }
        .padding(18)
        .background(.ultraThinMaterial)
        .cornerRadius(12)
        .shadow(radius: 8)
        .padding(.horizontal, 40)
    }
}

// MARK: - PortfolioListView
struct PortfolioListView: View {
    @ObservedObject var viewModel: PortfolioAnalysisViewModel
    let onViewAnalysis: () -> Void
    let onCompareCharts: () -> Void

    private var currencyCode: String {
        Locale.current.currency?.identifier ?? "USD"
    }

    init(viewModel: PortfolioAnalysisViewModel) {
        self._viewModel = ObservedObject(wrappedValue: viewModel)
        self.onViewAnalysis = {}
        self.onCompareCharts = {}
    }

    init(
        viewModel: PortfolioAnalysisViewModel,
        onViewAnalysis: @escaping () -> Void,
        onCompareCharts: @escaping () -> Void
    ) {
        self._viewModel = ObservedObject(wrappedValue: viewModel)
        self.onViewAnalysis = onViewAnalysis
        self.onCompareCharts = onCompareCharts
    }

    var body: some View {
        VStack(spacing: 16) {

            // MARK: - Portfolio Header with Cash (Option C)
            VStack(alignment: .leading, spacing: 4) {

                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Portfolio Value")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Text(viewModel.portfolioTotal, format: .currency(code: currencyCode))
                            .font(.title3.bold())
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 2) {
                        Text("Cash")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Text(viewModel.cashTotal, format: .currency(code: currencyCode))
                            .font(.headline.weight(.semibold))
                            .foregroundColor(.blue)
                    }
                }

                // Day Change
                HStack(spacing: 6) {
                    let change = viewModel.dayChangeTotal
                    let percent = viewModel.portfolioTotal > 0
                        ? change / (viewModel.portfolioTotal - change)
                        : 0

                    Text(change, format: .currency(code: currencyCode))
                    Text(percent, format: .percent.precision(.fractionLength(2)))
                }
                .font(.footnote.weight(.semibold))
                .foregroundColor(viewModel.dayChangeTotal < 0 ? .red : .green)
            }
            .padding(.horizontal)
            .contentShape(Rectangle())
            .onTapGesture {
                Task { await viewModel.refreshMarketData() }
            }

            // MARK: - Action Buttons
            VStack(spacing: 0) {
                actionLink(
                    title: "View Analysis",
                    systemImage: "list.bullet.rectangle"
                ) {
                    onViewAnalysis()
                }

                Divider()

                actionLink(
                    title: "Compare Charts",
                    systemImage: "chart.line.uptrend.xyaxis"
                ) {
                    onCompareCharts()
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 2)
            .background(Color.primary.opacity(0.04))
            .clipShape(RoundedRectangle(cornerRadius: 12))

            // MARK: - Positions List (Cash Hidden)
            List {
                ForEach(viewModel.analysisResults.filter { !$0.isCash }, id: \.symbol) { result in
                    NavigationLink(
                        destination: StockDetailView(
                            initialSymbol: result.symbol,
                            viewModel: viewModel
                        )
                    ) {
                        HStack {
                            VStack(alignment: .leading) {
                                Text(result.symbol)
                                    .font(.headline)

                                ClassificationBadgeView(classification: result.classification)
                            }

                            Spacer()
                            Text(result.currentPrice, format: .currency(code: currencyCode))
                        }
                        .padding(.vertical, 6)
                    }
                }
                .onDelete { indexSet in
                    for index in indexSet {
                        let symbol = viewModel.analysisResults.filter { !$0.isCash }[index].symbol
                        viewModel.removePosition(symbol: symbol)
                    }
                }
            }
            .listStyle(PlainListStyle())
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
    }

    private func actionLink(title: String, systemImage: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Label(title, systemImage: systemImage)
                    .font(.callout.weight(.semibold))
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 11)
            .padding(.horizontal, 6)
        }
        .buttonStyle(.plain)
        .foregroundColor(.accentColor)
    }
}
