//
//  QuickUITests.swift
//  QuickUITests
//
//  Created by Pivotal on 10/3/16.
//  Copyright © 2016 Pivotal. All rights reserved.
//

import XCTest
import Quick

class QuickOneUITests: QuickSpec {
    override func spec() {
        beforeEach {
            self.continueAfterFailure = false
            XCUIApplication().launch()
        }

        it("should do the thing") {
            let app = XCUIApplication()
            let presentButton = app.buttons["Present"]
            presentButton.tap()
            
            let dismissButton = app.buttons["Dismiss"]
            dismissButton.tap()
            presentButton.tap()
            dismissButton.tap()
            
            sleep(60)
            
            presentButton.tap()
            dismissButton.tap()
            presentButton.tap()
            dismissButton.tap()
        }
    }
 }
