import SwiftUI

struct MenuBarView: View {
    @ObservedObject var appModel: SkapAppModel

    var body: some View {
        Button("Capture Full Screen") {
            Task { await appModel.captureScreen() }
        }
        .keyboardShortcut("1", modifiers: [.command, .shift])

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

        Button("Edit Last Capture (coming soon)") {}
            .disabled(true)

        Divider()

        Text(appModel.statusMessage)

        Divider()

        Button("Quit") {
            NSApplication.shared.terminate(nil)
        }
    }
}
