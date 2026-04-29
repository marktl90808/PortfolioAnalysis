//
//  ContentView.swift
//  PortfolioAnalysis
//

import SwiftUI
import Foundation
import Combine

struct ContentView: View {
    @StateObject private var viewModel = PortfolioAnalysisViewModel()

    var body: some View {
        NavigationView {
            ZStack {
                PortfolioListView(viewModel: viewModel)
                    .navigationTitle("Portfolio")
                    .navigationBarTitleDisplayMode(.inline)

                if viewModel.isLoading {
                    loadingOverlay
                        .transition(.opacity)
                        .zIndex(10)
                }
            }
            .animation(.easeInOut(duration: 0.18), value: viewModel.isLoading)
            .task {
                await viewModel.startupLoad()
            }
        }
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

    // Explicit initializer to correctly set the @ObservedObject wrapper
    init(viewModel: PortfolioAnalysisViewModel) {
        self._viewModel = ObservedObject(wrappedValue: viewModel)
    }

    var body: some View {
        VStack(spacing: 16) {
            // Summary header
            HStack {
                VStack(alignment: .leading) {
                    Text("Portfolio Value")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(viewModel.portfolioTotal, format: .currency(code: Locale.current.currencyCode ?? "USD"))
                        .font(.title2.bold())
                }
                Spacer()
            }
            .padding()

            // Analysis results list
            List {
                ForEach(viewModel.analysisResults, id: \.symbol) { result in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(result.symbol)
                                .font(.headline)
                            Text(result.trend.rawValue)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Text(result.currentPrice, format: .currency(code: Locale.current.currencyCode ?? "USD"))
                    }
                    .padding(.vertical, 6)
                }
            }
            .listStyle(PlainListStyle())
        }
    }
}
