import SwiftUI
import Combine

@MainActor
final class DashboardViewModel: ObservableObject {
    @Published var dataSet: CSVDataSet?
    @Published var normalizedRows: [NormalizedShipment] = []
    @Published var question = ""
    @Published var insight: InsightResult?
    @Published var validationErrors: [String] = []
    @Published var infoMessage: String?
    @Published var isExporting = false
    @Published var exportedURL: URL?
    @Published var history: [HistoryItem] = []

    private let csvParser: CSVParsing
    private let insightEngine: InsightAnalyzing
    private let historyStore: HistoryStoring
    private let pdfExporter: PDFExporting
    private let normalizer: ShipmentNormalizer
    private let user: UserAccount

    init(environment: AppEnvironment, user: UserAccount) {
        self.csvParser = environment.csvParser
        self.insightEngine = environment.insightEngine
        self.historyStore = environment.historyStore
        self.pdfExporter = environment.pdfExporter
        self.normalizer = environment.normalizer
        self.user = user
        self.history = historyStore.loadHistory(for: user.email)
    }

    var profileInitial: String {
        String(user.fullName.prefix(1)).uppercased()
    }

    var userName: String { user.fullName }
    var userEmail: String { user.email }

    func importCSV(from url: URL) {
        validationErrors = []
        infoMessage = nil
        do {
            let granted = url.startAccessingSecurityScopedResource()
            defer {
                if granted {
                    url.stopAccessingSecurityScopedResource()
                }
            }

            dataSet = try csvParser.parse(fileURL: url)
            normalizedRows = normalizer.normalize(dataSet: dataSet!)
            if normalizedRows.isEmpty {
                validationErrors = ["No usable rows matched required shipment fields after normalization."]
                return
            }

            let uploadHistory = HistoryItem(
                id: UUID(),
                createdAt: Date(),
                updatedAt: Date(),
                fileName: dataSet?.fileName ?? url.lastPathComponent,
                question: "",
                recordCount: dataSet?.rows.count ?? 0,
                note: "CSV uploaded and validated.",
                csvRows: dataSet?.rows ?? [],
                csvColumns: dataSet?.columns ?? [],
                insight: nil
            )
            historyStore.saveHistoryItem(uploadHistory, for: user.email)
            history = historyStore.loadHistory(for: user.email)
        } catch {
            if let csvError = error as? CSVValidationError {
                switch csvError {
                case .parseRowErrors(let issues):
                    validationErrors = issues
                case .requiredFields(let issues):
                    validationErrors = issues
                default:
                    validationErrors = [csvError.errorDescription ?? "Invalid CSV file."]
                }
            } else {
                validationErrors = [error.localizedDescription]
            }
        }
    }

    func analyzeQuestion() {
        do {
            guard !question.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                throw InsightError.noQuestion
            }
            guard !normalizedRows.isEmpty else {
                throw InsightError.noData
            }

            let generated = try insightEngine.analyze(question: question, shipments: normalizedRows, now: Date())
            insight = generated
            infoMessage = nil

            let historyItem = HistoryItem(
                id: UUID(),
                createdAt: Date(),
                updatedAt: Date(),
                fileName: dataSet?.fileName ?? "Unknown.csv",
                question: question,
                recordCount: normalizedRows.count,
                note: generated.narrative,
                csvRows: dataSet?.rows ?? [],
                csvColumns: dataSet?.columns ?? [],
                insight: generated
            )
            historyStore.saveHistoryItem(historyItem, for: user.email)
            history = historyStore.loadHistory(for: user.email)
        } catch {
            infoMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
    }

    func restoreHistory(_ item: HistoryItem) {
        question = item.question
        insight = item.insight
        if item.csvRows.isEmpty {
            infoMessage = "Stored rows are unavailable. Please re-upload the CSV."
            return
        }
        dataSet = CSVDataSet(fileName: item.fileName, columns: item.csvColumns, rows: item.csvRows)
        normalizedRows = normalizer.normalize(dataSet: dataSet!)
        infoMessage = "Restored history from \(item.fileName)."
    }

    func clearHistory() {
        historyStore.clearHistory(for: user.email)
        history = []
    }

    func clearInMemoryState() {
        dataSet = nil
        normalizedRows = []
        question = ""
        insight = nil
        infoMessage = nil
        validationErrors = []
        exportedURL = nil
    }

    func loadSampleDataIfNeeded() {
        guard dataSet == nil,
              let url = Bundle.main.url(forResource: "sample_shipments", withExtension: "csv") else {
            return
        }
        importCSV(from: url)
    }

    func exportPDF() {
        guard let insight, let dataSet else { return }
        isExporting = true
        defer { isExporting = false }

        let chartImage = insight.showChart ? generateChartSnapshot(for: insight) : nil
        do {
            let report = PDFReportInput(
                title: insight.title,
                fileName: dataSet.fileName,
                question: question,
                generatedAt: Date(),
                analyzedCount: insight.analyzedCount,
                insight: insight,
                chartImage: chartImage
            )
            exportedURL = try pdfExporter.exportReport(report)
            infoMessage = "Report exported to temporary files."
        } catch {
            infoMessage = "Failed to export report PDF."
        }
    }

    private func generateChartSnapshot(for insight: InsightResult) -> UIImage? {
        let view = ChartSnapshotView(insight: insight)
            .frame(width: 560, height: 220)
            .background(Color.white)
        let renderer = ImageRenderer(content: view)
        renderer.scale = UIScreen.main.scale
        return renderer.uiImage
    }
}
