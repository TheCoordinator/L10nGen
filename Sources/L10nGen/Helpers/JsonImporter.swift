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
    static func `import`(source: Folder, dest: Folder, infoPlistDest: Folder) throws {
        try self.allJsonFiles(in: source)
            .forEach { file in
                let identifier = file.nameExcludingExtension == "base" ? "Base" : file.nameExcludingExtension

                let rawJson = try self.json(from: file)
                let filteredJson = self.filter(json: rawJson)
                let json = self.cleanUp(json: filteredJson)
                let localizableContent = self.localizableContent(from: identifier, with: json)

                try self.createLocalizableFiles(
                    from: localizableContent,
                    in: dest,
                    infoPlistDest: infoPlistDest
                )
            }
    }

    static func baseJson(from source: Folder) throws -> JSON {
        let file = try source.file(named: "base.json")
        let json = try self.json(from: file)

        return self.filter(json: json)
    }

    // MARK: Private Methods

    private static func allJsonFiles(in folder: Folder) -> [File] {
        return folder.files.filter { $0.extension == "json" }
    }

    private static func json(from file: File) throws -> JSON {
        let data = try file.read()
        return try JSON(data: data)
    }

    private static func filter(json: JSON) -> JSON {
        var dict = (json.dictionaryObject ?? [:])
            .filter {
            let unsupportedPlatforms = L10nPlatforms.unsupported.map { $0.rawValue }
            for each in unsupportedPlatforms where $0.key.hasSuffix(each) {
                return false
            }

            return true
        }

        dict = self.remove(suffixes: [L10nPlatforms.iOS.rawValue], from: dict)
        return JSON(dict)
    }

    private static func cleanUp(json: JSON) -> JSON {
        var dict = json.dictionaryObject ?? [:]

        dict = self.cleanUpPlurals(from: dict)
        dict = self.cleanUpParams(from: dict)

        return JSON(dict)
    }

    private static func cleanUpPlurals(from dict: [String: Any]) -> [String: Any] {
        return self.remove(suffixes: ["__Plural"], from: dict)
    }

    private static func cleanUpParams(from dict: [String: Any]) -> [String: Any] {
        var retVal = dict

        let paramValuePattern = "(\\{\\w+\\})%\\d+\\$[@df]"
        let paramValueRegex = try! NSRegularExpression(pattern: paramValuePattern, options: [])

        for each in dict {
            if let value = each.value as? [String: Any] {
                retVal[each.key] = self.cleanUpParams(from: value)
            } else if let value = each.value as? String {
                let nsValue = NSString(string: value)

                retVal[each.key] = paramValueRegex.matches(
                    in: value,
                    options: [],
                    range: NSRange(location: 0, length: value.count)
                )
                .map { nsValue.substring(with: $0.range(at: $0.numberOfRanges - 1)) }
                .reduce(value) { res, param in
                    return res.replacingOccurrences(of: param, with: "")
                }
            }
        }

        return self.remove(suffixes: ["__Param", "__PluralParam"], from: retVal)
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

    private static func localizableContent(from identifier: String, with json: JSON) -> LocalizableContent {
        let infoPlist = "__InfoPlist"

        var strings: [LocalizableContent.StringValue] = json.compactMap { key, json in
            guard !key.hasSuffix(infoPlist), let stringValue = json.string else {
                return nil
            }

            return (key, stringValue)
        }

        let plurals: [LocalizableContent.PluralValue] = json.compactMap { parentKey, json in
            guard let dict = json.dictionary else {
                return nil
            }

            let values: [LocalizableContent.PluralStringValue] = dict.compactMap { key, json in
                guard let stringValue = json.string else {
                    return nil
                }

                return (key: "\(parentKey)_\(key)", pluralFormat: key, value: stringValue)
            }

            return (parentKey, values)
        }

        strings += plurals.flatMap {
            $0.values.map { (key: $0.key, value: $0.value) }
        }

        let infoPlistStrings: [LocalizableContent.StringValue] = json.compactMap { key, json in
            guard key.hasSuffix(infoPlist), let stringValue = json.string else {
                return nil
            }

            return (key.replacingOccurrences(of: infoPlist, with: ""), stringValue)
        }

        return LocalizableContent(
            identifier: identifier,
            strings: strings,
            infoPlistStrings: infoPlistStrings,
            plurals: plurals
        )
    }

    private static func createLocalizableFiles(
        from content: LocalizableContent,
        in dest: Folder,
        infoPlistDest: Folder
    ) throws {
        let lProjFolder = try self.createLProjFolder(from: dest, with: content.identifier)

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
        return try folder.createSubfolder(named: "\(identifier).lproj")
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
        return """
                    <key>\(value.pluralFormat)</key>
                    <string>\(value.key)</string>
        """
    }
}
