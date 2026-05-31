import SwiftUI

struct MenuBarView: View {
    @ObservedObject var appModel: SkapAppModel
    @Environment(\.openSettings) private var openSettings

    private var updateChecker: UpdateChecker { appModel.updateChecker }

    var body: some View {
        Button("Capture Full Screen") {
            Task { await appModel.captureScreen() }
        }
        .keyboardShortcut("1", modifiers: [.command, .shift])

        Button("Capture All Displays") {
            Task { await appModel.captureAllDisplays() }
        }
        .keyboardShortcut("5", modifiers: [.command, .shift])

        Button("Capture Window") {
            appModel.beginWindowCapture()
        }
        .keyboardShortcut("4", modifiers: [.command, .shift])

        Button("Capture Area") {
            appModel.beginAreaCapture()
        }
        .keyboardShortcut("2", modifiers: [.command, .shift])

        Button("Capture Same Area") {
            appModel.captureSavedArea()
        }
        .disabled(!appModel.hasSavedArea)
        .keyboardShortcut("3", modifiers: [.command, .shift])

        Button("Edit Last Capture") {
            appModel.editLastCapture()
        }
        .disabled(appModel.lastCapture == nil)

        Divider()

        Button("Settings…") {
            NSApplication.shared.activate(ignoringOtherApps: true)
            openSettings()
        }

        Divider()

        Text(appModel.statusMessage)
            .foregroundStyle(.secondary)

        if let version = updateChecker.availableVersion {
            Divider()
            Button("Update available: v\(version)") {
                NSWorkspace.shared.open(URL(string: "https://github.com/danielecostarella/skap/releases/latest")!)
            }
        }

        Divider()

        Button("Quit skap") {
            NSApplication.shared.terminate(nil)
        }
    }
}
