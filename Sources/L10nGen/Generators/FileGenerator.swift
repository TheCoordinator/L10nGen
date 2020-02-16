import Files
import Foundation
import SwiftFormat

final class FileGenerator {
    private let folders: Folders
    private let templates: Templates

    init(folders: Folders, templates: Templates) {
        self.folders = folders
        self.templates = templates
    }

    func generate() throws {
        Helper.log("Imported All JSON files")

        let baseFeatures = try JsonImporter.baseFeatures(from: folders.jsonResources)

        let generatedFiles = [
            try generateKeys(from: baseFeatures),
            try generateMainContent(from: baseFeatures),
        ]

        try formatFiles(generatedFiles)
    }

    // MARK: - Content

    private func generateKeys(from baseFeatures: AllFeatures) throws -> File {
        let keysContent = L10nKeysGenerator(
            allFeatures: baseFeatures,
            templates: templates
        ).generate()

        let keysFile = try Helper.createFile(in: folders.sources, fileName: "L10nKeys.swift", contents: keysContent)

        Helper.log("Generated All L10n Keys")

        return keysFile
    }

    private func generateMainContent(from baseFeatures: AllFeatures) throws -> File {
        let mainContents = L10nContentGenerator(
            allFeatures: baseFeatures,
            templates: templates
        ).generate()

        let mainContentsFile = try Helper.createFile(in: folders.sources, fileName: "L10n.swift", contents: mainContents)

        Helper.log("Generated All L10n contents")

        return mainContentsFile
    }

    // MARK: - Formatter

    private func formatFiles(_ files: [File]) throws {
        let paths = files.map { $0.path }
            .joined(separator: " ")

        SwiftFormat.CLI.print = { message, _ in
            Helper.log(message)
        }

        _ = SwiftFormat.CLI.run(in: ".", with: paths)
    }
}
