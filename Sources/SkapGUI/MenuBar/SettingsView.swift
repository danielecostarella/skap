import AppKit
import SkapCore
import SwiftUI

struct SettingsView: View {
    @ObservedObject var appModel: SkapAppModel

    var body: some View {
        Form {
            permissionsSection
            captureSection
            shortcutsSection
            savedAreaSection
        }
        .formStyle(.grouped)
        .frame(width: 520)
        .padding()
        .onAppear {
            appModel.refreshPermissionState()
        }
    }

    private var permissionsSection: some View {
        Section("Permissions") {
            LabeledContent("Screen Recording", value: appModel.screenRecordingPermissionSummary)
            Button("Request Permission") {
                appModel.requestScreenRecordingPermission()
            }
            Button("Open System Settings…") {
                appModel.openScreenRecordingSettings()
            }
        }
    }

    private var captureSection: some View {
        Section("Capture") {
            Toggle("Show capture HUD", isOn: $appModel.settings.showsCaptureHUD)
            Toggle("Copy to clipboard", isOn: $appModel.settings.copyToClipboard)
            Toggle("Play capture sound", isOn: $appModel.settings.captureSound)

            Divider()

            Toggle("Save to file", isOn: $appModel.settings.saveToFile)

            if appModel.settings.saveToFile {
                LabeledContent("Save folder") {
                    HStack {
                        Text(appModel.settings.defaultSaveFolder.lastPathComponent)
                            .foregroundStyle(.secondary)
                        Button("Choose…") {
                            chooseSaveFolder()
                        }
                    }
                }

                LabeledContent("Format") {
                    Picker("", selection: $appModel.settings.imageFormat) {
                        ForEach(ImageFormat.allCases, id: \.self) { format in
                            Text(format.displayName).tag(format)
                        }
                    }
                    .pickerStyle(.segmented)
                    .fixedSize()
                }

                if appModel.settings.imageFormat == .jpeg {
                    LabeledContent("JPEG quality") {
                        HStack {
                            Slider(value: $appModel.settings.jpegQuality, in: 0.1...1, step: 0.05)
                                .frame(width: 180)
                            Text("\(Int(appModel.settings.jpegQuality * 100))%")
                                .monospacedDigit()
                                .foregroundStyle(.secondary)
                                .frame(width: 44, alignment: .trailing)
                        }
                    }
                }
            }
        }
    }

    private var shortcutsSection: some View {
        Section("Shortcuts") {
            LabeledContent("Capture Screen") {
                shortcutRecorder(for: .captureScreen)
            }
            LabeledContent("Capture Area") {
                shortcutRecorder(for: .captureArea)
            }
            LabeledContent("Capture Saved Area") {
                shortcutRecorder(for: .captureSameArea)
            }
            LabeledContent("Capture Window") {
                shortcutRecorder(for: .captureWindow)
            }
            LabeledContent("Capture All Displays") {
                shortcutRecorder(for: .captureAllDisplays)
            }
        }
    }

    private var savedAreaSection: some View {
        Section("Saved Area") {
            LabeledContent("Saved area", value: appModel.savedAreaSummary)
            Button("Clear Saved Area") {
                appModel.clearSavedArea()
            }
            .disabled(!appModel.hasSavedArea)
        }
    }

    private func shortcutRecorder(for action: ShortcutAction) -> some View {
        ShortcutRecorderView(config: Binding(
            get: {
                appModel.settings.shortcuts[action] ?? ShortcutConfig.defaults[action] ?? ShortcutConfig(keyCode: 18, modifiers: 768)
            },
            set: { appModel.settings.shortcuts[action] = $0 }
        ))
        .frame(width: 140, height: 22)
    }

    private func chooseSaveFolder() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        panel.directoryURL = appModel.settings.defaultSaveFolder
        panel.prompt = "Choose"
        panel.message = "Select the folder where screenshots will be saved."

        if panel.runModal() == .OK, let url = panel.url {
            appModel.settings.defaultSaveFolder = url
        }
    }
}
