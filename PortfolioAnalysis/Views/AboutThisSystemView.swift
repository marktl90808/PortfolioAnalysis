//
//  AboutThisSystemView.swift
//  PortfolioAnalysis
//
//  Created by Mark Leonard on 5/4/2026.
//


//
//  AboutThisSystemView.swift
//  PortfolioAnalysis
//

import SwiftUI

struct AboutThisSystemView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {

                // Title
                VStack(alignment: .leading, spacing: 6) {
                    Text("About This System")
                        .font(.largeTitle.bold())

                    Text("Why this app exists — and why it’s different.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                // Core philosophy
                section(
                    title: "The Core Philosophy",
                    content: """
                    Most portfolio apps show you numbers. This one shows you meaning.

                    Your portfolio isn’t just a list of stocks. It’s a collection of opportunities, risks, and strategies — each one different depending on the account it lives in, the number of shares you own, the volatility of the stock, the trend, your cost basis, and your break-even price.

                    This system evaluates all of that automatically. It doesn’t just show you data. It interprets it, classifies it, and guides you.
                    """
                )

                // Classification engine
                section(
                    title: "The “Now You Know” Classification Engine",
                    content: """
                    Every position in your portfolio is assigned a clear, unambiguous identity:

                    • Income Engine
                    • Income Candidate
                    • IRA Income Engine
                    • IRA Growth Position
                    • Repair Candidate
                    • Leave Alone

                    No ambiguity. No “maybe.” No “it depends.” Just: now you know.
                    """
                )

                // Why this matters
                section(
                    title: "Why This Matters",
                    content: """
                    Different positions require different strategies.

                    Some can generate weekly income. Some need repair. Some should be left alone. Some are ideal for long-term growth or tax-free compounding. Some are stepping stones toward 100 shares. Some are income engines waiting to be activated.

                    When you know which is which, you stop guessing and start acting.
                    """
                )

                // What comes next
                section(
                    title: "What Comes Next",
                    content: """
                    This page is the beginning. Behind it are deeper layers that build on this foundation:

                    • How You’ll Benefit
                    • Why We Designed It This Way
                    • Classification Meaning Guide
                    • Onboarding Walkthrough

                    Think of them as chapters in a book — each one deepening your understanding and sharpening your decisions.
                    """
                )

                // Back to the heart of the app
                section(
                    title: "Back to the Heart of the App",
                    content: """
                    This system exists to support the real work:

                    • Income generation
                    • Portfolio analysis
                    • Position repair
                    • Break-even optimization
                    • Trend and velocity evaluation
                    • Cost basis intelligence
                    • Weekly opportunity scanning

                    Your portfolio shouldn’t just sit there. It should work for you.
                    """
                )
            }
            .padding()
        }
        .navigationTitle("About This System")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Helpers

    private func section(title: String, content: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)

            Text(content)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }
}
