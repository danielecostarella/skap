import ArgumentParser
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

struct Screen: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "Capture the full screen."
    )

    @Option(name: .long, help: "Write the screenshot to this path.")
    var output: String?

    func run() async throws {
        let outputURL = output.map { URL(fileURLWithPath: NSString(string: $0).expandingTildeInPath) }
        let coordinator = SkapCoordinator()
        _ = try await coordinator.capture(
            options: CaptureOptions(
                mode: .screen,
                copyToClipboard: outputURL == nil,
                outputURL: outputURL
            )
        )
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
