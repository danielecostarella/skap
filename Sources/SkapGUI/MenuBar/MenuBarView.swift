import SwiftUI

struct MenuBarView: View {
    @ObservedObject var appModel: SkapAppModel

    var body: some View {
        Button("Capture Full Screen") {
            Task { await appModel.captureScreen() }
        }

        Button("Capture Window") {
            appModel.beginWindowCapture()
        }

        Button("Capture Area") {
            appModel.beginAreaCapture()
        }

        Button("Capture Same Area") {
            appModel.captureSavedArea()
        }
        .disabled(!appModel.hasSavedArea)

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
