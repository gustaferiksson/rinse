import AppKit
import SwiftUI
import UniformTypeIdentifiers

private let knownAppNames = [
    "com.1password.1password": "1Password",
    "com.bitwarden.desktop": "Bitwarden",
    "org.keepassx.keepassxc": "KeePassXC",
    "com.hicknhacksoftware.MacPass": "MacPass",
    "com.markmcguill.strongbox": "Strongbox",
    "com.markmcguill.strongbox.pro": "Strongbox Pro",
    "com.lastpass.LastPass": "LastPass",
    "in.sinew.Enpass-Desktop": "Enpass",
    "me.proton.pass.electron": "Proton Pass",
    "com.keepersecurity.passwordmanager": "Keeper",
    "com.apple.Passwords": "Passwords",
    "com.apple.Passwords.MenuBarExtra": "Passwords Menu Bar Extra",
    "com.apple.keychainaccess": "Keychain Access",
    "com.microsoft.Excel": "Microsoft Excel",
]

struct ExcludedAppsSettings: View {
    @Bindable var settings: AppSettings
    @State private var selection = Set<String>()
    @State private var isChoosingApp = false
    @State private var runningApps = NSWorkspace.shared.runningApplications

    var body: some View {
        let addableApps = runningApps
            .filter { app in
                guard app.activationPolicy == .regular, let id = app.bundleIdentifier else { return false }
                return id != Bundle.main.bundleIdentifier && !settings.excludedBundleIDs.contains(id)
            }
            .sorted { ($0.localizedName ?? "").localizedStandardCompare($1.localizedName ?? "") == .orderedAscending }
        Form {
            Section {
                List(settings.excludedBundleIDs, id: \.self, selection: $selection) { bundleID in
                    ExcludedAppRow(bundleID: bundleID)
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .frame(height: 300)
                .onDeleteCommand(perform: removeSelected)
                .dropDestination(for: URL.self) { urls, _ in
                    add(urls)
                    return true
                }
                HStack(spacing: 2) {
                    Button("Add App…", systemImage: "plus") { isChoosingApp = true }
                        .labelStyle(.iconOnly)
                    Button("Remove", systemImage: "minus", action: removeSelected)
                        .labelStyle(.iconOnly)
                        .disabled(selection.isEmpty)
                    Spacer()
                    Menu("Add Running App") {
                        ForEach(addableApps, id: \.processIdentifier) { app in
                            Button {
                                settings.excludedBundleIDs.append(app.bundleIdentifier ?? "")
                            } label: {
                                Label {
                                    Text(app.localizedName ?? app.bundleIdentifier ?? "")
                                } icon: {
                                    Image(nsImage: app.icon ?? NSWorkspace.shared.icon(for: .applicationBundle))
                                }
                            }
                        }
                    }
                    .fixedSize()
                    .disabled(addableApps.isEmpty)
                    Button("Restore Defaults") { settings.excludedBundleIDs = defaultExcludedBundleIDs }
                        .disabled(settings.excludedBundleIDs == defaultExcludedBundleIDs)
                }
                .buttonStyle(.borderless)
            } header: {
                Text("Don't clear formatting when copying in these apps")
            } footer: {
                Text("Password managers that mark copied passwords as concealed are always skipped, even when they aren't listed. Drag apps here from the Finder to add them.")
            }
        }
        .formStyle(.grouped)
        .frame(height: 460)
        .fileImporter(isPresented: $isChoosingApp, allowedContentTypes: [.applicationBundle], allowsMultipleSelection: true) { result in
            guard case .success(let urls) = result else { return }
            add(urls)
        }
        .fileDialogDefaultDirectory(URL(filePath: "/Applications"))
        .onReceive(NSWorkspace.shared.notificationCenter.publisher(for: NSWorkspace.didLaunchApplicationNotification)) { _ in
            runningApps = NSWorkspace.shared.runningApplications
        }
        .onReceive(NSWorkspace.shared.notificationCenter.publisher(for: NSWorkspace.didTerminateApplicationNotification)) { _ in
            runningApps = NSWorkspace.shared.runningApplications
        }
    }

    private func add(_ urls: [URL]) {
        for id in urls.compactMap({ Bundle(url: $0)?.bundleIdentifier }) where !settings.excludedBundleIDs.contains(id) {
            settings.excludedBundleIDs.append(id)
        }
    }

    private func removeSelected() {
        settings.excludedBundleIDs.removeAll { selection.contains($0) }
        selection = []
    }
}

private struct ExcludedAppRow: View {
    let bundleID: String

    var body: some View {
        let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID)
        let name = url.map { FileManager.default.displayName(atPath: $0.path).replacing(/\.app$/, with: "") }
        HStack(spacing: 8) {
            Image(nsImage: url.map { NSWorkspace.shared.icon(forFile: $0.path) } ?? NSWorkspace.shared.icon(for: .applicationBundle))
                .resizable()
                .frame(width: 28, height: 28)
                .opacity(url == nil ? 0.5 : 1)
            VStack(alignment: .leading, spacing: 1) {
                Text(name ?? knownAppNames[bundleID] ?? bundleID)
                Text(url == nil ? "Not installed · \(bundleID)" : bundleID)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .lineLimit(1)
            .truncationMode(.middle)
        }
        .padding(.vertical, 2)
    }
}
