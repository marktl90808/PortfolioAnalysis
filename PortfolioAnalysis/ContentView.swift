//
//  ContentView.swift
//  PortfolioAnalysis
//

import SwiftUI

struct ContentView: View {

    @StateObject private var viewModel = PortfolioAnalysisViewModel()

    var body: some View {
        NavigationStack {
            PortfolioAnalysisView(viewModel: viewModel)
        }
    }
}

#Preview {
    ContentView()
}
