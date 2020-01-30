// swiftformat:disable:all

import Foundation
import Files
import SwiftyJSON
import Yams

enum L10nGenCLIError: Error {
    case configMissing
}

let args = CommandLine.arguments

guard let configIndex = args.firstIndex(of: "--config") else {
    throw L10nGenCLIError.configMissing
}

let configPath = args[configIndex + 1]
let configFile = try File(path: configPath)
let configContent = try configFile.readAsString()

let config = try YAMLDecoder().decode(Config.self, from: configContent)
let folders = try Folders(config: config)

let templates = Templates()

try JsonImporter.import(using: folders)

Helper.log("Imported All JSON files")

let baseFeatures = try JsonImporter.baseFeatures(from: folders.jsonResources)

let keysContent = L10nKeysGenerator(
    allFeatures: baseFeatures,
    templates: templates
).generate()

try Helper.createFile(in: folders.sources, fileName: "L10nKeys.swift", contents: keysContent)

Helper.log("Generated All L10n Keys")

let mainContents = L10nContentGenerator(
    allFeatures: baseFeatures,
    templates: templates
).generate()

try Helper.createFile(in: folders.sources, fileName: "L10n.swift", contents: mainContents)

Helper.log("Generated All L10n contents")
