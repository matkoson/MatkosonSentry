import XCTest
@testable import MatkosonSentry

final class MatkosonSentryTests: XCTestCase {
    func testDefaultDSNEnvKeysPreferShortFleetAlias() {
        let keys = MatkosonSentry.defaultDSNEnvKeys(app: "menubar")
        XCTAssertEqual(keys.first, "SENTRY_DSN_MEN")
        XCTAssertTrue(keys.contains("SENTRY_DSN_MENUBAR"))
        XCTAssertTrue(keys.contains("SENTRY_DSN"))
    }

    func testAgentAuthAlias() {
        let keys = MatkosonSentry.defaultDSNEnvKeys(app: "agent-auth")
        XCTAssertEqual(keys.first, "SENTRY_DSN_AGENTAUTH")
        XCTAssertTrue(keys.contains("SENTRY_DSN_AGENT_AUTH"))
    }

    func testResolveDSNPrecedenceShortOverFallback() {
        let env = [
            "SENTRY_DSN": "https://a@sentry.example/1",
            "SENTRY_DSN_MEN": "https://b@sentry.example/2",
        ]
        let dsn = MatkosonSentry.resolveDSN(
            envKeys: MatkosonSentry.defaultDSNEnvKeys(app: "menubar"),
            environment: env
        )
        XCTAssertEqual(dsn, "https://b@sentry.example/2")
    }

    func testMissingDSNSkipsBootstrap() {
        let result = MatkosonSentry.bootstrap(
            .init(app: "menubar"),
            environment: [:]
        )
        XCTAssertEqual(result, .skippedMissingDSN)
    }
}
