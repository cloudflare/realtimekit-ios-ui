// swift-tools-version:5.5
import PackageDescription

let package = Package(
    name: "RealtimeKitUI",
    platforms: [.iOS(.v13)],
    products: [
        .library(name: "RealtimeKitUI", targets: ["RealtimeKitUI"]),
    ],
    dependencies: [
        .package(
            url: "https://github.com/dyte-in/RealtimeKitCoreiOS.git",
            from: "1.3.2"
        ),
    ],
    targets: [
        .target(
            name: "RealtimeKitUI",
            dependencies: [
                .product(name: "RealtimeKit", package: "RealtimeKitCoreiOS"),
                .product(name: "RTKWebRTC", package: "RealtimeKitCoreiOS"),
            ],
            path: "RealtimeKitUI/",
            resources: [
                .process("Resources/notification_join.mp3"),
                .process("Resources/notification_message.mp3"),
            ]
        ),
    ]
)
