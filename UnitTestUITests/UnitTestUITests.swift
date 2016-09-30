//
//  UnitTestUITests.swift
//  UnitTestUITests
//
//  Created by Pivotal on 9/30/16.
//  Copyright © 2016 Pivotal. All rights reserved.
//

import XCTest

class UnitTestUITests: XCTestCase {
    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        XCUIApplication().launch()
    }
    func testOne() {
        let app = XCUIApplication()
        let presentButton = app.buttons["Present"]
        presentButton.tap()
        
        let dismissButton = app.buttons["Dismiss"]
        dismissButton.tap()
        presentButton.tap()
        dismissButton.tap()
        presentButton.tap()
        dismissButton.tap()
        presentButton.tap()
        dismissButton.tap()
    }

    func testTwo() {
        let app = XCUIApplication()
        let presentButton = app.buttons["Present"]
        presentButton.tap()
        
        let dismissButton = app.buttons["Dismiss"]
        dismissButton.tap()
        presentButton.tap()
        dismissButton.tap()
        presentButton.tap()
        dismissButton.tap()
        presentButton.tap()
        dismissButton.tap()
    }
}
