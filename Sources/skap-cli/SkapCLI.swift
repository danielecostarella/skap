import ArgumentParser
import CoreGraphics
import Foundation
import SkapCore

@main
struct SkapCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "skap",
        abstract: "A fast, native macOS screenshot tool.",
        subcommands: [
            Window.self,
            Area.self,
            SameArea.self,
            Screen.self,
            SavedAreaCommand.self,
            ConfigCommand.self,
        ]
    )
}

// MARK: - Shared types

struct CaptureResult: Codable {
    let success: Bool
    let width: Int
    let height: Int
    let format: String
    let path: String?
    let copiedToClipboard: Bool
}

func printResult(_ result: CaptureResult, json: Bool) throws {
    if json {
        let data = try JSONEncoder().encode(result)
        print(String(decoding: data, as: UTF8.self))
    } else {
        var parts: [String] = []
        if result.copiedToClipboard { parts.append("copied to clipboard") }
        if let path = result.path { parts.append("saved to \(path)") }
        print("\(result.width)×\(result.height) — \(parts.joined(separator: ", "))")
    }
}

// MARK: - Window

struct Window: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "Capture a window."
    )

    @Flag(name: .long, help: "Capture the currently active window.")
    var current = false

    @Option(name: .long, help: "Write the screenshot to this path.")
    var output: String?

    @Flag(name: .long, help: "Output result as JSON.")
    var json = false

    func run() async throws {
        guard current else {
            throw ValidationError("Use --current. Window picking by ID is not yet implemented.")
        }

        let outputURL = output.map { URL(fileURLWithPath: NSString(string: $0).expandingTildeInPath) }
        let coordinator = SkapCoordinator()
        let image = try await coordinator.capture(
            options: CaptureOptions(
                mode: .window(.current),
                copyToClipboard: outputURL == nil,
                outputURL: outputURL
            )
        )

        try printResult(CaptureResult(
            success: true,
            width: image.cgImage.width,
            height: image.cgImage.height,
            format: "png",
            path: outputURL?.path,
            copiedToClipboard: outputURL == nil
        ), json: json)
    }
}

// MARK: - Area

struct Area: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "Capture a specific area of the screen."
    )

    @Option(name: .long, help: "Area as 'x,y,width,height' in pixels.")
    var rect: String?

    @Option(name: .long, help: "Display ID (default: main display).")
    var display: CGDirectDisplayID?

    @Option(name: .long, help: "Image format: png or jpeg (default: png).")
    var format: String = "png"

    @Option(name: .long, help: "Write the screenshot to this path.")
    var output: String?

    @Flag(name: .long, help: "Output result as JSON.")
    var json = false

    func run() async throws {
        guard let rectString = rect else {
            throw ValidationError("Specify --rect x,y,width,height. Interactive area selection requires the GUI.")
        }

        let parsedRect = try parseRect(rectString)
        let displayID = display ?? CGMainDisplayID()
        let area = CaptureArea(displayID: displayID, pixelRect: parsedRect)
        let imageFormat = try parseFormat(format)
        let outputURL = output.map { URL(fileURLWithPath: NSString(string: $0).expandingTildeInPath) }

        let coordinator = SkapCoordinator()
        let image = try await coordinator.capture(
            options: CaptureOptions(
                mode: .area(area),
                copyToClipboard: outputURL == nil,
                outputURL: outputURL,
                imageFormat: imageFormat
            )
        )

        try printResult(CaptureResult(
            success: true,
            width: image.cgImage.width,
            height: image.cgImage.height,
            format: imageFormat.rawValue,
            path: outputURL?.path,
            copiedToClipboard: outputURL == nil
        ), json: json)
    }

    private func parseRect(_ string: String) throws -> CGRect {
        let parts = string.split(separator: ",").compactMap { Double($0.trimmingCharacters(in: .whitespaces)) }
        guard parts.count == 4 else {
            throw ValidationError("--rect must be 'x,y,width,height' (four numbers separated by commas).")
        }
        guard parts[2] > 0, parts[3] > 0 else {
            throw ValidationError("Width and height must be greater than zero.")
        }
        return CGRect(x: parts[0], y: parts[1], width: parts[2], height: parts[3])
    }
}

