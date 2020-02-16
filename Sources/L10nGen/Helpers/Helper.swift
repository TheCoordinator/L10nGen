import Files
import Foundation

final class Helper {
    @discardableResult
    static func recreateFolder(in path: String) throws -> Folder {
        guard let folder = try? Folder(path: path) else {
            return try createFolder(in: path)
        }

        try folder.delete()
        return try createFolder(in: path)
    }

    @discardableResult
    static func createFolder(in path: String) throws -> Folder {
        try FileManager().createDirectory(atPath: path, withIntermediateDirectories: true, attributes: nil)
        return try Folder(path: path)
    }

    @discardableResult
    static func createFile(in folder: Folder, fileName: String, contents: String) throws -> File {
        let data = contents.data(using: .utf8)!
        return try folder.createFile(named: fileName, contents: data)
    }

    static func envVariable(_ key: String) -> String {
        ProcessInfo.processInfo.environment[key] ?? ""
    }

    static func log(_ msg: String) {
        print("L10nGen: \(msg)")
    }
}

extension String {
    var nilIfEmpty: String? {
        isEmpty ? nil : self
    }
}
