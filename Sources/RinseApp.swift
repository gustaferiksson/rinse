import SwiftUI

@main
struct RinseApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @Bindable private var settings = AppSettings.shared

    var body: some Scene {
        MenuBarExtra(isInserted: $settings.showMenuBarIcon) {
            Toggle("Enabled", isOn: $settings.isEnabled)
            Divider()
            UpdateMenuItems(updater: appDelegate.updater)
            SettingsLink { Text("Settings…") }
                .keyboardShortcut(",")
            Button("Quit Rinse") { NSApp.terminate(nil) }
                .keyboardShortcut("q")
        } label: {
            Image(systemName: settings.isEnabled ? "drop.fill" : "drop")
        }
        .menuBarExtraStyle(.menu)

        Settings {
            SettingsView(settings: settings)
                .environment(appDelegate.updater)
        }
    }
}

private struct UpdateMenuItems: View {
    let updater: AppUpdater

    var body: some View {
        if let staged = updater.staged {
            Button("Install Rinse \(staged.version) and Relaunch", action: updater.installAndRelaunch)
        } else {
            Button(checkTitle) { updater.check(.manual) }
                .disabled(updater.isBusy)
        }
        if let note {
            Text(note)
        }
    }

    private var checkTitle: String {
        if updater.status == .checking { return "Checking for Updates…" }
        if updater.status == .downloading { return "Downloading Update…" }
        return "Check for Updates…"
    }

    private var note: String? {
        if case .upToDate(let version) = updater.status { return "Rinse \(version) is the latest version." }
        if case .blocked(let message) = updater.status { return message }
        if case .failed(let message) = updater.status { return message }
        return nil
    }
}
