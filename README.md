<p align="center">
  <a href="https://www.cloudflare.com/">
    <img src="https://cf-assets.www.cloudflare.com/slt3lc6tev37/6EYsdkdfBcHtgPmgp3YtkD/0b203affd2053988264b9253b13de6b3/logo-thumbnail.png" alt="Cloudflare" width="200" />
  </a>
  <h2 align="center">RealtimeKit UI Kit for iOS</h2>
</p>

A prebuilt UIKit component library for building video and audio call interfaces in iOS apps. RealtimeKitUI provides ready-to-use UI components — from low-level atoms to full-screen layouts — built on top of the [RealtimeKit Core SDK](https://github.com/cloudflare/realtimekit-ios-core).

## Installation

Add RealtimeKitUI to your project using Swift Package Manager:

1. In Xcode, go to **File > Add Package Dependencies...**
2. Enter the repository URL:
   ```
   https://github.com/cloudflare/realtimekit-ios-ui.git
   ```
3. Select your desired version rule and add `RealtimeKitUI` to your target

### Package.swift

Add the dependency to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/cloudflare/realtimekit-ios-ui.git", from: "<version>")
]
```

Then add the product to your target:

```swift
.target(
    name: "YourApp",
    dependencies: [
        .product(name: "RealtimeKitUI", package: "realtimekit-ios-ui"),
    ]
)
```

The package will automatically resolve its dependencies on `RealtimeKit` and `RTKWebRTC` from the Core SDK.

## Components Overview

RealtimeKitUI follows a layered **Atom / Component / Screen** architecture:

### Atoms
Foundational UI elements that serve as building blocks:
- `RtkButton`, `RtkLabel`, `RtkTextField` — styled controls
- `RtkGridView`, `RtkPeerView` — participant layout primitives
- `RtkAvatar`, `RtkNotificationView` — status and identity elements

### Components
Composed UI modules built from atoms:
- `RtkVideoView` — renders a participant's video stream
- `RtkControlBar` — meeting control buttons (mic, camera, leave, etc.)

### Screens
Full-screen layouts for common call workflows:
- **Meeting** — main call interface with grid/active speaker views
- **Setup** — pre-call preview with audio/video device selection
- **Chat** — in-call messaging
- **Participants** — participant list and management
- **Polls** — in-call polling
- **LiveStream** — live streaming interface

### PIP Support
Picture-in-Picture support for multitasking during active calls.

## Design Tokens

Customize the look and feel of all components through design tokens:

| Token | Description |
|-------|-------------|
| **Colors** | Theme colors, backgrounds, text colors |
| **Font** | Typography styles and sizes |
| **Spacing** | Padding and margin values |
| **BorderSize** | Border widths and radii |

## Requirements

| Requirement | Minimum |
|-------------|---------|
| iOS | 13.0+ |
| Swift | 5.5+ |
| Xcode | 13.0+ |

## Documentation

For full guides, API reference, and examples, visit the [RealtimeKit iOS documentation](https://developers.cloudflare.com/realtime/realtimekit/ui-kit/).

## License

See [LICENSE](LICENSE) for details.
