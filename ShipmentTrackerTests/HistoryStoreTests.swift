import XCTest
@testable import ShipmentTracker

final class HistoryStoreTests: XCTestCase {
    private var defaults: UserDefaults!
    private var store: HistoryStore!
    private var suiteName = ""

    override func setUp() {
        super.setUp()
        suiteName = "history-tests-\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suiteName)
        store = HistoryStore(store: LocalStore(defaults: defaults))
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: suiteName)
        super.tearDown()
    }

    func testHistoryPersistsPerUser() {
        let item = sampleItem(fileName: "shipments.csv")
        store.saveHistoryItem(item, for: "a@test.com")
        store.saveHistoryItem(sampleItem(fileName: "other.csv"), for: "b@test.com")

        XCTAssertEqual(store.loadHistory(for: "a@test.com").count, 1)
        XCTAssertEqual(store.loadHistory(for: "a@test.com").first?.fileName, "shipments.csv")
        XCTAssertEqual(store.loadHistory(for: "b@test.com").count, 1)
    }

    func testHistoryCappedAtFortyItems() {
        for idx in 0..<45 {
            store.saveHistoryItem(sampleItem(fileName: "f\(idx).csv"), for: "cap@test.com")
        }
        XCTAssertEqual(store.loadHistory(for: "cap@test.com").count, 40)
    }

    private func sampleItem(fileName: String) -> HistoryItem {
        HistoryItem(
            id: UUID(),
            createdAt: Date(),
            updatedAt: Date(),
            fileName: fileName,
            question: "top routes",
            recordCount: 10,
            note: "ok",
            csvRows: [["shipment_id": "1"]],
            csvColumns: ["shipment_id"],
            insight: nil
        )
    }
}
