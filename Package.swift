// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "CopilotUsage",
    platforms: [.macOS(.v13)],
    products: [
        .executable(name: "copilot-usage", targets: ["CopilotUsageCLI"]),
    ],
    targets: [
        .target(name: "CopilotUsageCore"),
        .executableTarget(
            name: "CopilotUsageCLI",
            dependencies: ["CopilotUsageCore"]
        ),
    ]
)
