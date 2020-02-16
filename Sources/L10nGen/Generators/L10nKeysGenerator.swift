import Files
import Foundation
import SwiftyJSON

struct L10nKeysGenerator: L10nContentGenerating {
    let allFeatures: AllFeatures
    let templates: Templates

    func generate() -> String {
        let generators = allFeatures
            .features
            .filter { $0.isInfoPlist == false }
            .map { FeatureKeysGenerator(feature: $0, templates: templates) }

        let content = generators
            .sorted { $0.feature.key < $1.feature.key }
            .map { $0.generate() }
            .sorted()
            .joined(separator: "\n\n")

        return templates.l10nKeys
            .replacingOccurrences(of: "{Content}", with: content)
    }
}
