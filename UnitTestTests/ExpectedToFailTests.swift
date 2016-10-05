import XCTest
@testable import UnitTest

class ExpectedToFailTests: XCTestCase {
    func testTrue() {
        XCTAssertTrue(false)
    }
    
    func testFalse() {
        XCTAssertFalse(false)
    }
}
