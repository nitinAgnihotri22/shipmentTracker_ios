import XCTest
@testable import ShipmentTracker

final class CSVParserServiceTests: XCTestCase {
    private let parser = CSVParserService()

    func testParserRejectsMissingRequiredFields() throws {
        let url = try tempCSV("""
        shipment_id,route,carrier,origin,destination
        1,,Carrier A,Delhi,Mumbai
        """)

        XCTAssertThrowsError(try parser.parse(fileURL: url)) { error in
            XCTAssertTrue((error as? CSVValidationError) == .requiredFields(["Row 2: missing required field(s): route."]))
        }
    }

    func testParserReadsValidCSV() throws {
        let url = try tempCSV("""
        shipment_id,route,carrier,origin,destination
        1,R1,Carrier A,Delhi,Mumbai
        """)

        let result = try parser.parse(fileURL: url)
        XCTAssertEqual(result.rows.count, 1)
        XCTAssertEqual(result.columns, ["shipment_id", "route", "carrier", "origin", "destination"])
    }

    private func tempCSV(_ content: String) throws -> URL {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString).appendingPathExtension("csv")
        let data = try XCTUnwrap(content.data(using: .utf8))
        try data.write(to: url)
        return url
    }
}
