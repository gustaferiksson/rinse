import AppIntents
import SwiftUI
import WidgetKit

@main
struct RinseControlBundle: WidgetBundle {
    var body: some Widget {
        RinseToggle()
    }
}

struct RinseToggle: ControlWidget {
    var body: some ControlWidgetConfiguration {
        StaticControlConfiguration(kind: RinseDefaults.controlKind, provider: Provider()) { isOn in
            ControlWidgetToggle("Rinse", isOn: isOn, action: SetRinseEnabledIntent()) { isOn in
                Label("Clear Formatting", systemImage: isOn ? "drop.fill" : "drop")
            }
        }
        .displayName("Rinse")
        .description("Automatically clear formatting from copied text.")
    }

    struct Provider: ControlValueProvider {
        var previewValue: Bool { true }

        func currentValue() async throws -> Bool {
            UserDefaults(suiteName: RinseDefaults.suiteName)?.object(forKey: RinseDefaults.isEnabledKey) as? Bool ?? true
        }
    }
}

struct SetRinseEnabledIntent: SetValueIntent {
    static let title: LocalizedStringResource = "Clear Formatting"

    @Parameter(title: "Enabled")
    var value: Bool

    func perform() async throws -> some IntentResult {
        UserDefaults(suiteName: RinseDefaults.suiteName)?.set(value, forKey: RinseDefaults.isEnabledKey)
        return .result()
    }
}
