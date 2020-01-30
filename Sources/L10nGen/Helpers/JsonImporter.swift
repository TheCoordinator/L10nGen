import Files
import Foundation
import SwiftyJSON

private struct LocalizableContent {
    typealias StringValue = (key: String, value: String)
    typealias PluralStringValue = (key: String, pluralFormat: String, value: String)
    typealias PluralValue = (parentKey: String, values: [PluralStringValue])

    let identifier: String
    let strings: [StringValue]
    let infoPlistStrings: [StringValue]
    let plurals: [PluralValue]
}

final class JsonImporter {
    static func `import`(using folders: Folders) throws {
        try allJsonFiles(in: folders.jsonResources)
            .forEach { file in
                let identifier = file.nameExcludingExtension == "base" ? "Base" : file.nameExcludingExtension

                let features = try self.json(from: file)
                    .map(FeatureJson.init)
                    .map(cleanUp)

                let allFeatures = AllFeatures(features: features)

                let localizableContent = self.localizableContent(from: identifier, with: allFeatures)

                try self.createLocalizableFiles(
                    from: localizableContent,
                    in: folders.stringResources,
                    infoPlistDest: folders.infoPlistResources
                )
            }
    }

    static func baseFeatures(from jsonResources: Folder) throws -> AllFeatures {
        let file = try jsonResources.file(named: "base.json")
        let json = try self.json(from: file)

        let features = json.map(FeatureJson.init)
        return AllFeatures(features: features)
    }

    // MARK: Private Methods

    private static func allJsonFiles(in folder: Folder) -> [File] {
        folder.files.filter { $0.extension == "json" }
    }

    private static func json(from file: File) throws -> JSON {
        let data = try file.read()
        return try JSON(data: data)
    }

    private static func cleanUp(feature: FeatureJson) -> FeatureJson {
        var dict = feature.json.dictionaryObject ?? [:]

        dict = cleanUpPlurals(from: dict)
        dict = cleanUpParams(from: dict)

        return FeatureJson(key: feature.key, json: JSON(dict))
    }

    private static func cleanUpPlurals(from dict: [String: Any]) -> [String: Any] {
        remove(suffixes: ["__Plural"], from: dict)
    }

    private static func cleanUpParams(from dict: [String: Any]) -> [String: Any] {
        var retVal = dict

        let paramValuePattern = "(\\{\\w+\\})%\\d+\\$[@df]"
        let paramValueRegex = try! NSRegularExpression(pattern: paramValuePattern, options: [])

        for each in dict {
            if let value = each.value as? [String: Any] {
                retVal[each.key] = cleanUpParams(from: value)
            } else if let value = each.value as? String {
                let nsValue = NSString(string: value)

                retVal[each.key] = paramValueRegex.matches(
                    in: value,
                    options: [],
                    range: NSRange(location: 0, length: value.count)
                )
                .map { nsValue.substring(with: $0.range(at: $0.numberOfRanges - 1)) }
                .reduce(value) { res, param in
                    res.replacingOccurrences(of: param, with: "")
                }
            }
        }

        return remove(suffixes: ["__Param", "__PluralParam"], from: retVal)
    }

    private static func remove(suffixes: [String], from dict: [String: Any]) -> [String: Any] {
        var retVal = dict
        let filteredKeys = dict.filter {
            for each in suffixes where $0.key.hasSuffix(each) {
                return true
            }

            return false
        }

        for each in filteredKeys {
            retVal.removeValue(forKey: each.key)

            let newKey: String = {
                var retVal = each.key
                for suffix in suffixes {
                    retVal = retVal.replacingOccurrences(of: suffix, with: "")
                }

                return retVal
            }()

            retVal[newKey] = each.value
        }

        return retVal
    }

