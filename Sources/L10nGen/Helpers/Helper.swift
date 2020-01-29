import Files
import Foundation

final class Helper {
    static func createAndDeleteSubfolderIfNeeded(in folderPath: String, withName name: String) throws -> Folder {
        let folder = try Folder(path: folderPath)
        return try self.createAndDeleteSubfolderIfNeeded(in: folder, withName: name)
    }

    static func createAndDeleteSubfolderIfNeeded(in folder: Folder, withName name: String) throws -> Folder {
        if folder.containsSubfolder(named: name) {
            let subfolder = try folder.subfolder(named: name)
            try subfolder.delete()
        }

        return try folder.createSubfolderIfNeeded(withName: name)
    }

    static func createFile(in folder: Folder, fileName: String, contents: String) throws {
        let data = contents.data(using: .utf8)!
        try folder.createFile(named: fileName, contents: data)
    }

    static func envVariable(_ key: String) -> String {
        return ProcessInfo.processInfo.environment[key] ?? ""
    }

    static func log(_ msg: String) {
        print("L10nGenerator: \(msg)")
    }
}

extension String {
    func indented(with spaces: Int = 4) -> String {
        let indention = (0 ..< spaces).reduce("") { res, _ in "\(res) " }
        let newLinesIndented = self.replacingOccurrences(of: "\n",
                                                         with: "\(indention)\n")

        return "\(indention)\(newLinesIndented)"
    }

    var nilIfEmpty: String? {
        return self.isEmpty ? nil : self
    }
}
