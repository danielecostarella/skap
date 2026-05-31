import SwiftUI

struct SettingsView: View {
    @ObservedObject var appModel: SkapAppModel

    var body: some View {
        Form {
            Section("Permissions") {
                LabeledContent("Screen Recording", value: appModel.screenRecordingPermissionSummary)
                Button("Request Screen Recording Permission") {
                    appModel.requestScreenRecordingPermission()
                }
                Button("Open Screen Recording Settings") {
                    appModel.openScreenRecordingSettings()
                }
            }

            Section("Capture") {
                Toggle("Show capture HUD", isOn: $appModel.showsCaptureHUD)
                Toggle("Copy screenshots to clipboard immediately", isOn: .constant(true))
                    .disabled(true)
                LabeledContent("Saved area", value: appModel.savedAreaSummary)
                Button("Clear Saved Area") {
                    appModel.clearSavedArea()
                }
                .disabled(!appModel.hasSavedArea)
            }

            Section("Shortcuts") {
                Text("Capture Full Screen: Cmd+Shift+1")
                    .foregroundStyle(.secondary)
                Text("Capture Area: Cmd+Shift+2")
                    .foregroundStyle(.secondary)
                Text("Capture Same Area: Cmd+Shift+3")
                    .foregroundStyle(.secondary)
                Text("Capture Window: Cmd+Shift+4")
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .frame(width: 500, height: 380)
        .padding()
        .onAppear {
            appModel.refreshPermissionState()
        }
    }
}
