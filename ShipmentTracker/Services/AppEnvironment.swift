import Foundation

final class AppEnvironment {
    let authService: AuthServicing
    let csvParser: CSVParsing
    let insightEngine: InsightAnalyzing
    let historyStore: HistoryStoring
    let pdfExporter: PDFExporting
    let normalizer: ShipmentNormalizer

    init(
        authService: AuthServicing = AuthService(),
        csvParser: CSVParsing = CSVParserService(),
        insightEngine: InsightAnalyzing = InsightEngine(),
        historyStore: HistoryStoring = HistoryStore(),
        pdfExporter: PDFExporting = PDFExportService(),
        normalizer: ShipmentNormalizer = ShipmentNormalizer()
    ) {
        self.authService = authService
        self.csvParser = csvParser
        self.insightEngine = insightEngine
        self.historyStore = historyStore
        self.pdfExporter = pdfExporter
        self.normalizer = normalizer
    }
}
