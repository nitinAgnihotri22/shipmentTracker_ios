import SwiftUI

struct CSVPreviewView: View {
    let dataSet: CSVDataSet
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView([.horizontal, .vertical]) {
                VStack(alignment: .leading, spacing: 0) {
                    HStack {
                        ForEach(dataSet.columns, id: \.self) { column in
                            Text(column)
                                .font(.caption.bold())
                                .frame(width: 160, alignment: .leading)
                                .padding(6)
                                .background(Color.blue.opacity(0.1))
                        }
                    }
                    ForEach(Array(dataSet.rows.enumerated()), id: \.offset) { _, row in
                        HStack {
                            ForEach(dataSet.columns, id: \.self) { column in
                                Text(row[column] ?? "")
                                    .font(.caption)
                                    .frame(width: 160, alignment: .leading)
                                    .padding(6)
                            }
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Full CSV Preview")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }
}
