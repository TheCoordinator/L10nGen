import Foundation
import SwiftyJSON

struct FeatureKeysGenerator: FeatureContentGenerating {
    private struct KeyValue {
        let key: String
        let value: String
    }

    let feature: FeatureJson
    let templates: Templates

    func generate() -> String {
        let keyValues = self.keyValues()

        return replacedTemplateData(keyValues: keyValues)
    }

    private func keyValues() -> [KeyValue] {
        feature.json
            .map { key, _ in
                let key = key
                    .replacingOccurrences(of: "__Param", with: "")
                    .replacingOccurrences(of: "__PluralParam", with: "")
                    .replacingOccurrences(of: "__Plural", with: "")

                let value = feature.basicKey(for: key)
                return KeyValue(key: key, value: value)
            }
            .sorted { $0.key > $1.key }
    }

    private func replacedTemplateData(keyValues: [KeyValue]) -> String {
        let cases = keyValues
            .sorted { $0.key < $1.key }
            .compactMap {
                "case \($0.key) = \"\($0.value)\""
            }
            .joined(separator: "\n")

        return templates.featureKeys
            .replacingOccurrences(of: "{Name}", with: feature.typeKey)
            .replacingOccurrences(of: "{Cases}", with: cases)
    }
}
