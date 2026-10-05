import SwiftUI

enum SettingsTab: String {
    case general, formatting, excludedApps, advanced, about
}

struct SettingsView: View {
    @Bindable var settings: AppSettings
    @AppStorage("settingsTab") private var tab = SettingsTab.general

    var body: some View {
        TabView(selection: $tab) {
            Tab("General", systemImage: "gearshape", value: .general) {
                GeneralSettings(settings: settings)
            }
            Tab("Formatting", systemImage: "textformat", value: .formatting) {
                FormattingSettings(settings: settings)
            }
            Tab("Excluded Apps", systemImage: "hand.raised", value: .excludedApps) {
                ExcludedAppsSettings(settings: settings)
            }
            Tab("Advanced", systemImage: "gearshape.2", value: .advanced) {
                AdvancedSettings(settings: settings)
            }
            Tab("About", systemImage: "info.circle", value: .about) {
                AboutSettings()
            }
        }
        .frame(width: 560)
        .onAppear { NSApp.activate() }
    }
}
