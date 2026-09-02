// swift-tools-version: 6.0
import PackageDescription

// Foundation-only business rules can be tested without launching an iOS simulator.
let package = Package(
    name: "BuybeeCore",
    platforms: [.macOS(.v13)],
    products: [.library(name: "BuybeeCore", targets: ["BuybeeCore"])],
    targets: [
        .target(name: "BuybeeCore", path: "Buybee/Core"),
        .testTarget(name: "BuybeeCoreTests", dependencies: ["BuybeeCore"], path: "Tests/BuybeeCoreTests")
    ]
)
