import Foundation
import SwiftUI
import UIKit

struct PDFReportInput {
    let title: String
    let fileName: String
    let question: String
    let generatedAt: Date
    let analyzedCount: Int
    let insight: InsightResult
    let chartImage: UIImage?
}

protocol PDFExporting {
    func exportReport(_ input: PDFReportInput) throws -> URL
}

enum PDFExportError: LocalizedError {
    case unableToWrite

    var errorDescription: String? {
        "Unable to create report PDF."
    }
}

final class PDFExportService: PDFExporting {
    func exportReport(_ input: PDFReportInput) throws -> URL {
        let safeName = input.fileName
            .replacingOccurrences(of: ".csv", with: "")
            .replacingOccurrences(of: " ", with: "_")
            .replacingOccurrences(of: "/", with: "-")
        let targetURL = FileManager.default.temporaryDirectory.appendingPathComponent("\(safeName)_report.pdf")
        let bounds = CGRect(x: 0, y: 0, width: 612, height: 792)
        let renderer = UIGraphicsPDFRenderer(bounds: bounds)

        do {
            try renderer.writePDF(to: targetURL) { context in
                context.beginPage()
                let bodyFont = UIFont.systemFont(ofSize: 12)
                let titleFont = UIFont.boldSystemFont(ofSize: 24)
                let subtitleFont = UIFont.boldSystemFont(ofSize: 16)

                var y: CGFloat = 24
                if let logo = UIImage(named: "ReportLogo") {
                    logo.draw(in: CGRect(x: 24, y: y, width: 70, height: 40))
                    y += 50
                }

                draw("Logistics Ops Assistant", at: CGPoint(x: 24, y: y), font: titleFont)
                y += 34
                draw(input.title, at: CGPoint(x: 24, y: y), font: subtitleFont)
                y += 28

                let dateFormatter = DateFormatter()
                dateFormatter.dateStyle = .medium
                dateFormatter.timeStyle = .short

                let metaLines = [
                    "File: \(input.fileName)",
                    "Question: \(input.question)",
                    "Generated: \(dateFormatter.string(from: input.generatedAt))",
                    "Analyzed shipments: \(input.analyzedCount)"
                ]
                for line in metaLines {
                    draw(line, at: CGPoint(x: 24, y: y), font: bodyFont)
                    y += 20
                }

                y += 10
                if let chart = input.chartImage {
                    draw("Chart Snapshot", at: CGPoint(x: 24, y: y), font: subtitleFont)
                    y += 22
                    let chartHeight: CGFloat = 180
                    chart.draw(in: CGRect(x: 24, y: y, width: 560, height: chartHeight))
                    y += chartHeight + 16
                }

                draw("Table Data", at: CGPoint(x: 24, y: y), font: subtitleFont)
                y += 20
                draw("\(input.insight.dimension.title) | \(input.insight.metric.title)", at: CGPoint(x: 24, y: y), font: UIFont.boldSystemFont(ofSize: 12))
                y += 18

                for row in input.insight.rows {
                    if y > 760 {
                        context.beginPage()
                        y = 24
                    }
                    draw("\(row.label) | \(formatted(row.value))", at: CGPoint(x: 24, y: y), font: bodyFont)
                    y += 16
                }
            }
            return targetURL
        } catch {
            throw PDFExportError.unableToWrite
        }
    }

    private func draw(_ text: String, at point: CGPoint, font: UIFont) {
        let attrs: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: UIColor.label
        ]
        text.draw(at: point, withAttributes: attrs)
    }

    private func formatted(_ value: Double) -> String {
        if value.truncatingRemainder(dividingBy: 1) == 0 {
            return String(Int(value))
        }
        return String(format: "%.2f", value)
    }
}
