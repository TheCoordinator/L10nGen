import Foundation
import SwiftyJSON

enum ParamsGeneratorError: Error {
    case paramNotFound
}

enum ParamType: String {
    case string = "@"
    case integer = "d"
    case float = "f"

    var stringValue: String {
        switch self {
        case .string:
            return "String"
        case .integer:
            return "Int"
        case .float:
            return "Float"
        }
    }

    static let allValues: [ParamType] = [.string, .integer, .float]
}

struct ParamContentGenerator: FeatureContentGenerating {
    private typealias ParamValue = (rawParam: String, name: String, index: Int, type: ParamType)

    let feature: FeatureJson
    let templates: Templates

    private let paramRegex: NSRegularExpression = {
        let pattern = "(?:\\{([A-Za-z0-9]+)\\})?%([0-9]*)\\$?([@df])"

        return try! NSRegularExpression(pattern: pattern, options: [])
    }()

    func generate() -> String {
        let values = self.values(isAttributed: false) + self.values(isAttributed: true)

        return values
            .sorted()
            .joined(separator: "\n\n")
    }

    // MARK: Private Methods

    private func values(isAttributed: Bool) -> [String] {
        feature.json
            .filter { $0.0.hasSuffix("__Param") || $0.0.hasSuffix("__PluralParam") }
            .compactMap { key, json in
                let isPlural = key.hasSuffix("__PluralParam")

                let key = key.replacingOccurrences(of: "__Param", with: "")
                    .replacingOccurrences(of: "__PluralParam", with: "")

                return self.value(from: key,
                                  json: json,
                                  isPlural: isPlural,
                                  isAttributed: isAttributed)
            }
    }

    private func value(from key: String, json: JSON, isPlural: Bool, isAttributed: Bool) -> String? {
        let template = self.template(isPlural: isPlural, isAttributed: isAttributed)

        guard let stringValue = self.stringValue(from: json) else {
            return nil
        }

        let allParamValues = self.allParamValues(from: stringValue)

        guard !allParamValues.isEmpty else {
            return nil
        }

        let argsInputs = argInputs(from: allParamValues, isAttributed: isAttributed)
        let args = self.args(from: allParamValues, isAttributed: isAttributed)

        let enumKey = feature.enumKey(for: key)

        let values: String = {
            if let stringValue = json.string {
                return stringValue
            }

            return json.dictionaryValue
                .compactMap { "\($0.key): \($0.value.stringValue)" }
                .sorted()
                .joined(separator: "\n\t\t ")
        }()

        return template
            .replacingOccurrences(of: "{Key}", with: key)
            .replacingOccurrences(of: "{EnumKey}", with: enumKey)
            .replacingOccurrences(of: "{ArgInputs}", with: argsInputs)
            .replacingOccurrences(of: "{Args}", with: args)
            .replacingOccurrences(of: "{Value}", with: values)
    }

    private func stringValue(from json: JSON) -> String? {
        if let stringValue = json.string {
            return stringValue
        }

        return json.dictionaryValue
            .compactMap { $0.value.string }
            .joined(separator: "")
    }

    private func allParamValues(from value: String) -> [ParamValue] {
        let regex = paramRegex

        let matches = regex.matches(
            in: value,
            options: [],
            range: NSRange(location: 0, length: value.count)
        )

        guard matches.count > 0 else {
            return []
        }

        let nsValue = NSString(string: value)

        let allMatches: [ParamValue] = matches.enumerated().compactMap {
            self.paramValue(from: $0.element, matchIndex: $0.offset, value: nsValue)
        }

        var retVal = [ParamValue]()

        for each in allMatches {
            if retVal.contains(where: { $0.rawParam == each.rawParam }) {
                continue
            }

            retVal.append(each)
        }

        return retVal
            .sorted { $0.index < $1.index }
    }

    private func paramValue(from match: NSTextCheckingResult, matchIndex: Int, value: NSString) -> ParamValue? {
        guard let rawParam = self.string(from: value, at: match.range(at: 0)) else {
            return nil
        }

        guard let indexString = self.string(from: value, at: match.range(at: 2)),
            let index = Int(indexString) else {
            return nil
        }

        guard let rawTypeString = self.string(from: value, at: match.range(at: 3)),
            let rawType: ParamType = ParamType(rawValue: rawTypeString) else {
            return nil
        }

        let name: String = {
            if let retVal = self.string(from: value, at: match.range(at: 1)) {
                return retVal
            }

            return "arg\(matchIndex + 1)"
        }()

        return (rawParam, name, index, rawType)
    }

    private func string(from nsString: NSString, at range: NSRange) -> String? {
        guard range.location != NSNotFound, range.length > 0 else {
            return nil
        }

        return nsString.substring(with: range)
    }

    private func argInputs(from values: [ParamValue], isAttributed: Bool) -> String {
        let retVal: [String] = {
            if isAttributed {
                return values
                    .map { "\($0.name)Attributed: AttributedStringParam<\($0.type.stringValue)>" }
            } else {
                return values
                    .map { "\($0.name): \($0.type.stringValue)" }
            }
        }()

        return retVal
            .joined(separator: ", ")
    }

    private func args(from values: [ParamValue], isAttributed: Bool) -> String {
        let retVal = values.map {
                isAttributed ? "\($0.name)Attributed" : $0.name
            }
            .joined(separator: ", ")

        return "[\(retVal)]"
    }

    private func template(isPlural: Bool, isAttributed: Bool) -> String {
        switch (isPlural, isAttributed) {
        case (true, true):
            return templates.pluralParamAttr
        case (false, false):
            return templates.param
        case (true, false):
            return templates.pluralParam
        case (false, true):
            return templates.paramAttr
        }
    }
}
