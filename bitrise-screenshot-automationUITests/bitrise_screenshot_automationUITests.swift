//
//  bitrise_screenshot_automationUITests.swift
//  bitrise-screenshot-automationUITests
//
//  Created by Alexander Botkin on 4/20/20.
//  Copyright © 2020 ChargePoint, Inc. All rights reserved.
//

import XCTest

enum SwipeDirection {
    case Up
    case Down
    case Left
    case Right
}

extension XCTestCase {
    func handleAlerts(app: XCUIApplication) {
        app.tap()
        // Handle UI interruptions such as alerts for location permissions
        self.addUIInterruptionMonitor(withDescription: "Handling system alerts") { element in
            if (element.buttons.count > 2) {
                // this is the case for location where there are 3 cases so we will pick the second option which is
                // use location while in app
                let whileInUseButton = element.buttons.secondLastMatch
                if (whileInUseButton.exists) {
                    whileInUseButton.tap()
                    app.tap()
                    return true
                }
            }
            
            return false
        }
    }
}

extension XCUIApplication {
    // Extend XCUIApplication to swipe in a certain direction a certain number of times
    func swipe(direction: SwipeDirection, numSwipes: Int) {
        switch direction {
        case .Up:
            for _ in 1...numSwipes {
                self.swipeUp()
            }
        case .Down:
            for _ in 1...numSwipes {
                self.swipeDown()
            }
        case .Left:
            for _ in 1...numSwipes {
                self.swipeLeft()
            }
        case .Right:
            for _ in 1...numSwipes {
                self.swipeRight()
            }
        }
    }
}

extension XCUIElementQuery {
    // Extend XCUIElementQuery to have easy ways to access matches
    var secondMatch: XCUIElement {return self.element(boundBy: 1)}
    var lastMatch: XCUIElement { return self.element(boundBy: self.count - 1) }
    var secondLastMatch: XCUIElement { return self.element(boundBy: self.count - 2) }
    var thirdLastMatch: XCUIElement { return self.element(boundBy: self.count - 3) }
}

class bitrise_screenshot_automationUITests: XCTestCase {
    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        
        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false
        
        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
        
