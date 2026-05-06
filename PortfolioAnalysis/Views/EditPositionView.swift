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
    @State private var purchaseDate: Date?

    init(viewModel: PortfolioAnalysisViewModel, position: ImportedPosition) {
        self._viewModel = ObservedObject(wrappedValue: viewModel)
        self.position = position

        self._symbol = State(initialValue: position.symbol)
        self._quantity = State(initialValue: String(position.quantity))
        self._costBasis = State(initialValue: position.costBasis.map { String($0) } ?? "")
        self._purchaseDate = State(initialValue: position.purchaseDate)
    }

    var body: some View {
        Form {

            // MARK: - Holding Section
            Section("Holding") {
                TextField("Symbol", text: $symbol)

                TextField("Quantity", text: $quantity)
                    .keyboardType(.decimalPad)

                TextField("Cost Basis", text: $costBasis)
                    .keyboardType(.decimalPad)

                // ⭐ NEW: Purchase Date
                DatePicker(
                    "Purchase Date",
                    selection: Binding(
                        get: { purchaseDate ?? Date() },
                        set: { purchaseDate = $0 }
                    ),
                    displayedComponents: .date
                )
                .environment(\.locale, Locale(identifier: "en_US"))
                .opacity(purchaseDate == nil ? 0.5 : 1.0)

                // Clear Date Button
                if purchaseDate != nil {
                    Button("Clear Purchase Date") {
                        purchaseDate = nil
                    }
                    .foregroundColor(.red)
                }
            }

            // MARK: - Actions
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

    // MARK: - Save Logic

    private func saveChanges() {
        let trimmedSymbol = symbol.trimmingCharacters(in: .whitespacesAndNewlines)
        let symbolToUse = trimmedSymbol.isEmpty ? position.symbol : trimmedSymbol

        let qty = Double(quantity.trimmingCharacters(in: .whitespacesAndNewlines)) ?? position.quantity
        let parsedCost = Double(costBasis.trimmingCharacters(in: .whitespacesAndNewlines))

        Task { @MainActor in
            await viewModel.updateHolding(
                oldSymbol: position.symbol,
                newSymbol: symbolToUse,
                quantity: qty,
                costBasis: parsedCost,
                purchaseDate: purchaseDate   // ⭐ NEW FIELD PASSED TO VIEWMODEL
            )
            dismiss()
        }
    }
}
// End of EditPositionView.swift
