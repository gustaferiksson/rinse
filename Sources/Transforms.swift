import Foundation

struct TransformOptions: Equatable {
    var removeInvisibles = true
    var trimWhitespace = true
    var straightenQuotes = false
    var removeTrackingParameters = true
    var stripMailto = true
    var stripTel = true
}

func clean(_ text: String, options: TransformOptions) -> String {
    let steps: [(isOn: Bool, apply: (String) -> String)] = [
        (options.removeInvisibles, removeInvisibles),
        (options.trimWhitespace, trimWhitespace),
        (options.straightenQuotes, straightenQuotes),
        (options.removeTrackingParameters, removeTrackingParameters),
        (options.stripMailto, stripMailto),
        (options.stripTel, stripTel),
    ]
    return steps.reduce(text) { result, step in step.isOn ? step.apply(result) : result }
}

private let invisibleScalars: Set<Unicode.Scalar> = [
    "\u{00AD}", "\u{061C}", "\u{180E}", "\u{200B}", "\u{200E}", "\u{200F}",
    "\u{202A}", "\u{202B}", "\u{202C}", "\u{202D}", "\u{202E}",
    "\u{2060}", "\u{2061}", "\u{2062}", "\u{2063}", "\u{2064}",
    "\u{2066}", "\u{2067}", "\u{2068}", "\u{2069}", "\u{FEFF}",
]

private let spaceLikeScalars: Set<Unicode.Scalar> = ["\u{00A0}", "\u{2007}", "\u{202F}"]

func removeInvisibles(_ text: String) -> String {
    var scalars = String.UnicodeScalarView()
    for scalar in text.unicodeScalars where !invisibleScalars.contains(scalar) {
        scalars.append(spaceLikeScalars.contains(scalar) ? " " : scalar)
    }
    return String(scalars)
}

func trimWhitespace(_ text: String) -> String {
    text.trimmingCharacters(in: .whitespacesAndNewlines)
}

func straightenQuotes(_ text: String) -> String {
    String(text.map { character -> Character in
        if "\u{2018}\u{2019}\u{201A}\u{201B}".contains(character) { return "'" }
        if "\u{201C}\u{201D}\u{201E}\u{201F}".contains(character) { return "\"" }
        return character
    })
}

private let trackingParameters: Set<String> = [
    "fbclid", "gclid", "dclid", "gbraid", "wbraid", "msclkid", "mc_cid", "mc_eid",
    "igshid", "yclid", "_hsenc", "_hsmi", "mkt_tok", "ref_src",
]

private let siParameterHosts = ["youtube.com", "youtu.be", "spotify.com"]

func removeTrackingParameters(_ text: String) -> String {
    let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.contains(where: \.isWhitespace),
          var components = URLComponents(string: trimmed),
          let scheme = components.scheme?.lowercased(), scheme == "http" || scheme == "https",
          let host = components.host?.lowercased(), !host.isEmpty
    else { return text }

    let stripsSi = siParameterHosts.contains { host == $0 || host.hasSuffix("." + $0) }
    let items = components.percentEncodedQueryItems ?? []
    let keptItems = items.filter { item in
        let name = item.name.lowercased()
        return !(name.hasPrefix("utm_") || trackingParameters.contains(name) || (stripsSi && name == "si"))
    }
    let fragment = components.percentEncodedFragment
    let fragmentBeforeDirective = fragment.map { $0.components(separatedBy: ":~:")[0] }
    let keptFragment = fragmentBeforeDirective?.isEmpty == true ? nil : fragmentBeforeDirective
    guard keptItems.count != items.count || keptFragment != fragment else { return text }

    components.percentEncodedQueryItems = keptItems.isEmpty ? nil : keptItems
    components.percentEncodedFragment = keptFragment
    return components.string ?? text
}

func stripMailto(_ text: String) -> String {
    let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
    guard trimmed.lowercased().hasPrefix("mailto:") else { return text }
    let address = String(trimmed.dropFirst("mailto:".count).prefix { $0 != "?" })
    guard !address.isEmpty, !address.contains(where: \.isWhitespace) else { return text }
    return address.removingPercentEncoding ?? address
}

func stripTel(_ text: String) -> String {
    let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
    guard trimmed.lowercased().hasPrefix("tel:") else { return text }
    let number = String(trimmed.dropFirst("tel:".count))
    guard !number.isEmpty, !number.contains(where: \.isWhitespace) else { return text }
    return number.removingPercentEncoding ?? number
}
