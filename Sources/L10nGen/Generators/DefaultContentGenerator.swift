import Foundation
import SwiftyJSON

struct DefaultContentGenerator: FeatureContentGenerating {
    let feature: FeatureJson
    let templates: Templates

    func generate() -> String {
        let values = basicValues() + pluralValues()

        return values
            .joined(separator: "\n\n")
    }

    // MARK: Private Methods

    private func basicValues() -> [String] {
        feature.json
            .compactMap { key, json in
                guard !key.contains("__"), let string = json.string else {
                    return nil
                }

                let enumKey = feature.enumKey(for: key)

                return self.templates.basic
                    .replacingOccurrences(of: "{Key}", with: key)
                    .replacingOccurrences(of: "{EnumKey}", with: enumKey)
                    .replacingOccurrences(of: "{Value}", with: "\(string)")
            }
            .sorted()
    }

    private func pluralValues() -> [String] {
        feature.json
            .compactMap { key, json in
                guard key.hasSuffix("__Plural"), let dictValue = json.dictionary else {
                    return nil
                }

                let key = key.replacingOccurrences(of: "__Plural", with: "")
                let enumKey = feature.enumKey(for: key)

                let stringValues = dictValue
                    .compactMap { "\($0.key): \($0.value.stringValue)" }
                    .sorted()
                    .joined(separator: "\n\t\t ")

                return self.templates.plural
                    .replacingOccurrences(of: "{Key}", with: key)
                    .replacingOccurrences(of: "{EnumKey}", with: enumKey)
                    .replacingOccurrences(of: "{Value}", with: stringValues)
            }
            .sorted()
    }
}
