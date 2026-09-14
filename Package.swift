// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "MatkosonSentry",
    platforms: [.macOS(.v13)],
    products: [
        .library(name: "MatkosonSentry", targets: ["MatkosonSentry"]),
    ],
    dependencies: [
        .package(url: "https://github.com/getsentry/sentry-cocoa", from: "8.36.0"),
    ],
    targets: [
        .target(
            name: "MatkosonSentry",
            dependencies: [
                .product(name: "Sentry", package: "sentry-cocoa"),
            ]
        ),
        .testTarget(
            name: "MatkosonSentryTests",
            dependencies: ["MatkosonSentry"]
        ),
    ]
)
