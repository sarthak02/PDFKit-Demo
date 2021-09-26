import Foundation
extension FileManager {
    func copyfileToUserDocumentDirectory(forResource name: String,
                                         ofType ext: String) throws {
        if let bundlePath = Bundle.main.path(forResource: name, ofType: ext) {
            let fileName = "\(name).\(ext)"
            let path = Contants.documentsDirectory
            if self.fileExists(atPath: path.path) == false {
                try self.createDirectory(at: path,
                                         withIntermediateDirectories: true,
                                         attributes: nil)
            }
            let destinationPath: URL = path.appendingPathComponent(fileName)
            let fullDestPathString = destinationPath.path
            do {
                if self.fileExists(atPath: fullDestPathString) {
                    try self.removeItem(atPath: fullDestPathString)
                }
                try self.copyItem(atPath: bundlePath, toPath: fullDestPathString)
            } catch {}
        }
    }
}
