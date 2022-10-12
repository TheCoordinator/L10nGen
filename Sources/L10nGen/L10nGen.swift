// swiftformat:disable:all

import Foundation
import Files
import SwiftyJSON
import Yams
import ArgumentParser

@main
struct L10nGenCommand: ParsableCommand {
    static var _commandName: String { "L10nGen" }

    @Option(name: .shortAndLong, help: "Path to the yaml config file")
    var config: String

    mutating func run() throws {
        let configFile = try File(path: config)
        let configContent = try configFile.readAsString()

        let config = try YAMLDecoder().decode(Config.self, from: configContent)
        let folders = try Folders(config: config)

        let templates = Templates()

        try JsonImporter.import(using: folders)
        try FileGenerator(folders: folders, templates: templates).generate()
    }
}
