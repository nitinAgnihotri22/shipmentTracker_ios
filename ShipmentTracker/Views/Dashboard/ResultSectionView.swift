import Charts
import SwiftUI

struct ResultSectionView: View {
    @ObservedObject var viewModel: DashboardViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let infoMessage = viewModel.infoMessage {
                Text(infoMessage)
                    .foregroundStyle(.secondary)
            }

            if let insight = viewModel.insight {
                Text(insight.title)
                    .font(.headline)
                Text(insight.narrative)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text("Analyzed shipment count: \(insight.analyzedCount)")
                    .font(.footnote)

                if insight.showChart {
                    InsightChartView(insight: insight)
                        .frame(height: 240)
                }

                if insight.showTable {
                    InsightTableView(insight: insight)
                }

                HStack {
                    Button(viewModel.isExporting ? "Exporting..." : "Export Report PDF") {
                        viewModel.exportPDF()
                    }
                    .disabled(viewModel.isExporting)
                    .buttonStyle(.borderedProminent)

                    if let exportedURL = viewModel.exportedURL {
                        ShareLink(item: exportedURL) {
                            Label("Share PDF", systemImage: "square.and.arrow.up")
                        }
                    }
                }
            } else {
                Text("No result yet. Upload a CSV and ask a question.")
                    .foregroundStyle(.secondary)
            }
        }
    }
}

struct InsightChartView: View {
    let insight: InsightResult

    var body: some View {
        Chart(insight.rows) { row in
            BarMark(
                x: .value(insight.dimension.title, row.label),
                y: .value(insight.metric.title, row.value)
            )
            .foregroundStyle(.blue.gradient)
        }
        .chartScrollableAxes(.horizontal)
        .accessibilityLabel("Insight chart")
    }
}

struct InsightTableView: View {
    let insight: InsightResult

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(insight.dimension.title).bold().frame(maxWidth: .infinity, alignment: .leading)
                Text(insight.metric.title).bold().frame(maxWidth: .infinity, alignment: .trailing)
            }
            .font(.footnote)

            ForEach(insight.rows) { row in
                HStack {
                    Text(row.label).frame(maxWidth: .infinity, alignment: .leading)
                    Text(displayValue(row.value)).frame(maxWidth: .infinity, alignment: .trailing)
                }
                .font(.footnote)
            }
        }
        .padding(8)
        .background(Color.gray.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .accessibilityLabel("Insight table")
    }

    private func displayValue(_ value: Double) -> String {
        if value.truncatingRemainder(dividingBy: 1) == 0 {
            return "\(Int(value))"
        }
        return String(format: "%.2f", value)
    }
}

struct ChartSnapshotView: View {
    let insight: InsightResult

    var body: some View {
        InsightChartView(insight: insight)
    }
}
