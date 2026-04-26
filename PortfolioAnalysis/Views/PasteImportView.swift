//
//  PasteImportView.swift
//  PortfolioAnalysis
//
//  Created by Mark Leonard on 4/25/2026.
//

import SwiftUI
import UniformTypeIdentifiers

struct PasteImportView: View {
    @ObservedObject var viewModel: PortfolioAnalysisViewModel

    @Environment(\.dismiss) private var dismiss

    @State private var pastedText: String = ""
    @State private var showFileImporter = false
    @State private var importError: String?

    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 16) {

                // MARK: - File Chooser Button
                Button {
                    showFileImporter = true
                } label: {
                    Label("Choose File to Load Into Preview", systemImage: "doc.text")
                        .font(.headline)
                }
                .buttonStyle(.borderedProminent)
                .padding(.top, 4)

                Text("Portfolio Data Preview")
                    .font(.headline)

                spreadsheetPasteBox

                Spacer()

                Button {
                    importPortfolioData()
                } label: {
                    Text("Import Portfolio Data")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .disabled(pastedText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

            }
            .padding()
            .navigationTitle("Paste Portfolio Data")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
            .fileImporter(
                isPresented: $showFileImporter,
                allowedContentTypes: [
                    .commaSeparatedText,
                    .plainText,
                    .utf8PlainText,
                    .text,
                    .data
                ],
                allowsMultipleSelection: false
            ) { result in
                handleFileImport(result)
            }
            .alert("Import Error", isPresented: Binding(
                get: { importError != nil },
                set: { _ in importError = nil }
            )) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(importError ?? "Unknown error")
            }
        }
    }

    // MARK: - Spreadsheet‑Style Paste Box (Row Numbers + Column Guides)
    private var spreadsheetPasteBox: some View {

        // Parse CSV into rows + columns
        let rows = pastedText.components(separatedBy: .newlines)
        let parsed = rows.map {
            $0.split(separator: ",", omittingEmptySubsequences: false).map(String.init)
        }

        // Determine number of columns
        let columnCount = parsed.map { $0.count }.max() ?? 0

        // Auto‑detect column widths
        let columnWidths: [CGFloat] = (0..<columnCount).map { col in
            let longest = parsed.compactMap { row -> String? in
                guard col < row.count else { return nil }
                return row[col]
            }
            .max(by: { $0.count < $1.count }) ?? ""

            return CGFloat(longest.count) * 8.0 + 24.0
        }

        let totalWidth = columnWidths.reduce(0, +) + 40
        let gutterWidth: CGFloat = 50   // row number gutter

        return ScrollView([.horizontal, .vertical]) {
            ZStack(alignment: .topLeading) {

                // COLUMN GUIDES
                Canvas { context, size in
                    var x: CGFloat = gutterWidth
                    for width in columnWidths {
                        x += width
                        var path = Path()
                        path.move(to: CGPoint(x: x, y: 0))
                        path.addLine(to: CGPoint(x: x, y: size.height))

                        context.stroke(
                            path,
                            with: .color(Color.gray.opacity(0.25)),
                            lineWidth: 1
                        )
                    }
                }

                // ROW NUMBERS (left gutter)
                VStack(alignment: .trailing, spacing: 0) {
                    ForEach(rows.indices, id: \.self) { i in
                        Text("\(i + 1)")
                            .font(.system(.body, design: .monospaced))
                            .foregroundColor(.secondary)
                            .frame(width: gutterWidth - 8, alignment: .trailing)
                            .padding(.vertical, 2)
                    }
                }
                .padding(.top, 12)
                .background(Color(.secondarySystemBackground))

                // TEXT EDITOR (non‑wrapping)
                TextEditor(text: $pastedText)
                    .font(.system(.body, design: .monospaced))
                    .disableAutocorrection(true)
                    .textInputAutocapitalization(.never)
                    .padding(.leading, gutterWidth)
                    .padding(.top, 8)
                    .background(Color.clear)
                    .frame(
                        minWidth: max(totalWidth + gutterWidth, 800),
                        minHeight: 300,
                        alignment: .topLeading
                    )
                    .fixedSize(horizontal: true, vertical: false)
                    .scrollContentBackground(.hidden)
            }
            .padding(4)
        }
        .frame(maxHeight: 300)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(8)
    }

    // MARK: - Import Logic
    private func importPortfolioData() {
        viewModel.importPastedText(pastedText)

        dismiss()
    }

    // MARK: - File Loading Logic
    private func handleFileImport(_ result: Result<[URL], Error>) {
        do {
            guard let url = try result.get().first else { return }
            let text = try String(contentsOf: url, encoding: .utf8)
            pastedText = text
        } catch {
            importError = "Failed to load file: \(error.localizedDescription)"
        }
    }
}
