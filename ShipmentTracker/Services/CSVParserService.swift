import Foundation

protocol CSVParsing {
    func parse(fileURL: URL) throws -> CSVDataSet
}

final class CSVParserService: CSVParsing {
    private let requiredFields = ["shipment_id", "route", "carrier", "origin", "destination"]

    func parse(fileURL: URL) throws -> CSVDataSet {
        guard let data = try? Data(contentsOf: fileURL),
              let text = String(data: data, encoding: .utf8) ?? String(data: data, encoding: .ascii) else {
            throw CSVValidationError.unreadableRows
        }

        let lines = text
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .newlines) }
            .filter { !$0.isEmpty }

        guard !lines.isEmpty else { throw CSVValidationError.emptyFile }

        let headerParse = parseLine(lines[0])
        guard !headerParse.values.isEmpty else { throw CSVValidationError.unreadableRows }

        let headers = headerParse.values.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        let normalizedIndex = Dictionary(uniqueKeysWithValues: headers.map { (normalizeKey($0), $0) })

        var corruptedRows: [String] = []
        var requiredErrors: [String] = []
        var rows: [[String: String]] = []

        for (idx, line) in lines.dropFirst().enumerated() {
            let parsed = parseLine(line)
            if parsed.hadUnbalancedQuote {
                corruptedRows.append("Row \(idx + 2): malformed quotes.")
                continue
            }

            if parsed.values.count != headers.count {
                corruptedRows.append("Row \(idx + 2): expected \(headers.count) columns but found \(parsed.values.count).")
                continue
            }

            let row = Dictionary(uniqueKeysWithValues: zip(headers, parsed.values.map {
                $0.trimmingCharacters(in: .whitespacesAndNewlines)
            }))

            let missing = requiredFields.compactMap { field -> String? in
                guard let matchingHeader = normalizedIndex[normalizeKey(field)] else { return field }
                let value = row[matchingHeader] ?? ""
                return value.isEmpty ? field : nil
            }

            if !missing.isEmpty {
                requiredErrors.append("Row \(idx + 2): missing required field(s): \(missing.joined(separator: ", ")).")
            } else {
                rows.append(row)
            }
        }

        if !corruptedRows.isEmpty {
            throw CSVValidationError.parseRowErrors(corruptedRows)
        }

        if !requiredErrors.isEmpty {
            throw CSVValidationError.requiredFields(requiredErrors)
        }

        guard !rows.isEmpty else {
            throw CSVValidationError.noUsableRows
        }

        return CSVDataSet(fileName: fileURL.lastPathComponent, columns: headers, rows: rows)
    }

    private func normalizeKey(_ value: String) -> String {
        value
            .lowercased()
            .replacingOccurrences(of: "_", with: "")
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "-", with: "")
    }

    private func parseLine(_ line: String) -> (values: [String], hadUnbalancedQuote: Bool) {
        var values: [String] = []
        var current = ""
        var insideQuotes = false
        var chars = Array(line)
        var index = 0

        while index < chars.count {
            let char = chars[index]
            if char == "\"" {
                if insideQuotes, index + 1 < chars.count, chars[index + 1] == "\"" {
                    current.append("\"")
                    index += 1
                } else {
                    insideQuotes.toggle()
                }
            } else if char == ",", !insideQuotes {
                values.append(current)
                current = ""
            } else {
                current.append(char)
            }
            index += 1
        }
        values.append(current)
        return (values, insideQuotes)
    }
}

struct ShipmentNormalizer {
    private let dateParser = ShipmentDateParser()

    func normalize(dataSet: CSVDataSet) -> [NormalizedShipment] {
        let lookup = headerLookup(columns: dataSet.columns)

        return dataSet.rows.compactMap { row in
            guard let id = value(for: "shipment_id", in: row, lookup: lookup),
                  let route = value(for: "route", in: row, lookup: lookup),
                  let carrier = value(for: "carrier", in: row, lookup: lookup),
                  let origin = value(for: "origin", in: row, lookup: lookup),
                  let destination = value(for: "destination", in: row, lookup: lookup) else {
                return nil
            }

            let plannedDate = dateValue(for: ["planned_delivery_date", "eta", "expected_delivery_date"], in: row, lookup: lookup)
            let actualDate = dateValue(for: ["actual_delivery_date", "delivered_at"], in: row, lookup: lookup)
            let shipmentDate = dateValue(for: ["shipment_date", "pickup_date", "dispatch_date", "created_at"], in: row, lookup: lookup)
            let status = value(forCandidates: ["status", "shipment_status"], in: row, lookup: lookup) ?? ""

            let delayValue = numberValue(for: ["delay_minutes", "delay_mins", "delay", "late_by_minutes"], in: row, lookup: lookup)
            let inferred = inferDelay(plannedDate: plannedDate, actualDate: actualDate)
            let delayMinutes = delayValue ?? inferred ?? 0
            let statusLower = status.lowercased()
            let isDelayed = statusLower.contains("delay") || statusLower.contains("late") || delayMinutes > 0

            return NormalizedShipment(
                id: id,
                route: route,
                carrier: carrier,
                origin: origin,
                destination: destination,
                plannedDate: plannedDate,
                actualDate: actualDate,
                shipmentDate: shipmentDate,
                delayMinutes: delayMinutes,
                status: status,
                isDelayed: isDelayed
            )
        }
    }

    private func headerLookup(columns: [String]) -> [String: String] {
        Dictionary(uniqueKeysWithValues: columns.map { (normalizeKey($0), $0) })
    }

    private func normalizeKey(_ value: String) -> String {
        value
            .lowercased()
            .replacingOccurrences(of: "_", with: "")
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "-", with: "")
    }

    private func value(for key: String, in row: [String: String], lookup: [String: String]) -> String? {
        value(forCandidates: [key], in: row, lookup: lookup)
    }

    private func value(forCandidates keys: [String], in row: [String: String], lookup: [String: String]) -> String? {
        for key in keys {
            if let header = lookup[normalizeKey(key)],
               let value = row[header]?.trimmingCharacters(in: .whitespacesAndNewlines),
               !value.isEmpty {
                return value
            }
        }
        return nil
    }

    private func dateValue(for keys: [String], in row: [String: String], lookup: [String: String]) -> Date? {
        guard let raw = value(forCandidates: keys, in: row, lookup: lookup) else { return nil }
        return dateParser.parse(raw)
    }

    private func numberValue(for keys: [String], in row: [String: String], lookup: [String: String]) -> Double? {
        guard let raw = value(forCandidates: keys, in: row, lookup: lookup)?
            .replacingOccurrences(of: ",", with: ".") else { return nil }
        return Double(raw)
    }

    private func inferDelay(plannedDate: Date?, actualDate: Date?) -> Double? {
        guard let plannedDate, let actualDate else { return nil }
        let minutes = actualDate.timeIntervalSince(plannedDate) / 60.0
        return minutes > 0 ? minutes : 0
    }
}

struct ShipmentDateParser {
    private let formats = [
        "yyyy-MM-dd",
        "yyyy/MM/dd",
        "MM/dd/yyyy",
        "dd/MM/yyyy",
        "yyyy-MM-dd HH:mm:ss",
        "yyyy-MM-dd'T'HH:mm:ssZ",
        "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
    ]

    func parse(_ raw: String) -> Date? {
        if let iso = ISO8601DateFormatter().date(from: raw) {
            return iso
        }

        for format in formats {
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "en_US_POSIX")
            formatter.timeZone = TimeZone(secondsFromGMT: 0)
            formatter.dateFormat = format
            if let date = formatter.date(from: raw) {
                return date
            }
        }
        return nil
    }
}