// MARK: - SameArea

struct SameArea: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "same-area",
        abstract: "Capture the last area selected in the GUI."
    )

    @Option(name: .long, help: "Write the screenshot to this path.")
    var output: String?

    @Option(name: .long, help: "Image format: png or jpeg (default: png).")
    var format: String = "png"

    @Flag(name: .long, help: "Output result as JSON.")
    var json = false

    func run() async throws {
        let store = SavedCaptureAreaStore()

        guard let savedArea = store.savedArea else {
            throw ValidationError("No saved area found. Use 'Capture Area' in the GUI first.")
        }

        let imageFormat = try parseFormat(format)
        let outputURL = output.map { URL(fileURLWithPath: NSString(string: $0).expandingTildeInPath) }
        let coordinator = SkapCoordinator()
        let image = try await coordinator.capture(
            options: CaptureOptions(
                mode: .area(savedArea),
                copyToClipboard: outputURL == nil,
                outputURL: outputURL,
                imageFormat: imageFormat
            )
        )

        try printResult(CaptureResult(
            success: true,
            width: image.cgImage.width,
            height: image.cgImage.height,
            format: imageFormat.rawValue,
            path: outputURL?.path,
            copiedToClipboard: outputURL == nil
        ), json: json)
    }
}

// MARK: - Screen

struct Screen: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "Capture the full screen."
    )

    @Option(name: .long, help: "Write the screenshot to this path.")
    var output: String?

    @Option(name: .long, help: "Display to capture: main, all, or a numeric display ID.")
    var display = "main"

    @Option(name: .long, help: "Image format: png or jpeg (default: png).")
    var format: String = "png"

    @Flag(name: .long, help: "Output result as JSON.")
    var json = false

    func run() async throws {
        let imageFormat = try parseFormat(format)
        let outputURL = output.map { URL(fileURLWithPath: NSString(string: $0).expandingTildeInPath) }
        let coordinator = SkapCoordinator()
        let image = try await coordinator.capture(
            options: CaptureOptions(
                mode: .screen(try screenSelection()),
                copyToClipboard: outputURL == nil,
                outputURL: outputURL,
                imageFormat: imageFormat
            )
        )

        try printResult(CaptureResult(
            success: true,
            width: image.cgImage.width,
            height: image.cgImage.height,
            format: imageFormat.rawValue,
            path: outputURL?.path,
            copiedToClipboard: outputURL == nil
        ), json: json)
    }

    private func screenSelection() throws -> ScreenSelection {
        switch display.lowercased() {
        case "main": return .main
        case "all":  return .all
        default:
            guard let displayID = CGDirectDisplayID(display) else {
                throw ValidationError("--display must be 'main', 'all', or a numeric display ID.")
            }
            return .display(displayID)
        }
    }
}

// MARK: - saved-area

struct SavedAreaCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "saved-area",
        abstract: "Manage the saved capture area.",
        subcommands: [ShowSavedArea.self, ClearSavedArea.self]
    )
}

struct ShowSavedArea: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "show",
        abstract: "Print the saved area coordinates."
    )

    @Flag(name: .long, help: "Output as JSON.")
    var json = false

    func run() async throws {
        let store = SavedCaptureAreaStore()
        guard let area = store.savedArea else {
            if json {
                print("{\"saved\": false}")
            } else {
                print("No saved area.")
            }
            return
        }

        if json {
            struct AreaOutput: Codable {
                let saved: Bool
                let displayID: UInt32
                let x, y, width, height: Double
            }
            let out = AreaOutput(
                saved: true,
                displayID: area.displayID,
                x: area.pixelRect.origin.x,
                y: area.pixelRect.origin.y,
                width: area.pixelRect.width,
                height: area.pixelRect.height
            )
            let data = try JSONEncoder().encode(out)
            print(String(decoding: data, as: UTF8.self))
        } else {
            print("Saved area: \(Int(area.pixelRect.width))×\(Int(area.pixelRect.height)) at (\(Int(area.pixelRect.minX)), \(Int(area.pixelRect.minY))) on display \(area.displayID)")
        }
    }
}

