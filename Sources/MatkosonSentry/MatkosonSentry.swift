import Foundation
import Sentry

/// Shared bootstrap for Matkoson macOS fleet apps against self-hosted Sentry.
public enum MatkosonSentry {
    public struct Options: Sendable {
        public var app: String
        public var bundleIdentifier: String?
        public var release: String?
        public var dsnEnvKeys: [String]
        public var enableAutoSessionTracking: Bool

        public init(
            app: String,
            bundleIdentifier: String? = Bundle.main.bundleIdentifier,
            release: String? = nil,
            dsnEnvKeys: [String] = [],
            enableAutoSessionTracking: Bool = true
        ) {
            self.app = app
            self.bundleIdentifier = bundleIdentifier
            self.release = release
            self.dsnEnvKeys = dsnEnvKeys
            self.enableAutoSessionTracking = enableAutoSessionTracking
        }
    }

    public enum BootstrapResult: Equatable, Sendable {
        case started(dsnHost: String)
        case skippedMissingDSN
    }

    /// Short aliases minted into ~/.env by fleet self-hosted Sentry setup.
    private static let shortDSNAliases: [String: [String]] = [
        "menubar": ["SENTRY_DSN_MEN", "SENTRY_DSN_MENUBAR"],
        "automation": ["SENTRY_DSN_AUTO", "SENTRY_DSN_AUTOMATION"],
        "aerospace": ["SENTRY_DSN_AER", "SENTRY_DSN_AEROSPACE"],
        "engine": ["SENTRY_DSN_ENGINE"],
        "agent-auth": ["SENTRY_DSN_AGENTAUTH", "SENTRY_DSN_AGENT_AUTH"],
        "control": ["SENTRY_DSN_CONTROL"],
        "clui": ["SENTRY_DSN_CLUI"],
        "routine-worker": ["SENTRY_DSN_RW", "SENTRY_DSN_ROUTINE_WORKER"],
    ]

    /// Resolve DSN from environment without logging secret material.
    public static func resolveDSN(envKeys: [String], environment: [String: String] = ProcessInfo.processInfo.environment) -> String? {
        for key in envKeys {
            if let value = environment[key], !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                return value
            }
        }
        return nil
    }

    public static func defaultDSNEnvKeys(app: String) -> [String] {
        let normalized = app
            .lowercased()
            .trimmingCharacters(in: .whitespacesAndNewlines)
        var keys: [String] = shortDSNAliases[normalized] ?? []
        let upper = normalized
            .uppercased()
            .replacingOccurrences(of: "-", with: "_")
            .replacingOccurrences(of: " ", with: "_")
        let longKey = "SENTRY_DSN_\(upper)"
        if !keys.contains(longKey) {
            keys.append(longKey)
        }
        keys.append(contentsOf: ["SENTRY_DSN", "MATKOSON_SENTRY_DSN"])
        return keys
    }

    public static func defaultRelease(bundle: Bundle = .main) -> String {
        let version = bundle.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "0"
        let build = bundle.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "0"
        return "\(version)+\(build)"
    }

    @discardableResult
    public static func bootstrap(_ options: Options, environment: [String: String] = ProcessInfo.processInfo.environment) -> BootstrapResult {
        let keys = options.dsnEnvKeys.isEmpty ? defaultDSNEnvKeys(app: options.app) : options.dsnEnvKeys
        guard let dsn = resolveDSN(envKeys: keys, environment: environment) else {
            return .skippedMissingDSN
        }

        SentrySDK.start { cfg in
            cfg.dsn = dsn
            cfg.environment = environment["SENTRY_ENVIRONMENT"]
                ?? environment["SAND_SENTRY_ENVIRONMENT"]
                ?? "development"
            cfg.releaseName = options.release
                ?? environment["SENTRY_RELEASE"]
                ?? environment["SAND_SENTRY_RELEASE"]
                ?? defaultRelease()
            cfg.enableAutoSessionTracking = options.enableAutoSessionTracking
            cfg.beforeSend = { event in
                event.tags = (event.tags ?? [:]).merging([
                    "app": options.app,
                    "bundle_id": options.bundleIdentifier ?? "unknown",
                    "host": ProcessInfo.processInfo.hostName,
                ]) { _, new in new }
                return event
            }
        }

        let host = URL(string: dsn)?.host ?? "configured"
        return .started(dsnHost: host)
    }

    public static func captureSmokeMessage(_ message: String = "matkoson-sentry-smoke") {
        SentrySDK.capture(message: message)
    }
}
