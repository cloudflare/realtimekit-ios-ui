// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "RealtimeKitUI",
    platforms: [.iOS(.v16)],
    products: [
        .library(name: "RealtimeKitUI", targets: ["RealtimeKitUI"]),
    ],
    dependencies: [
        .package(
            url: "https://github.com/cloudflare/realtimekit-ios-core.git",
            from: "3.1.0"
        ),
    ],
    targets: [
        .target(
            name: "RealtimeKitUI",
            dependencies: [
                .product(name: "RealtimeKit", package: "realtimekit-ios-core"),
                .product(name: "RTKWebRTC", package: "realtimekit-ios-core"),
            ],
            path: "RealtimeKitUI/",
            resources: [
                .process("Resources/notification_join.mp3"),
                .process("Resources/notification_message.mp3"),
            ]
        ),
    ]
)