struct ClearSavedArea: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "clear",
        abstract: "Remove the saved capture area."
    )

    func run() async throws {
        let store = SavedCaptureAreaStore()
        if store.savedArea == nil {
            print("No saved area to clear.")
        } else {
            store.savedArea = nil
            print("Saved area cleared.")
        }
    }
}

// MARK: - config

struct ConfigCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "config",
        abstract: "Read and write skap settings.",
        subcommands: [ConfigList.self, ConfigGet.self, ConfigSet.self]
    )
}

private let configKeys = ["hud", "clipboard", "save-to-file", "save-folder", "format", "sound"]

struct ConfigList: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "list",
        abstract: "Print all settings."
    )

    func run() async throws {
        let settings = SkapSettingsStore().settings
        print("hud            = \(settings.showsCaptureHUD)")
        print("clipboard      = \(settings.copyToClipboard)")
        print("save-to-file   = \(settings.saveToFile)")
        print("save-folder    = \(settings.defaultSaveFolder.path)")
        print("format         = \(settings.imageFormat.rawValue)")
        print("sound          = \(settings.captureSound)")
    }
}

struct ConfigGet: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "get",
        abstract: "Print one setting value."
    )

    @Argument(help: "Setting key: \(configKeys.joined(separator: ", "))")
    var key: String

    func run() async throws {
        let settings = SkapSettingsStore().settings
        switch key {
        case "hud":          print(settings.showsCaptureHUD)
        case "clipboard":    print(settings.copyToClipboard)
        case "save-to-file": print(settings.saveToFile)
        case "save-folder":  print(settings.defaultSaveFolder.path)
        case "format":       print(settings.imageFormat.rawValue)
        case "sound":        print(settings.captureSound)
        default:
            throw ValidationError("Unknown key '\(key)'. Available: \(configKeys.joined(separator: ", "))")
        }
    }
}

struct ConfigSet: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "set",
        abstract: "Update a setting value."
    )

    @Argument(help: "Setting key: \(configKeys.joined(separator: ", "))")
    var key: String

    @Argument(help: "New value.")
    var value: String

    func run() async throws {
        let store = SkapSettingsStore()
        var settings = store.settings

        switch key {
        case "hud":
            settings.showsCaptureHUD = try parseBool(value, key: key)
        case "clipboard":
            settings.copyToClipboard = try parseBool(value, key: key)
        case "save-to-file":
            settings.saveToFile = try parseBool(value, key: key)
        case "save-folder":
            let url = URL(fileURLWithPath: NSString(string: value).expandingTildeInPath)
            guard FileManager.default.fileExists(atPath: url.path) else {
                throw ValidationError("Folder '\(value)' does not exist.")
            }
            settings.defaultSaveFolder = url
        case "format":
            guard let format = ImageFormat(rawValue: value.lowercased()) else {
                throw ValidationError("Invalid format '\(value)'. Use 'png' or 'jpeg'.")
            }
            settings.imageFormat = format
        case "sound":
            settings.captureSound = try parseBool(value, key: key)
        default:
            throw ValidationError("Unknown key '\(key)'. Available: \(configKeys.joined(separator: ", "))")
        }

        store.settings = settings
        print("Set \(key) = \(value)")
    }

    private func parseBool(_ string: String, key: String) throws -> Bool {
        switch string.lowercased() {
        case "true", "1", "yes", "on":   return true
        case "false", "0", "no", "off":  return false
        default:
            throw ValidationError("'\(key)' expects true/false, got '\(string)'.")
        }
    }
}

// MARK: - Helpers

private func parseFormat(_ string: String) throws -> ImageFormat {
    guard let format = ImageFormat(rawValue: string.lowercased()) else {
        throw ValidationError("Invalid format '\(string)'. Use 'png' or 'jpeg'.")
    }
    return format
}
