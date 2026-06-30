# SDK SOURCE — RealtimeKitUI

Atom/Molecule UIKit component library. All programmatic layout, no Storyboards.

## STRUCTURE

```
RealtimeKitUI/
├── Atoms/                    # Leaf UI components (18 files)
│   ├── RtkButton, RtkLabel, RtkTextField, RtkDropDown...
│   ├── RtkGridView           # Video tile grid layout engine
│   ├── RtkParticipantTileView # Single participant video tile
│   ├── RtkPeerView           # Raw peer video rendering
│   ├── RtkTopbar             # Meeting top navigation bar
│   └── Prebuilt/             # Message cells, plugin components
├── StandAloneComponent/      # Composite components (23 files)
│   ├── RtkMeetingControlBar  # Bottom control bar (mic/cam/end)
│   ├── RtkVideoView          # Video rendering with lifecycle
│   ├── RtkAvatarView         # Participant avatar with initials
│   ├── RtkLeaveDialog        # End/leave meeting confirmation
│   ├── Rtk*EventListener     # Meeting/Self/Participant event bridges
│   └── Rtk*ControlBar*       # Individual control bar buttons
├── Screens/                  # Full-screen VCs by feature
│   ├── Meeting/              # MeetingViewController (1100+ lines), WebinarViewController
│   ├── BreakoutRooms/        # Breakout room management (host controls, participant assignment)
│   ├── Setup/                # RtkSetupViewController — pre-meeting config
│   ├── Participants/         # ParticipantViewController + Webinar subdir
│   ├── Polls/                # Create/show polls
│   ├── LiveStream/           # Livestream variant
│   ├── Setting/              # In-meeting settings
│   ├── SearchController/     # Participant search
│   ├── Prebuilt/             # Prebuilt screen compositions
│   ├── Miscellaneous/        # Shared utilities (UIUtility, extensions)
│   └── Webinar/              # Webinar-specific screens
├── Tokens/                   # Design system tokens
│   ├── DesignLibrary.swift   # Master token registry (12KB)
│   ├── Colors/               # BackgroundColor, BrandColor, TextColor, StatusColor tokens
│   ├── Font/                 # FontToken definitions
│   ├── Spacing/              # SpacingToken definitions
│   └── BorderSize/           # BorderRadiusToken, BorderSizeToken
├── BaseClasses/              # VC and cell base classes
│   ├── RtkBaseViewController # Provides `meeting` client access to all VCs
│   └── BaseTableViewCell     # Reusable cell base
├── BaseProtocol/             # Core protocols
│   ├── BaseProtocols.swift   # Searchable, ReusableObject, SetTopbar, KeyboardObservable
│   └── CleanTableViewConfigurator # Generic table/collection view configurator pattern
└── PIP/                      # Picture-in-Picture support
```

## WHERE TO LOOK

| Task | Location | Notes |
|------|----------|-------|
| New leaf component | `Atoms/` | Conform to `BaseAtom` protocol |
| New composite component | `StandAloneComponent/` | Inherit `BaseMoleculeView` (note: typo `BaseMoluculeView`) |
| New screen | `Screens/{Feature}/` | Inherit `RtkBaseViewController` for `meeting` access |
| Modify control bar | `StandAloneComponent/RtkMeetingControlBar.swift` | Tab items defined here |
| Change colors/fonts | `Tokens/DesignLibrary.swift` | Central token registry |
| Add design token | `Tokens/{Category}/` | Create token class, register in DesignLibrary |
| Event handling | `StandAloneComponent/Rtk*EventListener.swift` | Bridges RealtimeKit events to UI |
| Video grid layout | `Atoms/RtkGridView.swift` | Custom grid layout engine |
| Table/collection setup | `BaseProtocol/CleanTableViewConfigurator.swift` | Generic configurator pattern |

## COMPONENT HIERARCHY

```
BaseAtom (protocol)
├── BaseAtomView (UIView)          → Atoms/*
├── BaseMoluculeView (UIView)      → StandAloneComponent/*  [typo is shipped API]
└── RtkBaseViewController (UIViewController) → Screens/*
```

All components access styling via `DesignLibrary.shared`. Never call `UIColor` / `UIFont` directly.

## CONVENTIONS (THIS DIRECTORY)

- **Naming**: `Rtk` prefix for all public types (e.g. `RtkButton`, `RtkGridView`)
- **Layout**: `NSLayoutConstraint` via `AutoLayoutable` protocol. No SnapKit/other libs
- **Event listeners**: Separate `*EventListener` classes bridge RealtimeKit SDK events → UI updates
- **View lifecycle**: Components use `createSubviews()` / `layoutSubviews()` pattern, not `init`
- **Token access**: `dyteSharedTokenColor.background.shade1000` — never raw hex/RGB

## ANTI-PATTERNS

- **Never subclass Atoms for screen-specific behavior** — compose in StandAloneComponent instead
- **Never put business logic in Atoms** — Atoms are pure UI; logic lives in ViewModels or event listeners
- **Never access `RealtimeKitClient` directly from Atoms** — only VCs (via `RtkBaseViewController.meeting`) and event listeners
- **Never create new singletons** — `Shared.data` and `DesignLibrary.shared` are existing tech debt
