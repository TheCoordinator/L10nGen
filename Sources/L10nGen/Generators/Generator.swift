import Foundation
import SwiftyJSON

protocol Generator {
    var json: JSON { get }
    var templates: Templates { get }

    func generate() -> String
}
