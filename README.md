# skap

![CI](https://github.com/danielecostarella/skap/actions/workflows/ci.yml/badge.svg)
![Release](https://img.shields.io/github/v/release/danielecostarella/skap)
![Platform](https://img.shields.io/badge/platform-macOS%2014%2B-lightgrey)
![Swift](https://img.shields.io/badge/Swift-6.0-orange)
![License](https://img.shields.io/badge/license-MIT-blue)

`skap` — short for **screenshot kapture** — is a native, privacy-first macOS screenshot app: fast capture, instant clipboard, reusable capture areas, annotation editor, and a scriptable CLI. Pronounced "es-kap" or however feels right to you.

The project is split into three modules:

- `SkapCore`: ScreenCaptureKit capture, clipboard, image processing, annotation renderer.
- `SkapGUI`: menu bar app, global shortcuts, SwiftUI overlays, annotation editor, onboarding.
- `skap-cli`: terminal interface powered by Swift Argument Parser.

## Try it

Build and open the app bundle:

```sh
bash scripts/package-app.sh
open dist/Skap.app
```

Or install to `~/Applications`:

```sh
bash scripts/install-app.sh
open ~/Applications/Skap.app
```

Set `INSTALL_DIR=/Applications` for the system Applications folder.

## Build from source

```sh
swift build
swift run Skap          # GUI app
swift run skap --help   # CLI
```

Open in Xcode:

```sh
xed .
```

## Capture modes

| Action | Shortcut (default) |
|--------|--------------------|
| Capture Full Screen | ⌘⇧1 |
| Capture Area | ⌘⇧2 |
| Capture Same Area | ⌘⇧3 |
| Capture Window | ⌘⇧4 |
| Capture All Displays | ⌘⇧5 |
| Edit Last Capture | menu |

All shortcuts are customisable in **Settings → Shortcuts**.

Saved areas remember the display they were selected on, keeping repeat captures predictable on multi-monitor setups.

## Settings

- **Show capture HUD** — floating thumbnail after every capture.
- **Play capture sound** — native macOS screenshot sound.
- **Copy to clipboard** — write the capture to the system clipboard.
- **Save to file** — auto-save every capture to a chosen folder.
- **Format** — PNG or JPEG.
- **Shortcuts** — click any shortcut field and press a new key combination.
- **Saved area** — shows coordinates and lets you clear the saved area.

## CLI

```sh
# Capture full screen
skap screen
skap screen --display all --format jpeg --output ~/Desktop/shot.jpg

# Capture a specific area (pixels on the main display)
skap area --rect 0,0,1280,800
skap area --rect 100,100,800,600 --display 1 --output ~/Desktop/shot.png --json

# Capture the area saved from the GUI
skap same-area
skap same-area --output ~/Desktop/area.png --format jpeg

# Capture active window
skap window --current

# Manage the saved area
skap saved-area show
skap saved-area show --json
skap saved-area clear

# Read/write settings
skap config list
skap config get format
skap config set save-to-file true
skap config set format jpeg
skap config set save-folder ~/Screenshots
```

### JSON output

All capture commands accept `--json` and print a structured result to stdout:

```json
{
  "success": true,
  "width": 1280,
  "height": 800,
  "format": "png",
  "path": "/Users/dan/Desktop/Screenshot 2026-05-31 at 15.00.00.png",
  "copiedToClipboard": false
}
```

## Annotation editor

After a capture, choose **Edit Last Capture** from the menu bar. A window opens with the captured image and a toolbar:

| Tool | Description |
|------|-------------|
| Arrow (→) | Directional arrow |
| Rectangle (□) | Stroked rectangle |
| Ellipse (○) | Stroked ellipse |
| Text (T) | Click to place text |
| Redact (👁‍🗨) | Pixelate a region |
| Highlight (✏️) | Semi-transparent yellow fill |

Click **Done** to apply annotations and copy the result to the clipboard. **Undo** removes the last element.

## Permissions

On first launch, skap shows a guided onboarding flow to request Screen Recording permission. After granting it in System Settings you may need to restart skap.

You can also manage permissions in **Settings → Permissions**.

## Release

Releases are built automatically by GitHub Actions when a tag is pushed:

```sh
git tag v1.0.0
git push origin v1.0.0
```

The workflow produces a signed `.app` bundle, a `.zip`, and a `.dmg`, then publishes a GitHub Release with checksums.

> **Notarisation** requires an Apple Developer account. The workflow contains commented-out steps — add `APPLE_ID`, `APPLE_TEAM_ID`, and `APPLE_APP_PASSWORD` as repository secrets to enable it.

## Homebrew

After the first release, install via a tap:

```sh
brew install --cask daniele-costarella/skap/skap
```

> The tap (`daniele-costarella/homebrew-skap`) is a separate repository created after the first stable release.

## Roadmap

- [ ] **Notarization** — requires Apple Developer account; unlock Gatekeeper-free distribution
- [ ] **Sparkle auto-update** — in-app update UI with delta downloads (blocked on notarization)
- [ ] **Homebrew tap** — `brew install --cask daniele-costarella/skap/skap`
- [ ] **Custom shortcuts UI polish** — keyboard shortcut recorder improvements
- [ ] **App Store** — long-term, pending sandboxing audit

## Maintainer

Created and maintained by [Daniele Costarella](https://github.com/danielecostarella).

Bugs, feature requests, and discussions: [GitHub Issues](https://github.com/danielecostarella/skap/issues).

## License

MIT. See [LICENSE](LICENSE).
