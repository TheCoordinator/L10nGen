import Foundation
import SwiftyJSON

protocol Generating {
    var templates: Templates { get }

    func generate() -> String
}

protocol FeatureContentGenerating: Generating {
    var feature: FeatureJson { get }
}

protocol L10nContentGenerating: Generating {
    var allFeatures: AllFeatures { get }
}
