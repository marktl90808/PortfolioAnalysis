import SwiftUI

@main
struct PortfolioAnalysisApp: App {
    @StateObject private var portfolio = Portfolio()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(portfolio)
        }
    }
}
