import Files
import Foundation

extension File: TextOutputStream {
    public mutating func write(_ string: String) {
        try? write(string, encoding: .utf8)
    }
}
