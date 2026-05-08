//
//  AddPositionView.swift
//  PortfolioAnalysis
//

import SwiftUI

struct AddPositionView: View {
    @ObservedObject var viewModel: PortfolioAnalysisViewModel
    @Environment(\.dismiss) var dismiss

    @State private var symbol: String = ""
    @State private var quantity: String = ""
    @State private var costBasis: String = ""
    @State private var descriptionText: String = ""
    @State private var purchaseDate: Date = Date()
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            Form {

                Section(header: Text("Symbol")) {
                    TextField("AAPL", text: $symbol)
                        .autocapitalization(.allCharacters)
                }

                Section(header: Text("Quantity")) {
                    TextField("100", text: $quantity)
                        .keyboardType(.decimalPad)
                }

                Section(header: Text("Cost Basis ($)")) {
                    TextField("2500.00", text: $costBasis)
                        .keyboardType(.decimalPad)
                }

                Section(header: Text("Description (optional)")) {
                    TextField("Apple Inc.", text: $descriptionText)
                }

                Section(header: Text("Purchase Date (optional)")) {
                    DatePicker("Date", selection: $purchaseDate, displayedComponents: .date)
                }

                if let error = errorMessage {
                    Section {
                        Text(error)
                            .foregroundColor(.red)
                    }
                }

                Section {
                    Button("Add Position") {
                        addPosition()
                    }
                    .disabled(symbol.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .navigationTitle("Add Position")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    private func addPosition() {
        let trimmed = symbol.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmed.isEmpty else {
            errorMessage = "Symbol cannot be empty."
            return
        }

        let qty = Double(quantity.replacingOccurrences(of: ",", with: "")) ?? 0
        let parsedCost = Double(costBasis.replacingOccurrences(of: ",", with: "")) ?? 0

        // ⭐ NEW: Default account assignment for manual entries
        let defaultAccountNumber = "MANUAL"
        let defaultAccountNickname = "Manual Entry"

        let pos = ImportedPosition(
            symbol: trimmed.uppercased(),
            name: descriptionText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                ? trimmed.uppercased()
                : descriptionText,
            quantity: qty,
            price: 0,                // updated later by market data
            value: 0,                // derived later
            costBasis: parsedCost,
            unitCost: nil,
            purchaseDate: purchaseDate,
            accountNumber: defaultAccountNumber,
            accountNickname: defaultAccountNickname
        )

        viewModel.addManualPosition(pos)
        dismiss()
    }
}
// End of AddPositionView.swift

