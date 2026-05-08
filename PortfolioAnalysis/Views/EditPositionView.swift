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
    @State private var unitCost: String
    @State private var purchaseDate: Date?

    init(viewModel: PortfolioAnalysisViewModel, position: ImportedPosition) {
        self._viewModel = ObservedObject(wrappedValue: viewModel)
        self.position = position

        self._symbol = State(initialValue: position.symbol)
        self._quantity = State(initialValue: String(position.quantity))
        self._unitCost = State(initialValue: position.unitCost.map { String($0) } ?? "")
        self._purchaseDate = State(initialValue: position.purchaseDate)
    }

    private var currencyCode: String {
        Locale.current.currency?.identifier ?? "USD"
    }

    var body: some View {
        Form {

            // MARK: - Holding Section
            Section("Holding") {

                LabeledContent("Symbol") {
                    TextField("Symbol", text: $symbol)
                }

                LabeledContent("Quantity (Shares)") {
                    TextField("Quantity", text: $quantity)
                        .keyboardType(.decimalPad)
                }

                LabeledContent("Unit Cost (per share)") {
                    TextField("Unit Cost", text: $unitCost)
                        .keyboardType(.decimalPad)
                }

                // Computed total cost basis (read-only)
                if let qty = Double(quantity),
                   let uCost = Double(unitCost) {
                    LabeledContent("Total Cost Basis") {
                        Text((qty * uCost).formatted(.currency(code: currencyCode)))
                            .foregroundColor(.secondary)
                    }
                }

                LabeledContent("Purchase Date") {
                    DatePicker(
                        "",
                        selection: Binding(
                            get: { purchaseDate ?? Date() },
                            set: { purchaseDate = $0 }
                        ),
                        displayedComponents: .date
                    )
                    .environment(\.locale, Locale(identifier: "en_US"))
                }

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
        let uCost = Double(unitCost.trimmingCharacters(in: .whitespacesAndNewlines))
        let totalCostBasis = (qty * (uCost ?? position.unitCost ?? 0))

        Task { @MainActor in
            await viewModel.updateHolding(
                oldSymbol: position.symbol,
                newSymbol: symbolToUse,
                quantity: qty,
                costBasis: totalCostBasis,
                purchaseDate: purchaseDate
            )
            dismiss()
        }
    }
}

// End of EditPositionView.swift
