//
//  PasteImportView.swift
//  PortfolioAnalysis
//

import SwiftUI
import UniformTypeIdentifiers

struct PasteImportView: View {
    @ObservedObject var viewModel: PortfolioAnalysisViewModel
    @Environment(\.dismiss) var dismiss

    @State private var pastedText: String = ""
    @State private var errorMessage: String?
    @State private var isFileImporterPresented = false
    @State private var previewPositions: [ImportedPosition] = []

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {

                Text("Paste Portfolio Data")
                    .font(.title2.bold())

                Button {
                    isFileImporterPresented = true
                } label: {
                    Label("Choose File…", systemImage: "doc.on.doc")
                }
                .buttonStyle(.bordered)
                .fileImporter(
                    isPresented: $isFileImporterPresented,
                    allowedContentTypes: [.plainText, .commaSeparatedText, .tabSeparatedText],
                    allowsMultipleSelection: false
                ) { result in
                    handleFileImport(result)
                }

                Button {
                    if let clipboard = UIPasteboard.general.string {
                        pastedText = clipboard
                        updatePreview()
                    }
                } label: {
                    Label("Paste from Clipboard", systemImage: "doc.on.clipboard")
                }
                .buttonStyle(.bordered)

                Button(role: .destructive) {
                    pastedText = ""
                    previewPositions = []
                } label: {
                    Label("Clear", systemImage: "trash")
                }
                .buttonStyle(.bordered)

                Button {
                    importPasted()
                } label: {
                    Label("Import", systemImage: "checkmark.circle.fill")
                        .font(.headline)
                }
                .buttonStyle(.borderedProminent)
                .disabled(pastedText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

                TextEditor(text: $pastedText)
                    .frame(minHeight: 200)
                    .padding(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.secondary.opacity(0.3))
                    )
                    .onChange(of: pastedText) { _, _ in updatePreview() }

                if let error = errorMessage {
                    Text(error)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                }

                if !previewPositions.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Preview (\(previewPositions.count) positions)")
                            .font(.headline)

                        ScrollView {
                            VStack(alignment: .leading, spacing: 6) {
                                ForEach(previewPositions.prefix(10), id: \.symbol) { pos in
                                    HStack {
                                        Text(pos.symbol).font(.body.bold())
                                        Spacer()
                                        Text("Qty: \(pos.quantity, specifier: "%.2f")")
                                            .foregroundColor(.secondary)
                                    }
                                }

                                if previewPositions.count > 10 {
                                    Text("…and \(previewPositions.count - 10) more")
                                        .foregroundColor(.secondary)
                                        .italic()
                                }
                            }
                        }
                        .frame(maxHeight: 150)
                    }
                    .padding(.top, 8)
                }

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
        .developerLabel("PasteImportView")
    }

    private func handleFileImport(_ result: Result<[URL], Error>) {
        do {
            let urls = try result.get()
            guard let url = urls.first else { return }

            let _ = url.startAccessingSecurityScopedResource()
            defer { url.stopAccessingSecurityScopedResource() }

            let text = try String(contentsOf: url, encoding: .utf8)
            pastedText = text
            updatePreview()

        } catch {
            errorMessage = "Failed to load file: \(error.localizedDescription)"
        }
    }

    private func updatePreview() {
        do {
            previewPositions = try ImportedPosition.parseTSV(pastedText)
        } catch {
            previewPositions = []
        }
    }

    private func importPasted() {
        do {
            let positions = try ImportedPosition.parseTSV(pastedText)
            viewModel.importPastedPositions(positions)
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
