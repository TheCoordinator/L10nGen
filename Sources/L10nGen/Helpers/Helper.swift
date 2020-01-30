import Files
import Foundation

final class Helper {
    static func recreateFolder(in path: String) throws -> Folder {
        guard let folder = try? Folder(path: path) else {
            return try createFolder(in: path)
        }

        try folder.delete()
        return try createFolder(in: path)
    }

    static func createFolder(in path: String) throws -> Folder {
        try FileManager().createDirectory(atPath: path, withIntermediateDirectories: true, attributes: nil)
        return try Folder(path: path)
    }

    static func createFile(in folder: Folder, fileName: String, contents: String) throws {
        let data = contents.data(using: .utf8)!
        try folder.createFile(named: fileName, contents: data)
    }

    static func envVariable(_ key: String) -> String {
        ProcessInfo.processInfo.environment[key] ?? ""
    }

    static func log(_ msg: String) {
        print("L10nGen: \(msg)")
    }
}

extension String {
    func indented(with spaces: Int = 4) -> String {
        let indention = (0 ..< spaces).reduce("") { res, _ in "\(res) " }
        let newLinesIndented = replacingOccurrences(of: "\n",
                                                    with: "\(indention)\n")

        return "\(indention)\(newLinesIndented)"
    }

    var nilIfEmpty: String? {
        isEmpty ? nil : self
    }
}