    private static func localizableContent(from identifier: String, with allFeatures: AllFeatures) -> LocalizableContent {
        var strings: [LocalizableContent.StringValue] = allFeatures.features
            .filter { $0.isInfoPlist == false }
            .compactMap { feature -> [LocalizableContent.StringValue] in
                feature.json.compactMap { key, json in
                    guard let string = json.string else { return nil }

                    return (feature.basicKey(for: key), string)
                }
            }
            .flatMap { $0 }

        let plurals: [LocalizableContent.PluralValue] = allFeatures.features
            .filter { $0.isInfoPlist == false }
            .compactMap { feature -> [LocalizableContent.PluralValue] in
                feature.json.compactMap { jsonKey, json in
                    guard let dict = json.dictionary else {
                        return nil
                    }

                    let parentKey = feature.basicKey(for: jsonKey)

                    let values: [LocalizableContent.PluralStringValue] = dict.compactMap { key, json in
                        guard let string = json.string else { return nil }

                        let pluralKey = feature.pluralKey(with: jsonKey, for: key)
                        return (pluralKey, key, string)
                    }

                    return (parentKey, values)
                }
            }
            .flatMap { $0 }

        strings += plurals.flatMap {
            $0.values.map { (key: $0.key, value: $0.value) }
        }

        let infoPlistFeature = allFeatures.features.first(where: { $0.isInfoPlist == true })
        let infoPlistStrings: [LocalizableContent.StringValue]? = infoPlistFeature?.json
            .compactMap { key, json in
                guard let string = json.string else { return nil }
                return (key, string)
            }

        return LocalizableContent(
            identifier: identifier,
            strings: strings,
            infoPlistStrings: infoPlistStrings ?? [],
            plurals: plurals
        )
    }

    private static func createLocalizableFiles(
        from content: LocalizableContent,
        in dest: Folder,
        infoPlistDest: Folder
    ) throws {
        let lProjFolder = try createLProjFolder(from: dest, with: content.identifier)

        if let data = self.stringsLocalizableContentData(from: content.strings) {
            try lProjFolder.createFile(named: "Localizable.strings", contents: data)
        }

        if let data = self.stringsLocalizableContentData(from: content.infoPlistStrings) {
            let infoPlistLProjFolder: Folder = try {
                guard dest != infoPlistDest else {
                    return lProjFolder
                }

                return try self.createLProjFolder(from: infoPlistDest, with: content.identifier)
            }()

            try infoPlistLProjFolder.createFile(named: "InfoPlist.strings", contents: data)
        }

        if let data = self.pluralsLocalizableContentData(from: content) {
            try lProjFolder.createFile(named: "Localizable.stringsdict", contents: data)
        }
    }

    private static func createLProjFolder(from folder: Folder, with identifier: String) throws -> Folder {
        try folder.createSubfolder(named: "\(identifier).lproj")
    }

    private static func stringsLocalizableContentData(
        from strings: [LocalizableContent.StringValue]
    ) -> Data? {
        guard !strings.isEmpty else {
            return nil
        }

        let stringValue: String = strings
            .map(stringLocalizableContentValue)
            .sorted()
            .joined(separator: "\n")

        return stringValue.data(using: .utf8)
    }

    private static func stringLocalizableContentValue(
        from stringValue: LocalizableContent.StringValue
    ) -> String {
        let value = stringValue.value.replacingOccurrences(of: "\"", with: "\\\"")
        return """
        "\(stringValue.key)" = "\(value)";
        """
    }

    private static func pluralsLocalizableContentData(
        from content: LocalizableContent
    ) -> Data? {
        guard !content.plurals.isEmpty else {
            return nil
        }

        let xmlDicts = content.plurals
            .map(pluralXMLDict)
            .sorted()
            .joined(separator: "\n")

        let retVal = """
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
        <plist version="1.0">
        <dict>
        \(xmlDicts)
        </dict>
        </plist>
        """

        return retVal.data(using: .utf8)
    }

    private static func pluralXMLDict(
        from plural: LocalizableContent.PluralValue
    ) -> String {
        let keys: String = plural.values
            .map(pluralXMLKeys)
            .joined(separator: "\n")

        return """
        <key>\(plural.parentKey)</key>
        <dict>
            <key>NSStringLocalizedFormatKey</key>
            <string>%#@plural@</string>
            <key>plural</key>
            <dict>
                <key>NSStringFormatSpecTypeKey</key>
                <string>NSStringPluralRuleType</string>
                <key>NSStringFormatValueTypeKey</key>
                <string>d</string>
            \(keys)
            </dict>
        </dict>
        """
    }

    private static func pluralXMLKeys(
        from value: LocalizableContent.PluralStringValue
    ) -> String {
        """
                    <key>\(value.pluralFormat)</key>
                    <string>\(value.key)</string>
        """
    }
}
