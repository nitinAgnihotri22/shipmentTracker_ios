import XCTest
@testable import ShipmentTracker

final class InsightEngineTests: XCTestCase {
    private let engine = InsightEngine()
    private let now = ISO8601DateFormatter().date(from: "2026-03-20T10:00:00Z")!

    func testQuestionParsingDimensionMetricAndTopN() {
        let parsed = engine.parseQuestion("show top 3 carrier average delays table", now: now)
        XCTAssertEqual(parsed.dimension, .carrier)
        XCTAssertEqual(parsed.metric, .avgDelay)
        XCTAssertEqual(parsed.topN, 3)
        XCTAssertTrue(parsed.showTable)
        XCTAssertFalse(parsed.showChart)
    }

    func testQuestionParsingTimeWindowLastNDays() {
        let parsed = engine.parseQuestion("last 7 days route chart", now: now)
        let inside = ISO8601DateFormatter().date(from: "2026-03-18T10:00:00Z")
        let outside = ISO8601DateFormatter().date(from: "2026-03-01T10:00:00Z")
        XCTAssertTrue(parsed.dateFilter(inside))
        XCTAssertFalse(parsed.dateFilter(outside))
    }

    func testAggregationSortsDescending() throws {
        let shipments = [
            makeShipment(id: "1", route: "A", carrier: "Fast", destination: "X", origin: "O", delay: 40, delayed: true),
            makeShipment(id: "2", route: "A", carrier: "Fast", destination: "X", origin: "O", delay: 20, delayed: true),
            makeShipment(id: "3", route: "B", carrier: "ShipCo", destination: "Y", origin: "O", delay: 10, delayed: true)
        ]

        let result = try engine.analyze(question: "top 2 route total delay chart", shipments: shipments, now: now)
        XCTAssertEqual(result.rows.first?.label, "A")
        XCTAssertEqual(result.rows.first?.value ?? -1, 60, accuracy: 0.1)
        XCTAssertEqual(result.rows.last?.label, "B")
    }

    private func makeShipment(id: String, route: String, carrier: String, destination: String, origin: String, delay: Double, delayed: Bool) -> NormalizedShipment {
        NormalizedShipment(
            id: id,
            route: route,
            carrier: carrier,
            origin: origin,
            destination: destination,
            plannedDate: now,
            actualDate: now,
            shipmentDate: now,
            delayMinutes: delay,
            status: delayed ? "Delayed" : "Delivered",
            isDelayed: delayed
        )
    }
}
