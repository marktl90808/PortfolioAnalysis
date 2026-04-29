import SwiftUI

struct ImportView: View {
    @EnvironmentObject var portfolio: Portfolio
    @State private var pastedText    = ""
    @State private var parseResult: ParseResult?
    @State private var showPreview   = false
    @State private var showSuccess   = false
    @State private var showHelp      = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Instruction banner
                HStack(spacing: 10) {
                    Image(systemName: "doc.text.below.ecg")
                        .font(.title2)
                        .foregroundStyle(.blue)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Paste Tab-Separated Data")
                            .font(.headline)
                        Text("Copy from your brokerage and paste below.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }
                .padding()
                .background(.regularMaterial)

                // Text editor
                ZStack(alignment: .topLeading) {
                    TextEditor(text: $pastedText)
                        .font(.system(.caption, design: .monospaced))
                        .padding(6)

                    if pastedText.isEmpty {
                        Text(placeholderText)
                            .font(.system(.caption, design: .monospaced))
                            .foregroundStyle(.tertiary)
                            .padding(10)
                            .allowsHitTesting(false)
                    }
                }
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color(.systemGray4), lineWidth: 1)
                )
                .padding()

                // Buttons
                HStack(spacing: 12) {
                    Button(role: .destructive) {
                        pastedText   = ""
                        parseResult  = nil
                    } label: {
                        Label("Clear", systemImage: "trash")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .disabled(pastedText.isEmpty)

                    Button {
                        parseResult = PortfolioParser.parse(pastedText)
                        showPreview = true
                    } label: {
                        Label("Preview & Import", systemImage: "eye")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(pastedText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
                .padding([.horizontal, .bottom])
            }
            .navigationTitle("Import")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showHelp = true } label: {
                        Image(systemName: "questionmark.circle")
                    }
                }
            }
            .sheet(isPresented: $showPreview) {
                if let result = parseResult {
                    ImportPreviewView(result: result) {
                        portfolio.importHoldings(result.holdings)
                        showPreview  = false
                        pastedText   = ""
                        parseResult  = nil
                        withAnimation { showSuccess = true }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                            withAnimation { showSuccess = false }
                        }
                    }
                }
            }
            .sheet(isPresented: $showHelp) {
                ImportHelpView()
            }
            .overlay(alignment: .bottom) {
                if showSuccess {
                    successBanner
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .padding(.bottom, 20)
                }
            }
        }
    }

    // MARK: - Sub-views

    private var successBanner: some View {
        HStack(spacing: 10) {
            Image(systemName: "checkmark.circle.fill")
            Text("Portfolio imported successfully!")
                .bold()
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .background(Color.green)
        .clipShape(Capsule())
        .shadow(radius: 6)
    }

    private let placeholderText =
        "Symbol\tName\tShares\tCost/Share\tLast Price\tAccount\tAccount Type\tType\n" +
        "AAPL\tApple Inc.\t100\t150.00\t185.50\tBrokerage\tNon-IRA\tStock\n" +
        "VOO\tVanguard S&P 500\t40\t350.00\t480.00\tIRA\tTraditional IRA\tETF"
}

// MARK: - Import Preview Sheet

struct ImportPreviewView: View {
    let result: ParseResult
    let onConfirm: () -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                if !result.errors.isEmpty {
                    Section {
                        ForEach(result.errors, id: \.self) { msg in
                            Label(msg, systemImage: "exclamationmark.triangle.fill")
                                .font(.caption)
                                .foregroundStyle(.orange)
                        }
                    } header: {
                        Text("Warnings")
                    }
                }

                Section {
                    ForEach(result.holdings) { h in
                        HStack(spacing: 12) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(h.symbol).font(.headline)
                                Text(h.name).font(.caption).foregroundStyle(.secondary).lineLimit(1)
                            }
                            Spacer()
                            VStack(alignment: .trailing, spacing: 2) {
                                Text(h.marketValue, format: .currency(code: "USD"))
                                    .font(.subheadline)
                                Text("\(h.shares, specifier: "%.4g") shares")
                                    .font(.caption).foregroundStyle(.secondary)
                            }
                        }
                    }
                } header: {
                    Text("\(result.holdings.count) Holdings to Import")
                }

                if result.skippedRows > 0 {
                    Section {
                        Text("\(result.skippedRows) row(s) skipped (blank or unreadable)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Preview Import")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Import") { onConfirm() }
                        .buttonStyle(.borderedProminent)
                        .disabled(result.holdings.isEmpty)
                }
            }
        }
    }
}

// MARK: - Help Sheet

struct ImportHelpView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {

                    Group {
                        Text("Expected Columns")
                            .font(.headline)
                        Text("The first row must be a header. Columns can be in any order.")
                            .foregroundStyle(.secondary)
                            .font(.subheadline)

                        ForEach(columns, id: \.name) { col in
                            VStack(alignment: .leading, spacing: 2) {
                                Text(col.name).bold()
                                Text(col.desc).font(.caption).foregroundStyle(.secondary)
                            }
                        }
                    }

                    Divider()

                    Group {
                        Text("Example Data")
                            .font(.headline)
                        ScrollView(.horizontal, showsIndicators: false) {
                            Text(exampleText)
                                .font(.system(.caption, design: .monospaced))
                                .padding(10)
                                .background(Color(.systemGray6))
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                    }

                    Divider()

                    Group {
                        Text("Tips")
                            .font(.headline)
                        ForEach(tips, id: \.self) { tip in
                            Label(tip, systemImage: "checkmark.circle.fill")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Import Help")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private struct ColInfo: Identifiable {
        let id = UUID()
        let name: String
        let desc: String
    }

    private let columns: [ColInfo] = [
        ColInfo(name: "Symbol",       desc: "Ticker symbol, e.g. AAPL, VOO, VTSAX"),
        ColInfo(name: "Name",         desc: "Security name (optional)"),
        ColInfo(name: "Shares",       desc: "Number of shares / units held"),
        ColInfo(name: "Cost/Share",   desc: "Average cost basis per share"),
        ColInfo(name: "Last Price",   desc: "Current market price per share"),
        ColInfo(name: "Account",      desc: "Account name, e.g. 'Fidelity Brokerage'"),
        ColInfo(name: "Account Type", desc: "'Non-IRA' or 'Traditional IRA'"),
        ColInfo(name: "Type",         desc: "Stock, ETF, Mutual Fund, or Cash"),
    ]

    private let exampleText =
        "Symbol\tName\tShares\tCost/Share\tLast Price\tAccount\tAccount Type\tType\n" +
        "AAPL\tApple Inc.\t100\t150.00\t185.50\tFidelity\tNon-IRA\tStock\n" +
        "VOO\tVanguard S&P 500\t40\t350.00\t480.00\tFidelity IRA\tTraditional IRA\tETF\n" +
        "VTSAX\tVanguard Total Mkt\t200\t95.00\t115.00\tSchwab IRA\tTraditional IRA\tMutual Fund\n" +
        "CASH\tCash\t1\t5000.00\t5000.00\tFidelity\tNon-IRA\tCash"

    private let tips: [String] = [
        "Copy directly from Fidelity, Schwab, E*TRADE, or any brokerage CSV export.",
        "Dollar signs and commas in numbers are handled automatically.",
        "You can have multiple accounts in the same file.",
        "Up to 4 or more accounts are supported.",
        "Importing replaces all current holdings.",
    ]
}
