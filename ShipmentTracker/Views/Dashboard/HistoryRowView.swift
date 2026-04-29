import SwiftUI

struct HistoryRowView: View {
    let item: HistoryItem

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(item.fileName)
                .font(.headline)
            Text(item.question.isEmpty ? "Upload only" : item.question)
                .font(.subheadline)
                .foregroundStyle(.primary)
            Text(item.note)
                .font(.footnote)
                .foregroundStyle(.secondary)
            Text("Records: \(item.recordCount)")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(8)
        .background(Color.gray.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .accessibilityLabel("History item \(item.fileName)")
    }
}
