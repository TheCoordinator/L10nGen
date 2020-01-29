import Foundation
import SwiftyJSON

struct DefaultContentGenerator: Generator {
    let json: JSON
    let templates: Templates

    func generate() -> String {
        let values = self.basicValues() + self.pluralValues()

        return values
            .joined(separator: "\n\n")
    }

    // MARK: Private Methods

    private func basicValues() -> [String] {
        return self.json
            .compactMap { key, json in
                guard !key.contains("__"), json.string != nil else {
                    return nil
                }

                return self.templates.basic
                    .replacingOccurrences(of: "{Key}", with: key)
            }
            .sorted()
    }

    private func pluralValues() -> [String] {
        return self.json
            .compactMap { key, json in
                guard key.hasSuffix("__Plural"), json.dictionaryObject != nil else {
                    return nil
                }

                return self.templates.plural
                    .replacingOccurrences(of: "{Key}",
                                          with: key.replacingOccurrences(of: "__Plural", with: ""))
            }
            .sorted()
    }
}
