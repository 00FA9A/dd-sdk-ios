import XCTest
@testable import Datadog

// swiftlint:disable multiline_arguments_brackets trailing_closure
class LogConsoleOutputTests: XCTestCase {
    private let logBuilder = LogBuilder(
        appContext: AppContext(
            bundleIdentifier: "com.datadoghq.ios-sdk",
            bundleVersion: "1.0.0",
            bundleShortVersion: "1.0.0"
        ),
        serviceName: "test-service",
        loggerName: "test-logger-name",
        dateProvider: RelativeDateProvider(
            using: .mockDecember15th2019At10AMUTC()
        ),
        userInfoProvider: .mockWith(
            userInfo: UserInfo(id: "abc-123", name: "Foo", email: "foo@example.com")
        )
    )

    func testItPrintsLogsUsingShortFormat() {
        var messagePrinted: String = ""

        let output1 = LogConsoleOutput(
            logBuilder: logBuilder,
            format: .short,
            printingFunction: { messagePrinted = $0 },
            timeFormatter: LogConsoleOutput.shortTimeFormatter(calendar: .gregorian, timeZone: .UTC)
        )
        output1.writeLogWith(level: .info, message: "Info message.", attributes: [:], tags: [])
        XCTAssertEqual(messagePrinted, "10:00:00 [INFO] Info message.")

        let output2 = LogConsoleOutput(
            logBuilder: logBuilder,
            format: .shortWith(prefix: "🐶 "),
            printingFunction: { messagePrinted = $0 },
            timeFormatter: LogConsoleOutput.shortTimeFormatter(calendar: .gregorian, timeZone: .UTC)
        )
        output2.writeLogWith(level: .info, message: "Info message.", attributes: [:], tags: [])
        XCTAssertEqual(messagePrinted, "🐶 10:00:00 [INFO] Info message.")
    }

    func testItPrintsLogsUsingJSONFormat() {
        var messagePrinted: String = ""

        let output1 = LogConsoleOutput(
            logBuilder: logBuilder,
            format: .json,
            printingFunction: { messagePrinted = $0 }
        )
        output1.writeLogWith(level: .info, message: "Info message.", attributes: [:], tags: [])
        assertThat(jsonObjectData: messagePrinted.utf8Data, fullyMatches: """
        {
          "status" : "INFO",
          "message" : "Info message.",
          "service" : "test-service",
          "logger.name" : "test-logger-name",
          "logger.version": "\(sdkVersion)",
          "logger.thread_name" : "main",
          "date" : "2019-12-15T10:00:00Z",
          "application.version": "1.0.0"
        }
        """)

        let output2 = LogConsoleOutput(
            logBuilder: logBuilder,
            format: .jsonWith(prefix: "🐶 → "),
            printingFunction: { messagePrinted = $0 }
        )
        output2.writeLogWith(level: .info, message: "Info message.", attributes: [:], tags: [])
        XCTAssertTrue(messagePrinted.hasPrefix("🐶 → "))
        assertThat(jsonObjectData: messagePrinted.removingPrefix("🐶 → ").utf8Data, fullyMatches: """
        {
          "status" : "INFO",
          "message" : "Info message.",
          "service" : "test-service",
          "logger.name" : "test-logger-name",
          "logger.version": "\(sdkVersion)",
          "logger.thread_name" : "main",
          "date" : "2019-12-15T10:00:00Z",
          "application.version": "1.0.0"
        }
        """)
    }
}
