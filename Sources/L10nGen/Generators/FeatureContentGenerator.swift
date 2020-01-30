import Foundation
import SwiftyJSON

struct FeatureContentGenerator: FeatureContentGenerating {
    let feature: FeatureJson
    let templates: Templates

    func generate() -> String {
        let allGenerators: [FeatureContentGenerating] = [
            self.defaultContentGenerator(),
            self.paramContentGenerator(),
        ]

        let content = allGenerators
            .map { $0.generate() }
            .joined(separator: "\n\n")
            .trimmingCharacters(in: .newlines)

        return templates.feature
            .replacingOccurrences(of: "{Key}", with: feature.typeKey)
            .replacingOccurrences(of: "{Content}", with: content)
    }

    private func defaultContentGenerator() -> DefaultContentGenerator {
        DefaultContentGenerator(
            feature: feature,
            templates: templates
        )
    }

    private func paramContentGenerator() -> ParamContentGenerator {
        ParamContentGenerator(
            feature: feature,
            templates: templates
        )
    }
}
