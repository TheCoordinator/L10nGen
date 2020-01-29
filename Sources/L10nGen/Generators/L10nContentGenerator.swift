import Foundation
import SwiftyJSON

struct L10nContentGenerator: Generator {
    let json: JSON
    let templates: Templates

    func generate() -> String {
        let allGenerators: [Generator] = [
            self.defaultContentGenerator(),
            self.paramContentGenerator()
        ]

        let content = allGenerators
            .map { $0.generate() }
            .joined(separator: "\n")

        return self.templates.l10n
            .replacingOccurrences(of: "{Content}", with: content)
    }

    private func defaultContentGenerator() -> DefaultContentGenerator {
        return DefaultContentGenerator(
            json: self.json,
            templates: self.templates
        )
    }

    private func paramContentGenerator() -> ParamContentGenerator {
        return ParamContentGenerator(
            json: self.json,
            templates: self.templates
        )
    }
}
