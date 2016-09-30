import XCTest
@testable import UnitTest

class UnitTestTests: XCTestCase {
    func testTrue() {
        sleep(30)
        XCTAssertTrue(true)
    }
    
    func testFalse() {
        sleep(30)
        XCTAssertFalse(false)
    }
}
