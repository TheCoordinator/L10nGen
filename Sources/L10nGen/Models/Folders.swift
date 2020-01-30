import Files
import Foundation

enum FoldersError: Error {
    case pathInvalid
}

struct Config: Decodable {
    let inputs: Inputs
}

extension Config {
    struct Inputs: Decodable {
        let sources: String
        let jsonResources: String
        let stringResources: String
        let infoPlistResources: String
    }
}

struct Folders {
    let jsonResources: Folder
    let sources: Folder
    let stringResources: Folder
    let infoPlistResources: Folder
}

extension Folders {
    init(config: Config) throws {
        jsonResources = try Folder(path: config.inputs.jsonResources)
        sources = try Helper.recreateFolder(in: config.inputs.sources)
        stringResources = try Helper.recreateFolder(in: config.inputs.stringResources)
        infoPlistResources = try Helper.recreateFolder(in: config.inputs.infoPlistResources)
    }
}
