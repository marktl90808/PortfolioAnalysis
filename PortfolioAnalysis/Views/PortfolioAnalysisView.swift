//
//  PortfolioAnalysisView.swift
//  PortfolioAnalysis
//

import SwiftUI
import UniformTypeIdentifiers

struct PortfolioAnalysisView: View {
    @ObservedObject var viewModel: PortfolioAnalysisViewModel

    @State private var showingImporter = false
    @State private var showPasteSheet = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {

                    // MARK: - Primary Actions
                    VStack(spacing: 12) {
                        Button {
                            showingImporter = true
                        } label: {
                            Label("Import Portfolio (CSV)", systemImage: "tray.and.arrow.down")
                        }
                        .buttonStyle(.borderedProminent)

                        Button {
                            showPasteSheet = true
                        } label: {
                            Label("Paste Portfolio Data", systemImage: "doc.on.clipboard")
                        }
                        .buttonStyle(.bordered)
                    }
                    .padding(.top, 8)

                    // MARK: - Empty State
                    if viewModel.positions.isEmpty && viewModel.errorMessage == nil {
                        VStack(spacing: 12) {
                            Text("No portfolio loaded")
                                .font(.headline)
                                .foregroundColor(.secondary)

                            Text("Import a CSV file or paste your portfolio data to get started.")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.top, 20)
                    }

                    // MARK: - Error State
                    if let error = viewModel.errorMessage {
                        VStack(spacing: 12) {
                            Text(error)
                                .foregroundColor(.red)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)

                            Button("Clear Error") {
                                viewModel.resetState()
                            }
                            .buttonStyle(.bordered)
                        }
                        .padding(.vertical)
                    }

                    // MARK: - Totals
                    if !viewModel.positions.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {

                            HStack {
                                Text("Portfolio Total")
                                    .font(.headline)
                                Spacer()
                                Text(viewModel.portfolioTotal, format: .currency(code: "USD"))
                                    .font(.title3.bold())
                            }

                            HStack {
                                Text("Cash Total")
                                Spacer()
                                Text(viewModel.cashTotal, format: .currency(code: "USD"))
                            }

                            HStack {
                                Text("Growth (Unrealized)")
                                Spacer()
                                Text(viewModel.totalGrowth, format: .currency(code: "USD"))
                                    .foregroundColor(viewModel.totalGrowth >= 0 ? .green : .red)
                            }

                            HStack {
                                Text("Day Change")
                                Spacer()
                                Text(viewModel.dayChangeTotal, format: .currency(code: "USD"))
                                    .foregroundColor(viewModel.dayChangeTotal >= 0 ? .green : .red)
                            }
                        }
                        .padding()
                        .background(Color.blue.opacity(0.08))
                        .cornerRadius(12)
                        .padding(.horizontal)
                    }

                    // MARK: - Imported Positions
                    if !viewModel.positions.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Imported Positions")
                                .font(.title3.bold())
                                .padding(.bottom, 4)

                            ForEach(viewModel.positions) { position in
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(position.symbol)
                                            .font(.headline)

                                        if !position.name.isEmpty {
                                            Text(position.name)
                                                .font(.subheadline)
                                                .foregroundColor(.secondary)
                                        }

                                        HStack(spacing: 16) {
                                            Text("Qty: \(position.quantity, specifier: "%.4f")")
                                            Text("Price: \(position.price, format: .currency(code: "USD"))")
                                        }
                                        .font(.caption)
                                        .foregroundColor(.secondary)

                                        Text("Value: \(position.value, format: .currency(code: "USD"))")
                                            .font(.caption)
                                            .foregroundColor(.secondary)

                                        if let cost = position.costBasis {
                                            Text("Cost Basis: \(cost, format: .currency(code: "USD"))")
                                                .font(.caption2)
                                                .foregroundColor(.secondary)
                                        }
                                    }

                                    Spacer()
                                }
                                .padding(.vertical, 6)

                                Divider()
                            }
                        }
                        .padding(.horizontal)
                    }

                    Spacer()
                }
                .padding(.top)
            }
            .navigationTitle("Portfolio Analysis")
            .fileImporter(
                isPresented: $showingImporter,
                allowedContentTypes: [.commaSeparatedText, .plainText, .data],
                allowsMultipleSelection: false
            ) { result in
                switch result {
                case .success(let urls):
                    if let url = urls.first {
                        viewModel.importFile(url: url)
                    }
                case .failure(let error):
                    print("Import failed: \(error.localizedDescription)")
                }
            }
            .sheet(isPresented: $showPasteSheet) {
                PasteImportView(viewModel: viewModel)
            }
        }
    }
}
