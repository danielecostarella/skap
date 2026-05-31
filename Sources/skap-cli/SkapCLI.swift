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
            Last.self
        ]
    )
}

struct Window: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "Capture a window."
    )

    @Flag(name: .long, help: "Capture the currently active window.")
    var current = false

    func run() async throws {
        guard current else {
            throw ValidationError("Use --current until window picking is implemented.")
        }

        let coordinator = SkapCoordinator()
        _ = try await coordinator.capture(options: CaptureOptions(mode: .window(.current)))
    }
}

struct Area: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "Select and capture an area."
    )

    @Flag(name: .long, help: "Pin the captured area as a floating window.")
    var pin = false

    func run() async throws {
        throw ValidationError("Interactive area selection is implemented in the GUI target next.")
    }
}

struct SameArea: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "same-area",
        abstract: "Capture the last area selected in the GUI."
    )

    @Option(name: .long, help: "Write the screenshot to this path.")
    var output: String?

    func run() async throws {
        let store = SavedCaptureAreaStore()

        guard let savedArea = store.savedArea else {
            throw ValidationError("No saved area found. Use Capture Area in the GUI first.")
        }

        let outputURL = output.map { URL(fileURLWithPath: NSString(string: $0).expandingTildeInPath) }
        let coordinator = SkapCoordinator()
        _ = try await coordinator.capture(
            options: CaptureOptions(
                mode: .area(savedArea),
                copyToClipboard: outputURL == nil,
                outputURL: outputURL
            )
        )
    }
}

struct Screen: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "Capture the full screen."
    )

    @Option(name: .long, help: "Write the screenshot to this path.")
    var output: String?

    @Option(name: .long, help: "Display to capture: main, all, or a numeric display ID.")
    var display = "main"

    func run() async throws {
        let outputURL = output.map { URL(fileURLWithPath: NSString(string: $0).expandingTildeInPath) }
        let coordinator = SkapCoordinator()
        _ = try await coordinator.capture(
            options: CaptureOptions(
                mode: .screen(try screenSelection()),
                copyToClipboard: outputURL == nil,
                outputURL: outputURL
            )
        )
    }

    private func screenSelection() throws -> ScreenSelection {
        switch display.lowercased() {
        case "main":
            return .main
        case "all":
            return .all
        default:
            guard let displayID = CGDirectDisplayID(display) else {
                throw ValidationError("--display must be main, all, or a numeric display ID.")
            }
            return .display(displayID)
        }
    }
}

struct Last: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "Work with the last screenshot."
    )

    @Flag(name: .long, help: "Open the last screenshot in the annotation editor.")
    var edit = false

    func run() async throws {
        guard edit else {
            throw ValidationError("Use --edit.")
        }

        throw ValidationError("Last capture persistence is not implemented yet.")
    }
}
