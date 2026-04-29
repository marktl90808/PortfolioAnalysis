//
//  EditPositionView.swift
//  PortfolioAnalysis
//

import SwiftUI

struct EditPositionView: View {
    @ObservedObject var viewModel: PortfolioAnalysisViewModel
    let position: ImportedPosition

    @Environment(\.dismiss) private var dismiss
    @State private var symbol: String
    @State private var quantity: String
    @State private var costBasis: String

    init(viewModel: PortfolioAnalysisViewModel, position: ImportedPosition) {
        self._viewModel = ObservedObject(wrappedValue: viewModel)
        self.position = position
        self._symbol = State(initialValue: position.symbol)
        self._quantity = State(initialValue: String(position.quantity))
        self._costBasis = State(initialValue: position.costBasis.map { String($0) } ?? "")
    }

    var body: some View {
        Form {
            Section("Holding") {
                TextField("Symbol", text: $symbol)
                TextField("Quantity", text: $quantity)
                    .keyboardType(.decimalPad)
                TextField("Cost Basis", text: $costBasis)
                    .keyboardType(.decimalPad)
            }

            Section {
                Button("Save") {
                    saveChanges()
                    dismiss()
                }

                Button("Cancel", role: .cancel) {
                    dismiss()
                }
            }
        }
        .navigationTitle("Edit Position")
    }

    private func saveChanges() {
        let trimmedSymbol = symbol.trimmingCharacters(in: .whitespacesAndNewlines)
        let symbolToUse = trimmedSymbol.isEmpty ? position.symbol : trimmedSymbol
        let qty = Double(quantity.trimmingCharacters(in: .whitespacesAndNewlines)) ?? position.quantity

        if symbolToUse != position.symbol {
            viewModel.updateSymbol(for: position.symbol, newSymbol: symbolToUse)
        }

        viewModel.updateQuantity(for: symbolToUse, newQuantity: qty)

        if let parsedCost = Double(costBasis.trimmingCharacters(in: .whitespacesAndNewlines)) {
            viewModel.updateCostBasis(for: symbolToUse, newCostBasis: parsedCost)
        }
    }
}

