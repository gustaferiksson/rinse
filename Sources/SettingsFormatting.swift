import SwiftUI

struct FormattingSettings: View {
    @Bindable var settings: AppSettings
    @State private var sample = "  https://example.com/article?id=7&utm_source=newsletter  "

    var body: some View {
        let cleaned = clean(sample, options: settings.transforms)
        Form {
            Section {
                Toggle(isOn: $settings.transforms.removeInvisibles) {
                    Text("Remove invisible characters")
                    Text(verbatim: "Hi⟨zero-width space⟩there → Hithere").monospaced()
                }
                Toggle(isOn: $settings.transforms.trimWhitespace) {
                    Text("Trim leading and trailing whitespace")
                    Text(verbatim: "␣␣hello world␣⏎ → hello world").monospaced()
                }
                Toggle(isOn: $settings.transforms.straightenQuotes) {
                    Text("Normalize quotes")
                    Text(verbatim: "“Hello” ‘world’ → \"Hello\" 'world'").monospaced()
                }
            } header: {
                Text("Text")
            } footer: {
                Text("Fonts, colors, links and tables are always removed. These options also tidy the text itself.")
            }

            Section {
                Toggle(isOn: $settings.transforms.removeTrackingParameters) {
                    Text("Remove tracking parameters from URLs")
                    Text(verbatim: "https://x.com/?id=7&utm_source=a → https://x.com/?id=7").monospaced()
                }
                Toggle(isOn: $settings.transforms.stripMailto) {
                    Text("Remove mailto: prefix from email addresses")
                    Text(verbatim: "mailto:hi@example.com → hi@example.com").monospaced()
                }
                Toggle(isOn: $settings.transforms.stripTel) {
                    Text("Remove tel: prefix from phone numbers")
                    Text(verbatim: "tel:+46701234567 → +46701234567").monospaced()
                }
            } header: {
                Text("Links")
            } footer: {
                Text("Applies when the copied text is a single link or address.")
            }

            Section {
                TextField("Text to clean", text: $sample, prompt: Text("Paste or type text"), axis: .vertical)
                    .labelsHidden()
                    .textFieldStyle(.plain)
                    .font(.body.monospaced())
                    .lineLimit(1...4)
                LabeledContent("Result") {
                    Text(cleaned == sample ? "No changes" : cleaned)
                        .monospaced()
                        .foregroundStyle(cleaned == sample ? .secondary : .primary)
                        .textSelection(.enabled)
                        .multilineTextAlignment(.trailing)
                }
            } header: {
                Text("Try It")
            } footer: {
                Text("Paste text above to preview how Rinse cleans it with the options you've chosen.")
            }
        }
        .formStyle(.grouped)
        .frame(height: 650)
    }
}
