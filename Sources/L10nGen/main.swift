// swiftformat:disable:all

import Foundation
import Files
import SwiftyJSON

do {
    let folders = try Folders.from(
        localizationResourcesPath: Helper.envVariable("L10N_LOCALIZATION_RESOURCES_DIR"),
        sourcesPath: Helper.envVariable("L10N_SOURCES_DIR"),
        resourcesPath: Helper.envVariable("L10N_RESOURCES_DIR"),
        infoPlistResourcesPath: Helper.envVariable("L10N_INFOPLIST_RESOURCES_DIR").nilIfEmpty
    )

    let templates = Templates()

    try JsonImporter.import(
        source: folders.localizationResources,
        dest: folders.resourcesBundle,
        infoPlistDest: folders.infoPlistResourcesBundle
    )

    Helper.log("Imported All JSON files")

    let baseJson = try JsonImporter.baseJson(from: folders.localizationResources)

    let keysContent = KeysGenerator(
        json: baseJson,
        templates: templates
    ).generate()

    try Helper.createFile(in: folders.generatedSources, fileName: "L10nKeys.swift", contents: keysContent)

    Helper.log("Generated All L10n Keys")

    let mainContents = L10nContentGenerator(
        json: baseJson,
        templates: templates
    ).generate()

    try Helper.createFile(in: folders.generatedSources, fileName: "L10n.swift", contents: mainContents)

    Helper.log("Generated All L10n contents")

} catch {
    Helper.log("Error running L10nGenerator \(error)")
}
