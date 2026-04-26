//
//  PasteImportView.swift
//  PortfolioAnalysis
//

import SwiftUI

struct PasteImportView: View {
    @ObservedObject var viewModel: PortfolioAnalysisViewModel
    @Environment(\.dismiss) var dismiss

    @State private var pastedText: String = ""
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {

                Text("Paste Portfolio Data")
                    .font(.title2.bold())

                TextEditor(text: $pastedText)
                    .frame(minHeight: 240)
                    .padding(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.secondary.opacity(0.3))
                    )

                if let error = errorMessage {
                    Text(error)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                }

                Button {
                    importPasted()
                } label: {
                    Label("Import", systemImage: "checkmark.circle.fill")
                }
                .buttonStyle(.borderedProminent)
                .disabled(pastedText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

                Spacer()
            }
            .padding()
            .navigationTitle("Paste Import")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }

    private func importPasted() {
        do {
            // Parse TSV (tab-delimited)
            let positions = try ImportedPosition.parseTSV(pastedText)

            // ViewModel expects [ImportedPosition]
            viewModel.importPastedPositions(positions)

            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
