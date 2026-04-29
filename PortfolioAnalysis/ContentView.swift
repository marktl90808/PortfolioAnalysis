import SwiftUI

struct ContentView: View {
    @EnvironmentObject var portfolio: Portfolio

    var body: some View {
        TabView {
            PortfolioListView()
                .tabItem {
                    Label("Portfolio", systemImage: "chart.pie.fill")
                }

            ImportView()
                .tabItem {
                    Label("Import", systemImage: "square.and.arrow.down.fill")
                }

            AnalysisView()
                .tabItem {
                    Label("Analysis", systemImage: "wand.and.stars")
                }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(Portfolio.preview)
}
