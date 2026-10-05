import ServiceManagement
import SwiftUI

struct GeneralSettings: View {
    @Bindable var settings: AppSettings
    @Environment(AppUpdater.self) private var updater
    @State private var loginStatus = SMAppService.mainApp.status
    @State private var loginError: String?

    var body: some View {
        Form {
            Section {
                Toggle(isOn: $settings.isEnabled) {
                    Text("Clear formatting automatically")
                    Text("Text you copy becomes plain text right away, so it pastes in the style of the document you paste into.")
                }
            } footer: {
                Text("To keep formatting for a single copy, hold ⌥ Option while you copy.")
            }

            Section {
                Toggle("Launch at login", isOn: Binding(
                    get: { loginStatus == .enabled || loginStatus == .requiresApproval },
                    set: setLaunchAtLogin
                ))
                if loginStatus == .requiresApproval {
                    LabeledContent {
                        Button("Open Login Items…") { SMAppService.openSystemSettingsLoginItems() }
                    } label: {
                        Text("Approval needed")
                        Text("Allow Rinse in System Settings to finish turning this on.")
                    }
                }
                if let loginError {
                    Text(loginError)
                        .font(.callout)
                        .foregroundStyle(.red)
                }
            }

            Section {
                Toggle("Show menu bar icon", isOn: $settings.showMenuBarIcon)
            } header: {
                Text("Menu Bar")
            } footer: {
                Text("When hidden, open Rinse again to show Settings.")
            }

            Section {
                LabeledContent {
                    Image(systemName: "switch.2")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                } label: {
                    Text("Add a Rinse control")
                    Text("Open Control Center, choose Edit Controls, then add Rinse to turn automatic clearing on or off from Control Center or the menu bar.")
                }
            } header: {
                Text("Control Center")
            }

            Section("Updates") {
                LabeledContent("Version", value: AppUpdater.currentVersion)
                HStack(spacing: 8) {
                    updateStatus
                    Spacer()
                    if updater.isBusy {
                        ProgressView()
                            .controlSize(.small)
                            .accessibilityLabel(updater.status == .checking ? "Checking" : "Downloading")
                    }
                    if let staged = updater.staged {
                        Button("Install Rinse \(staged.version) and Relaunch", action: updater.installAndRelaunch)
                    } else {
                        Button("Check for Updates") { updater.check(.manual) }
                            .disabled(updater.isBusy)
                    }
                }
            }
        }
        .formStyle(.grouped)
        .frame(height: 590)
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            loginStatus = SMAppService.mainApp.status
        }
    }

    @ViewBuilder private var updateStatus: some View {
        if updater.status == .checking {
            Text("Checking for updates…").font(.callout).foregroundStyle(.secondary)
        } else if updater.status == .downloading {
            Text("Downloading the update…").font(.callout).foregroundStyle(.secondary)
        } else if case .upToDate(let version) = updater.status {
            Text("Rinse \(version) is the latest version.").font(.callout).foregroundStyle(.secondary)
        } else if case .ready(let version) = updater.status {
            Text("Rinse \(version) is ready to install.").font(.callout)
        } else if case .blocked(let message) = updater.status {
            Text(message).font(.callout).foregroundStyle(.orange)
        } else if case .failed(let message) = updater.status {
            Text(message).font(.callout).foregroundStyle(.red)
        }
    }

    private func setLaunchAtLogin(_ isOn: Bool) {
        do {
            if isOn { try SMAppService.mainApp.register() } else { try SMAppService.mainApp.unregister() }
            loginError = nil
        } catch {
            loginError = "Couldn't change Launch at login: \(error.localizedDescription)"
        }
        loginStatus = SMAppService.mainApp.status
    }
}
