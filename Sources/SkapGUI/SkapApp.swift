import SkapCore
import SwiftUI

@main
struct SkapApp: App {
    @StateObject private var appModel = SkapAppModel()

    var body: some Scene {
        MenuBarExtra("skap", systemImage: "camera.viewfinder") {
            MenuBarView(appModel: appModel)
        }
        .menuBarExtraStyle(.menu)

        Settings {
            SettingsView(appModel: appModel)
        }
    }
}
