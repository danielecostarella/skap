# skap

`skap` is a native, privacy-first macOS screenshot app: fast capture, instant clipboard, reusable capture areas, lightweight annotation, and a scriptable CLI.

Created and maintained by Daniele Costarella.

The project is intentionally split into three modules:

- `SkapCore`: ScreenCaptureKit capture, clipboard, image processing, annotation models.
- `SkapGUI`: menu bar app, global shortcut handling, SwiftUI overlay editor, and reusable capture areas.
- `skap-cli`: terminal interface powered by Swift Argument Parser.

## Build

```sh
swift build
```

## Package the macOS App

```sh
scripts/package-app.sh
open dist/Skap.app
```

The generated app bundle uses `com.danielecostarella.skap` as its bundle identifier and is ad-hoc signed for local development.

To install the generated app locally:

```sh
scripts/install-app.sh
open ~/Applications/Skap.app
```

Set `INSTALL_DIR=/Applications` if you want to install into the system Applications folder.

To regenerate the app icon:

```sh
scripts/generate-app-icon.swift
```

## Run

```sh
swift run Skap
swift run skap --help
```

## Current Capture Modes

- `Capture Full Screen`: captures the main display and copies it to the clipboard.
- `Capture Window`: click a window to capture only that window.
- `skap window --current`: captures the frontmost window from scripts or automation.
- `Capture Area`: drag a rectangle to capture a portion of the screen. The selected area is saved for reuse.
- `Capture Same Area`: captures the last selected area again without asking you to redraw it.
- Saved areas remember the display they were selected on, which keeps repeat captures predictable on multi-monitor setups.
- Settings show the saved area coordinates and let you clear the saved area.
- Settings show whether macOS Screen Recording permission is granted.
- `skap same-area`: captures the saved area from scripts or automation.

## Default Shortcuts

- `Cmd+Shift+1`: Capture Full Screen.
- `Cmd+Shift+2`: Capture Area.
- `Cmd+Shift+3`: Capture Same Area.
- `Cmd+Shift+4`: Capture Window.

## Xcode

Open the package directly in Xcode:

```sh
xed .
```

The Swift package is the source of truth for targets and dependencies. A generated `.xcodeproj` can be added later for release signing and `.app` archive automation if needed.

## License

MIT. See [LICENSE](LICENSE).
