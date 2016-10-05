import XCTest
@testable import UnitTest

class ExpectedToFailTests: XCTestCase {
    func testFalse() {
        XCTAssertFalse(true)
        sleep(30)
    }
}
