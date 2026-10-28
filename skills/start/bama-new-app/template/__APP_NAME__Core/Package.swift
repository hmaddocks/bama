// swift-tools-version: 6.2
import PackageDescription

// Models, storage and logic. No AppKit or UIKit types: the compiler keeps UI
// out, the tests run without the app, and a UIKit app can share it later.
let package = Package(
    name: "__APP_NAME__Core",
    platforms: [.macOS(.v26), .iOS(.v26)],
    products: [
        .library(name: "__APP_NAME__Core", targets: ["__APP_NAME__Core"]),
    ],
    targets: [
        .target(
            name: "__APP_NAME__Core",
            // Compiled by CoreDataModelPlugin, not by SwiftPM's or Xcode's own
            // model handling, which would both claim it. See the plugin.
            exclude: ["Persistence/__APP_NAME__Core.xcdatamodeld"],
            plugins: ["CoreDataModelPlugin"]
        ),
        .testTarget(name: "__APP_NAME__CoreTests", dependencies: ["__APP_NAME__Core"]),
        .plugin(name: "CoreDataModelPlugin", capability: .buildTool()),
    ]
)
