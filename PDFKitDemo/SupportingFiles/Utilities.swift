import Foundation
import UIKit
struct AppUtility {
    static func checkFileExists(at filePath: String) -> Bool {
        let fileManager = FileManager.default
        return fileManager.fileExists(atPath: filePath)
    }
}
