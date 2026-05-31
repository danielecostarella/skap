import SwiftUI

struct MenuBarView: View {
    @ObservedObject var appModel: SkapAppModel

    var body: some View {
        Button("Capture Full Screen") {
            Task { await appModel.captureScreen() }
        }
        .keyboardShortcut("1", modifiers: [.command, .shift])

        Button("Capture All Displays") {
            Task { await appModel.captureAllDisplays() }
        }

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

        SettingsLink {
            Text("Settings…")
        }

        Divider()

        Text(appModel.statusMessage)
            .foregroundStyle(.secondary)

        Divider()

        Button("Quit skap") {
            NSApplication.shared.terminate(nil)
        }
    }
}
