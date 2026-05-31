import SwiftUI

struct OnboardingView: View {
    @State private var step: Step = .intro

    var onDismiss: () -> Void = {}

    private enum Step {
        case intro, requesting, granted, denied
    }

    var body: some View {
        VStack(spacing: 0) {
            content
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(40)

            Divider()

            footer
                .padding(.horizontal, 24)
                .padding(.vertical, 16)
        }
        .frame(width: 480, height: 360)
    }

    @ViewBuilder
    private var content: some View {
        switch step {
        case .intro:
            introView
        case .requesting:
            requestingView
        case .granted:
            grantedView
        case .denied:
            deniedView
        }
    }

    private var introView: some View {
        VStack(spacing: 20) {
            Image(systemName: "camera.viewfinder")
                .font(.system(size: 56))
                .foregroundStyle(.tint)
                .symbolRenderingMode(.hierarchical)

            VStack(spacing: 8) {
                Text("skap needs Screen Recording")
                    .font(.title2)
                    .fontWeight(.semibold)

                Text("To capture screenshots, skap needs permission to record your screen. Your screenshots are never stored or transmitted — they stay on your Mac.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
    }

    private var requestingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
                .frame(height: 56)

            Text("Waiting for permission…")
                .font(.title2)
                .fontWeight(.semibold)

            Text("A system dialog may appear. Grant Screen Recording access to continue.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
    }

    private var grantedView: some View {
        VStack(spacing: 20) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 56))
                .foregroundStyle(.green)
                .symbolRenderingMode(.multicolor)

            VStack(spacing: 8) {
                Text("All set!")
                    .font(.title2)
                    .fontWeight(.semibold)

                Text("skap is ready to capture your screen.")
                    .font(.body)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var deniedView: some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.shield.fill")
                .font(.system(size: 56))
                .foregroundStyle(.orange)
                .symbolRenderingMode(.multicolor)

            VStack(spacing: 8) {
                Text("Permission not granted")
                    .font(.title2)
                    .fontWeight(.semibold)

                Text("Open System Settings and enable Screen Recording for skap. You may need to restart skap after granting access.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
    }

    @ViewBuilder
    private var footer: some View {
        switch step {
        case .intro:
            HStack {
                Button("Later") { onDismiss() }
                    .keyboardShortcut(.cancelAction)
                Spacer()
                Button("Continue") {
                    requestPermission()
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.defaultAction)
            }

        case .requesting:
            HStack {
                Spacer()
                Button("Cancel") {
                    step = .intro
                }
            }

        case .granted:
            HStack {
                Spacer()
                Button("Get Started") { onDismiss() }
                    .buttonStyle(.borderedProminent)
                    .keyboardShortcut(.defaultAction)
            }

        case .denied:
            HStack {
                Button("Dismiss") { onDismiss() }
                    .keyboardShortcut(.cancelAction)
                Spacer()
                Button("Open System Settings…") {
                    ScreenRecordingPermission.openSystemSettings()
                    onDismiss()
                }
                .buttonStyle(.borderedProminent)
            }
        }
    }

    private func requestPermission() {
        step = .requesting
        let granted = ScreenRecordingPermission.request()
        if granted {
            step = .granted
        } else {
            step = .denied
        }
    }
}
