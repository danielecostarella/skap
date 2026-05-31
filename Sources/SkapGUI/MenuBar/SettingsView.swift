import SwiftUI

struct SettingsView: View {
    @ObservedObject var appModel: SkapAppModel

    var body: some View {
        Form {
            Section("Capture") {
                Toggle("Copy screenshots to clipboard immediately", isOn: .constant(true))
                Text("Global shortcut customization will live here.")
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .frame(width: 420, height: 220)
        .padding()
    }
}
