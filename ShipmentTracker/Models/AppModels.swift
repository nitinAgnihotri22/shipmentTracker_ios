import Foundation

struct UserAccount: Codable, Identifiable, Equatable {
    let id: UUID
    let fullName: String
    let email: String
    let passwordHash: String
    let createdAt: Date
}

struct Session: Codable, Equatable {
    let email: String
}

struct CSVDataSet: Codable, Equatable {
    let fileName: String
    let columns: [String]
    let rows: [[String: String]]
}

struct NormalizedShipment: Codable, Identifiable, Equatable {
    let id: String
    let route: String
    let carrier: String
    let origin: String
    let destination: String
    let plannedDate: Date?
    let actualDate: Date?
    let shipmentDate: Date?
    let delayMinutes: Double
    let status: String
    let isDelayed: Bool
}

enum InsightDimension: String, Codable {
    case route
    case carrier
    case destination
    case origin

    var title: String { rawValue.capitalized }
}

enum InsightMetric: String, Codable {
    case avgDelay = "avg_delay"
    case delayMinutes = "delay_minutes"
    case shipmentCount = "shipment_count"
    case delayCount = "delay_count"

    var title: String {
        switch self {
        case .avgDelay:
            return "Average Delay (mins)"
        case .delayMinutes:
            return "Total Delay (mins)"
        case .shipmentCount:
            return "Shipments"
        case .delayCount:
            return "Delayed Shipments"
        }
    }
}

struct InsightRow: Codable, Identifiable, Equatable {
    let id: UUID
    let label: String
    let value: Double
}

struct InsightResult: Codable, Equatable {
    let title: String
    let narrative: String
    let analyzedCount: Int
    let dimension: InsightDimension
    let metric: InsightMetric
    let rows: [InsightRow]
    let showTable: Bool
    let showChart: Bool
    let generatedAt: Date
}

struct HistoryItem: Codable, Identifiable, Equatable {
    let id: UUID
    let createdAt: Date
    let updatedAt: Date
    let fileName: String
    let question: String
    let recordCount: Int
    let note: String
    let csvRows: [[String: String]]
    let csvColumns: [String]
    let insight: InsightResult?
}
