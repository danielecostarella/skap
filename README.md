# skap

`skap` is a native, privacy-first macOS screenshot app: fast capture, instant clipboard, lightweight annotation, pin-to-screen, and a scriptable CLI.

The project is intentionally split into three modules:

- `SkapCore`: ScreenCaptureKit capture, clipboard, image processing, annotation models.
- `SkapGUI`: menu bar app, global shortcut handling, SwiftUI overlay editor, pinned screenshot windows.
- `skap-cli`: terminal interface powered by Swift Argument Parser.

## Build

```sh
swift build
```

## Run

```sh
swift run Skap
swift run skap --help
```

## Xcode

Open the package directly in Xcode:

```sh
xed .
```

The Swift package is the source of truth for targets and dependencies. A generated `.xcodeproj` can be added later for release signing and `.app` archive automation if needed.
