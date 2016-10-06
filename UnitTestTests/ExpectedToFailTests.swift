import XCTest
@testable import UnitTest

class ExpectedToFailTests: XCTestCase {
    func testTrue() {
        XCTAssertFalse(true)
    }

    func testFalse() {
        XCTAssertTrue(false)
    }
}