        // UI tests must launch the application that they test.
        let app = XCUIApplication()
        app.launch()
        // Set up interruption handler
        self.handleAlerts(app: app)
    }
    
    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    func testMainViewScreenshot() throws {
        let app = XCUIApplication()
        
        // Let's ensure the view has appeared by using the accessibility identifier
        // we set up in the storyboard
        let darkMapVCView = app.otherElements["Dark Map View"];
        XCTAssertTrue(darkMapVCView.waitForExistence(timeout: 3))
        
        // Now let's get a screenshot & save it to the xcresult as an attachment
        self.saveScreenshot("MyAutomation_darkMapView")
    }
    
    func testTodayWidgetScreenshot() throws {
        let app = XCUIApplication()
        // The springboard app allows you to navigate the home screen
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        springboard.activate()
        
        // Swipe until we get to the Today View
        springboard.swipe(direction: .Right, numSwipes: 2)
        
        // Swipe until edit button is visible
        springboard.swipe(direction: .Up, numSwipes: 2)
        
        let editButton = springboard.buttons.firstMatch
        XCTAssertTrue(editButton.waitForExistence(timeout: 3))
        editButton.tap()
        
        // Swipe until Customize button is visible
        springboard.swipe(direction: .Up, numSwipes: 3)
        
        var customizeButton = springboard.buttons.secondLastMatch
        
        // If on an iPad or and iOS 16 iPhone, the customize button is the last match
        switch UIDevice.current.userInterfaceIdiom {
        case .phone:
            if #available(iOS 16, *) {
                customizeButton = springboard.buttons.lastMatch
            }
            break
        case .pad:
            customizeButton = springboard.buttons.lastMatch
            break
        default:
            break
        }
        
        customizeButton.tap()
        
        // Find and tap to add the TodayWidget
        let widgetNamePredicate = NSPredicate(format: "label CONTAINS[c] 'TodayWidget'")
        let addWidgetCells = springboard.cells.matching(widgetNamePredicate)
        addWidgetCells.buttons.firstMatch.tap()
        
        let doneButton = springboard.navigationBars.buttons.secondMatch
        doneButton.tap()
        
        springboard.swipe(direction: .Up, numSwipes: 1)
        let todayLabel = springboard.staticTexts["Today Label"]
        XCTAssertTrue(todayLabel.waitForExistence(timeout: 3))
        
        self.saveScreenshot("MyAutomation_todayWidget")
        
        // Remove today widget
        customizeButton = springboard.buttons.secondLastMatch
        customizeButton.tap()
        
        addWidgetCells.buttons.firstMatch.tap()
        addWidgetCells.buttons.lastMatch.tap()
        
        doneButton.tap()
        
        app.activate()
    }
    
    func testLockScreenWidgetScreenshot() throws {
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        springboard.activate()
        
        // Swipe down from the top to get to the lock screen
        let coord1 = springboard.coordinate(withNormalizedOffset: CGVector(dx: 0, dy: 0))
        let coord2 = springboard.coordinate(withNormalizedOffset: CGVector(dx: 0, dy: 2))
        coord1.press(forDuration: 0.1, thenDragTo: coord2)
        
        addLockScreenWidget()
        
        self.saveScreenshot("MyAutomation_lockScreenWidget")
        
        editLockScreenWidget()
        
        sleep(3)
        
        self.saveScreenshot("MyAutomation_configuredLockScreenWidget")
        
        removeLockScreenWidget()
    }
    
    func addLockScreenWidget() {
        // Press and hold to edit lock screen
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        springboard.press(forDuration: 3)
        
        // Tap Customize
        springboard.buttons.matching(identifier: "posterboard-customize-button").firstMatch.tap()
        
        // Tap to customize Lock Screen
        springboard.collectionViews["posterboard-collection-view"].cells.firstMatch.tap()
        
        // Use posterboard to navigate lock screen customization
        let posterboard = XCUIApplication(bundleIdentifier: "com.apple.PosterBoard")
        
        posterboard.buttons.lastMatch.tap()
        
        posterboard.cells["bitrise-screenshot-automation"].tap()
        
        springboard.buttons.lastMatch.tap()
        
        springboard.buttons.firstMatch.tap()
        
        springboard.buttons.firstMatch.tap()
        
        springboard.buttons.secondMatch.tap()
        
        springboard.tap()
    }
    
    func editLockScreenWidget() {
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        springboard.press(forDuration: 3)
        
        springboard.buttons.matching(identifier: "posterboard-customize-button").firstMatch.tap()
        
        springboard.collectionViews["posterboard-collection-view"].cells.firstMatch.tap()
        
        let posterboard = XCUIApplication(bundleIdentifier: "com.apple.PosterBoard")
        
        // Tap on widget when in customize mode to edit the configuration
        posterboard.buttons.firstMatch.tap()
        posterboard.buttons.secondMatch.tap()
        
        sleep(3)
        
        self.saveScreenshot("MyAutomation_lockScreenWidgetConfiguration")
        
        springboard.buttons.secondMatch.tap()
        
        // Type Cupertino in search field
        springboard.searchFields.firstMatch.tap()
        springboard.typeText("Cupertino\n")
        
        // Select Cupertino and close configuration view
        springboard.cells.firstMatch.tap()
        springboard.buttons.secondMatch.tap()
        springboard.buttons.firstMatch.tap()
        
        springboard.buttons.firstMatch.tap()
        springboard.buttons.secondMatch.tap()
        springboard.tap()
    }
    
    func removeLockScreenWidget() {
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        springboard.press(forDuration: 3)
        
        springboard.buttons.matching(identifier: "posterboard-customize-button").firstMatch.tap()
        
        springboard.collectionViews["posterboard-collection-view"].cells.firstMatch.tap()
        
        let posterboard = XCUIApplication(bundleIdentifier: "com.apple.PosterBoard")
        
        posterboard.buttons.firstMatch.tap()
        
        posterboard.buttons.firstMatch.tap()
        
        posterboard.buttons.firstMatch.tap()
        
        posterboard.buttons.secondMatch.tap()
        
        springboard.tap()
    }
    
    func testHomeScreenWidgetScreenshot() throws {
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        springboard.activate()
        
        addHomeScreenWidget(isMediumSize: false)
        addHomeScreenWidget(isMediumSize: true)
        
        self.saveScreenshot("MyAutomation_homeScreenWidgets")
        
        editHomeScreenWidgetConfig()
        
        sleep(3)
        
        self.saveScreenshot("MyAutomation_configuredHomeScreenWidget")
        
        removeHomeScreenWidget()
        removeHomeScreenWidget()
    }
    
    func editHomeScreenWidgetConfig() {
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        springboard.press(forDuration: 3)
        springboard.icons.matching(identifier: "bitrise-screenshot-automation").firstMatch.tap()
        
        // Use WidgetConfigurationExtension XCUIApplication to navigate the home screen widget configuration
        let widgetConfig = XCUIApplication(bundleIdentifier: "com.apple.WorkflowUI.WidgetConfigurationExtension")
        
        sleep(3)
        
        self.saveScreenshot("MyAutomation_homeScreenWidgetConfiguration")
        
        widgetConfig.buttons.firstMatch.tap()
        widgetConfig.searchFields.firstMatch.tap()
        widgetConfig.typeText("Cupertino\n")
        widgetConfig.cells.firstMatch.tap()
        widgetConfig.buttons.secondMatch.tap()
        
        // Dismiss configuration
        springboard.coordinate(withNormalizedOffset: CGVector(dx: 0, dy: 0)).tap()
        
        springboard.buttons.secondMatch.tap()
    }
    
    func removeHomeScreenWidget() {
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        springboard.press(forDuration: 3)
        
        springboard.icons.matching(identifier: "bitrise-screenshot-automation").firstMatch.buttons["DeleteButton"].tap()
        springboard.alerts.firstMatch.buttons.lastMatch.tap()
        springboard.buttons.secondMatch.tap()
    }
    
    func addHomeScreenWidget(isMediumSize: Bool) {
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        springboard.press(forDuration: 3)
        
        springboard.buttons.firstMatch.tap()
        
        springboard.searchFields.firstMatch.tap()
        
        springboard.typeText("bitrise-screenshot-automation")
        springboard.collectionViews.cells["bitrise-screenshot-automation"].tap()
        
        // Swipe to medium size widget if parameter passed is true
        if (isMediumSize) {
            springboard.swipe(direction: .Left, numSwipes: 1)
        }
        
        springboard.buttons.thirdLastMatch.tap()
        
        springboard.buttons.secondMatch.tap()
    }
    
    func testSiriShortcut() {
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        springboard.activate()
        // Use XCUISiriService to pass text to Siri and invoke App Shortcut
        XCUIDevice.shared.siriService.activate(voiceRecognitionText: "Run sample with bitrise-screenshot-automation")
        
        sleep(3)
        
        self.saveScreenshot("MyAutomation_sampleSiriShortcut")
    }
    
    func testNotificationCenter() {
        
        let app = XCUIApplication()
        let button = app.buttons["ZoomButton"]
        XCTAssertTrue(button.exists)
        button.tap()
        handleAlerts(app: app)
        // Springboard allows us to interact with the home screen
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        
        springboard.activate()
        // wait to make sure notification is sent
        sleep(2)
        // Swipe down from the top to get to the lock screen to view notifications
        let coord1 = springboard.coordinate(withNormalizedOffset: CGVector(dx: 0, dy: 0))
        
        let coord2 = springboard.coordinate(withNormalizedOffset: CGVector(dx: 0, dy: 2))
        
        coord1.press(forDuration: 0.1, thenDragTo: coord2)
        
        self.saveScreenshot("MyAutomation_Notification")
        
    }
    
}
