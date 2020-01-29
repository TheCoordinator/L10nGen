import Files
import Foundation

enum FoldersError: Error {
    case pathInvalid
}

struct Folders {
    let localizationResources: Folder

    let sources: Folder
    let resources: Folder
    let infoPlistResources: Folder

    let generatedSources: Folder
    let resourcesBundle: Folder
    let infoPlistResourcesBundle: Folder

    static func from(
        localizationResourcesPath: String,
        sourcesPath: String,
        resourcesPath: String,
        infoPlistResourcesPath: String?
    ) throws -> Folders {
        let localizationResources = try self.folder(from: localizationResourcesPath)
        let sources = try self.folder(from: sourcesPath)
        let resources = try self.folder(from: resourcesPath)
        let infoPlistResources = try self.folder(from: infoPlistResourcesPath ?? resourcesPath)

        let generatedSources = try Helper.createAndDeleteSubfolderIfNeeded(in: sources, withName: "L10n")
        let resourcesBundle = try Helper.createAndDeleteSubfolderIfNeeded(in: resources, withName: "Strings")

        let infoPlistResourcesBundle: Folder = try {
            guard resources != infoPlistResources else {
                return resourcesBundle
            }

            return try Helper.createAndDeleteSubfolderIfNeeded(in: infoPlistResources, withName: "Strings")
        }()

        return Folders(
            localizationResources: localizationResources,
            sources: sources,
            resources: resources,
            infoPlistResources: infoPlistResources,
            generatedSources: generatedSources,
            resourcesBundle: resourcesBundle,
            infoPlistResourcesBundle: infoPlistResourcesBundle
        )
    }

    // MARK: Private Methods

    private static func folder(from path: String) throws -> Folder {
        let pathValue = path.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        guard !pathValue.isEmpty else {
            throw FoldersError.pathInvalid
        }

        return try Folder(path: pathValue)
    }
}
