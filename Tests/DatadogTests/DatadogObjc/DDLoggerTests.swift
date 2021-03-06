/*
* Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
* This product includes software developed at Datadog (https://www.datadoghq.com/).
* Copyright 2019-2020 Datadog, Inc.
*/

import XCTest
@testable import Datadog
@testable import DatadogObjc

// swiftlint:disable multiline_arguments_brackets
// swiftlint:disable compiler_protocol_init
class DDLoggerTests: XCTestCase {
    override func setUp() {
        super.setUp()
        XCTAssertNil(Datadog.instance)
        temporaryDirectory.create()
    }

    override func tearDown() {
        XCTAssertNil(Datadog.instance)
        temporaryDirectory.delete()
        super.tearDown()
    }

    func testSendingLogWithCustomizedLogger() throws {
        try DatadogInstanceMock.builder
            .initialize()
            .run {
                let objcBuilder = DDLogger.builder()
                objcBuilder.set(serviceName: "objc-service-name")
                objcBuilder.set(loggerName: "objc-logger-name")
                objcBuilder.sendLogsToDatadog(true)
                objcBuilder.printLogsToConsole(false)

                let objcLogger = objcBuilder.build()
                objcLogger.debug("message")
            }
            .waitUntil(numberOfLogsSent: 1)
            .verifyFirst { logMatcher in
                logMatcher.assertServiceName(equals: "objc-service-name")
                logMatcher.assertLoggerName(equals: "objc-logger-name")
            }
            .destroy()
    }

    func testSendingLogsWithDifferentLevels() throws {
        try DatadogInstanceMock.builder
            .initialize()
            .run {
                let objcLogger = DDLogger.builder().build()

                objcLogger.debug("message")
                objcLogger.info("message")
                objcLogger.notice("message")
                objcLogger.warn("message")
                objcLogger.error("message")
                objcLogger.critical("message")
            }
            .waitUntil(numberOfLogsSent: 6)
            .verifyAll { logMatchers in
                logMatchers[0].assertStatus(equals: "DEBUG")
                logMatchers[1].assertStatus(equals: "INFO")
                logMatchers[2].assertStatus(equals: "NOTICE")
                logMatchers[3].assertStatus(equals: "WARN")
                logMatchers[4].assertStatus(equals: "ERROR")
                logMatchers[5].assertStatus(equals: "CRITICAL")
            }
            .destroy()
    }

    // MARK: - Sending attributes

    func testSendingLoggerAttributes() throws {
        try DatadogInstanceMock.builder
            .initialize()
            .run {
                let objcLogger = DDLogger.builder().build()

                objcLogger.addAttribute(forKey: "nsstring", value: NSString(string: "hello"))
                objcLogger.addAttribute(forKey: "nsbool", value: NSNumber(booleanLiteral: true))
                objcLogger.addAttribute(forKey: "nsint", value: NSInteger(integerLiteral: 10))
                objcLogger.addAttribute(forKey: "nsnumber", value: NSNumber(value: 10.5))
                objcLogger.addAttribute(forKey: "nsnull", value: NSNull())
                objcLogger.addAttribute(forKey: "nsurl", value: NSURL(string: "http://apple.com")!)
                objcLogger.addAttribute(
                    forKey: "nsarray-of-int",
                    value: NSArray(array: [1, 2, 3])
                )
                objcLogger.addAttribute(
                    forKey: "nsdictionary-of-date",
                    value: NSDictionary(dictionary: [
                        "date1": Date.mockDecember15th2019At10AMUTC(),
                        "date2": Date.mockDecember15th2019At10AMUTC(addingTimeInterval: 60 * 60)
                    ])
                )
                objcLogger.info("message")
            }
            .waitUntil(numberOfLogsSent: 1)
            .verifyFirst { logMatcher in
                logMatcher.assertValue(forKey: "nsstring", equals: "hello")
                logMatcher.assertValue(forKey: "nsbool", equals: true)
                logMatcher.assertValue(forKey: "nsint", equals: 10)
                logMatcher.assertValue(forKey: "nsnumber", equals: 10.5)
                logMatcher.assertValue(forKeyPath: "nsnull", isTypeOf: Optional<Any>.self)
                logMatcher.assertValue(forKey: "nsurl", equals: "http://apple.com")
                logMatcher.assertValue(forKey: "nsarray-of-int", equals: [1, 2, 3])
                logMatcher.assertValue(forKeyPath: "nsdictionary-of-date.date1", equals: "2019-12-15T10:00:00Z")
                logMatcher.assertValue(forKeyPath: "nsdictionary-of-date.date2", equals: "2019-12-15T11:00:00Z")
            }
            .destroy()
    }
}
// swiftlint:enable multiline_arguments_brackets
// swiftlint:enable compiler_protocol_init
