import SwiftUI

struct SettingsView: View {
    @ObservedObject var appModel: SkapAppModel

    var body: some View {
        Form {
            Section("Capture") {
                Toggle("Copy screenshots to clipboard immediately", isOn: .constant(true))
                    .disabled(true)
                LabeledContent("Saved area", value: appModel.savedAreaSummary)
                Button("Clear Saved Area") {
                    appModel.clearSavedArea()
                }
                .disabled(!appModel.hasSavedArea)
            }

            Section("Shortcuts") {
                Text("Capture Area: Cmd+Shift+2")
                    .foregroundStyle(.secondary)
                Text("Capture Same Area: Cmd+Shift+3")
                    .foregroundStyle(.secondary)
                Text("Capture Window: Cmd+Shift+4")
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .frame(width: 460, height: 300)
        .padding()
    }
}
