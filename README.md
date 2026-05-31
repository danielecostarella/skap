# skap

`skap` is a native, privacy-first macOS screenshot app: fast capture, instant clipboard, lightweight annotation, pin-to-screen, and a scriptable CLI.

Created and maintained by Daniele Costarella.

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

## Current Capture Modes

- `Capture Full Screen`: captures the main display and copies it to the clipboard.
- `Capture Window`: click a window to capture only that window.
- `Capture Area`: drag a rectangle to capture a portion of the screen.
- `Pin Window on Screen` / `Pin Area on Screen`: captures the target, copies it to the clipboard, and opens it as a floating reference window that stays above normal windows.

## Xcode

Open the package directly in Xcode:

```sh
xed .
```

The Swift package is the source of truth for targets and dependencies. A generated `.xcodeproj` can be added later for release signing and `.app` archive automation if needed.

## License

MIT. See [LICENSE](LICENSE).
