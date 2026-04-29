import Foundation

protocol InsightAnalyzing {
    func analyze(question: String, shipments: [NormalizedShipment], now: Date) throws -> InsightResult
    func parseQuestion(_ question: String, now: Date) -> ParsedQuestion
}

final class InsightEngine: InsightAnalyzing {
    func analyze(question: String, shipments: [NormalizedShipment], now: Date = .init()) throws -> InsightResult {
        guard !shipments.isEmpty else { throw InsightError.noData }

        let trimmed = question.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw InsightError.noQuestion }

        let parsed = parseQuestion(trimmed, now: now)
        let filtered = shipments.filter { parsed.dateFilter(relevantDate(for: $0)) }
        guard !filtered.isEmpty else { throw InsightError.noResults }

        let grouped = Dictionary(grouping: filtered, by: { dimensionValue(for: $0, dimension: parsed.dimension) })
        let rows: [InsightRow] = grouped.map { key, values in
            InsightRow(id: UUID(), label: key, value: metricValue(for: values, metric: parsed.metric))
        }
        .sorted { $0.value > $1.value }
        .prefix(parsed.topN)
        .map { $0 }

        guard !rows.isEmpty else { throw InsightError.noResults }

        let narrative = "Showing top \(rows.count) \(parsed.dimension.rawValue) groups for \(parsed.metric.title.lowercased()) in \(parsed.timeDescription)."
        return InsightResult(
            title: "Shipment Insight by \(parsed.dimension.title)",
            narrative: narrative,
            analyzedCount: filtered.count,
            dimension: parsed.dimension,
            metric: parsed.metric,
            rows: rows,
            showTable: parsed.showTable,
            showChart: parsed.showChart,
            generatedAt: now
        )
    }

    func parseQuestion(_ question: String, now: Date = .init()) -> ParsedQuestion {
        let lower = question.lowercased()
        let dimension = detectDimension(in: lower)
        let metric = detectMetric(in: lower)
        let topN = detectTopN(in: lower)
        let display = detectDisplayMode(in: lower)
        let (dateFilter, label) = detectTimeWindow(in: lower, now: now)

        return ParsedQuestion(
            dimension: dimension,
            metric: metric,
            topN: topN,
            showTable: display.showTable,
            showChart: display.showChart,
            dateFilter: dateFilter,
            timeDescription: label
        )
    }

    private func detectDimension(in question: String) -> InsightDimension {
        if question.contains("carrier") || question.contains("driver") || question.contains("vendor") {
            return .carrier
        }
        if question.contains("destination") || question.contains("city") || question.contains("hub") {
            return .destination
        }
        if question.contains("origin") {
            return .origin
        }
        return .route
    }

    private func detectMetric(in question: String) -> InsightMetric {
        if question.contains("average") || question.contains("avg") {
            return .avgDelay
        }
        if question.contains("minutes") || question.contains("total delay") {
            return .delayMinutes
        }
        if question.contains("shipments") || question.contains("volume") {
            return .shipmentCount
        }
        return .delayCount
    }

    private func detectTopN(in question: String) -> Int {
        let pattern = #"top\s+(\d+)"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return 10 }
        let nsRange = NSRange(question.startIndex..<question.endIndex, in: question)
        guard let match = regex.firstMatch(in: question, range: nsRange),
              match.numberOfRanges > 1,
              let range = Range(match.range(at: 1), in: question),
              let value = Int(question[range]),
              value > 0 else {
            return 10
        }
        return value
    }

    private func detectDisplayMode(in question: String) -> (showTable: Bool, showChart: Bool) {
        let table = question.contains("table") || question.contains("list")
        let chart = question.contains("chart") || question.contains("graph")
        if table && chart {
            return (true, true)
        }
        if table {
            return (true, false)
        }
        if chart {
            return (false, true)
        }
        return (false, true)
    }

    private func detectTimeWindow(in question: String, now: Date) -> ((Date?) -> Bool, String) {
        let calendar = Calendar.current
        if question.contains("last month"),
           let monthRange = calendar.dateInterval(of: .month, for: calendar.date(byAdding: .month, value: -1, to: now) ?? now) {
            return ({ date in
                guard let date else { return false }
                return monthRange.contains(date)
            }, "last month")
        }

        if question.contains("this month"),
           let monthRange = calendar.dateInterval(of: .month, for: now) {
            return ({ date in
                guard let date else { return false }
                return monthRange.contains(date)
            }, "this month")
        }

        if let days = extractLastNDays(in: question) {
            let start = calendar.startOfDay(for: calendar.date(byAdding: .day, value: -days, to: now) ?? now)
            return ({ date in
                guard let date else { return false }
                return date >= start && date <= now
            }, "last \(days) days")
        }

        if let month = detectNamedMonth(in: question) {
            return ({ date in
                guard let date else { return false }
                return calendar.component(.month, from: date) == month
            }, monthName(from: month))
        }

        return ({ _ in true }, "all available time")
    }

    private func extractLastNDays(in question: String) -> Int? {
        let pattern = #"last\s+(\d+)\s+days"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return nil }
        let nsRange = NSRange(question.startIndex..<question.endIndex, in: question)
        guard let match = regex.firstMatch(in: question, range: nsRange),
              let range = Range(match.range(at: 1), in: question),
              let value = Int(question[range]) else { return nil }
        return max(value, 1)
    }

    private func detectNamedMonth(in question: String) -> Int? {
        let monthMap: [String: Int] = [
            "jan": 1, "january": 1,
            "feb": 2, "february": 2,
            "mar": 3, "march": 3,
            "apr": 4, "april": 4,
            "may": 5,
            "jun": 6, "june": 6,
            "jul": 7, "july": 7,
            "aug": 8, "august": 8,
            "sep": 9, "sept": 9, "september": 9,
            "oct": 10, "october": 10,
            "nov": 11, "november": 11,
            "dec": 12, "december": 12
        ]

        for (key, value) in monthMap where question.contains(key) {
            return value
        }
        return nil
    }

    private func monthName(from month: Int) -> String {
        let formatter = DateFormatter()
        return formatter.monthSymbols[max(month - 1, 0)].lowercased()
    }

    private func relevantDate(for shipment: NormalizedShipment) -> Date? {
        shipment.actualDate ?? shipment.plannedDate ?? shipment.shipmentDate
    }

    private func dimensionValue(for shipment: NormalizedShipment, dimension: InsightDimension) -> String {
        switch dimension {
        case .route:
            return shipment.route
        case .carrier:
            return shipment.carrier
        case .destination:
            return shipment.destination
        case .origin:
            return shipment.origin
        }
    }

    private func metricValue(for shipments: [NormalizedShipment], metric: InsightMetric) -> Double {
        switch metric {
        case .avgDelay:
            let delays = shipments.map(\.delayMinutes)
            guard !delays.isEmpty else { return 0 }
            return delays.reduce(0, +) / Double(delays.count)
        case .delayMinutes:
            return shipments.map(\.delayMinutes).reduce(0, +)
        case .shipmentCount:
            return Double(shipments.count)
        case .delayCount:
            return Double(shipments.filter(\.isDelayed).count)
        }
    }
}
