//
//  FeatureJson.swift
//  CYaml
//
//  Created by Peyman Khanjan on 29/01/2020.
//

import Foundation
import SwiftyJSON

struct AllFeatures {
    let features: [FeatureJson]
}

struct FeatureJson {
    let key: String
    let json: JSON

    var isInfoPlist: Bool {
        key == "infoPlist"
    }

    var typeKey: String {
        key.prefix(1).capitalized + key.dropFirst()
    }

    func basicKey(for contentKey: String) -> String {
        [key, contentKey]
            .joined(separator: "__")
    }

    func pluralKey(with parentKey: String, for contentKey: String) -> String {
        [key, parentKey, contentKey]
            .joined(separator: "__")
    }

    func enumKey(for contentKey: String) -> String {
        "\(typeKey).\(contentKey)"
    }
}
