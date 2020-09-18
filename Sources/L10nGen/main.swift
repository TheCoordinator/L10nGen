// swiftformat:disable:all

import Foundation
import Files
import SwiftyJSON
import Yams

enum L10nGenCLIError: Error {
    case configMissing
}

let args = CommandLine.arguments

guard let configIndex: Int = args.firstIndex(of: "--config") else {
    throw L10nGenCLIError.configMissing
}

let configPath: String = args[configIndex + 1]
let configFile = try File(path: configPath)
let configContent = try configFile.readAsString()

let config = try YAMLDecoder().decode(Config.self, from: configContent)
let folders = try Folders(config: config)

let templates = Templates()

try JsonImporter.import(using: folders)
try FileGenerator(folders: folders, templates: templates).generate()
