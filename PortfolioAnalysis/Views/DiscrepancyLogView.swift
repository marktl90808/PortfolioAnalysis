import SwiftUI

struct DiscrepancyLogView: View {

    @StateObject private var log = DiscrepancyLogStore.shared

    var body: some View {
        NavigationView {
            List {
                if log.entries.isEmpty {
                    Text("No discrepancies detected yet.")
                        .foregroundColor(.secondary)
                } else {
                    ForEach(log.groupedBySymbol, id: \.symbol) { group in
                        Section(header: Text(group.symbol).font(.headline)) {
                            ForEach(group.entries) { entry in
                                VStack(alignment: .leading, spacing: 6) {
                                    Text(entry.message)
                                        .font(.subheadline)

                                    Text(entry.timestamp.formatted(date: .numeric, time: .standard))
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .padding(.vertical, 4)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Data Discrepancies")
            .toolbar {
                Button("Clear") {
                    log.clear()
                }
            }
        }
    }
}
