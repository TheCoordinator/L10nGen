import Files
import Foundation
import SwiftyJSON

struct KeysGenerator: Generator {
    let json: JSON
    let templates: Templates

    func generate() -> String {
        let keys = self.keys()

        let name = "L10nKeys"

        return self.replacedTemplateData(
            name: name,
            keys: keys,
            template: templates.keys
        )
    }

    // MARK: Private Methods

    private func keys() -> [String] {
        return self.json
            .filter { key, _ in !key.hasSuffix("__InfoPlist") }
            .map { key, _ in
                key
                    .replacingOccurrences(of: "__Param", with: "")
                    .replacingOccurrences(of: "__PluralParam", with: "")
                    .replacingOccurrences(of: "__Plural", with: "")
            }
            .sorted()
    }

    private func replacedTemplateData(name: String, keys: [String], template: String) -> String {
        let cases = keys
            .compactMap { "case \($0)".indented() }
            .joined(separator: "\n")

        return template
            .replacingOccurrences(of: "{Name:Type}", with: "\(name): String")
            .replacingOccurrences(of: "{Cases}", with: cases)
    }
}
