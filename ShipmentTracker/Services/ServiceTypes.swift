import Foundation

enum AuthError: LocalizedError {
    case requiredFields
    case userAlreadyExists
    case invalidCredentials

    var errorDescription: String? {
        switch self {
        case .requiredFields:
            return "Please fill all required fields."
        case .userAlreadyExists:
            return "User already exists. Please login instead."
        case .invalidCredentials:
            return "Invalid email or password."
        }
    }
}

enum CSVValidationError: LocalizedError, Equatable {
    case emptyFile
    case unreadableRows
    case parseRowErrors([String])
    case noUsableRows
    case requiredFields([String])

    var errorDescription: String? {
        switch self {
        case .emptyFile:
            return "The file is empty."
        case .unreadableRows:
            return "Could not read CSV rows."
        case .parseRowErrors(let issues):
            return issues.joined(separator: "\n")
        case .noUsableRows:
            return "No usable data rows were found."
        case .requiredFields(let rows):
            return rows.joined(separator: "\n")
        }
    }
}

enum InsightError: LocalizedError {
    case noData
    case noQuestion
    case noResults

    var errorDescription: String? {
        switch self {
        case .noData:
            return "Upload a CSV file before asking a question."
        case .noQuestion:
            return "Please enter a question."
        case .noResults:
            return "No matching shipments were found for this question."
        }
    }
}

struct ParsedQuestion {
    let dimension: InsightDimension
    let metric: InsightMetric
    let topN: Int
    let showTable: Bool
    let showChart: Bool
    let dateFilter: (Date?) -> Bool
    let timeDescription: String
}
