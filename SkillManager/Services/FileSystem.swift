import Foundation

actor FileSystem {
    static let shared = FileSystem()

    private let fileManager = FileManager.default

    private init() {}

    func directoryExists(at url: URL) -> Bool {
        var isDirectory: ObjCBool = false
        let exists = fileManager.fileExists(atPath: url.path, isDirectory: &isDirectory)
        return exists && isDirectory.boolValue
    }

    func fileExists(at url: URL) -> Bool {
        return fileManager.fileExists(atPath: url.path)
    }

    func listDirectories(at url: URL) -> [URL] {
        guard directoryExists(at: url) else { return [] }

        do {
            let contents = try fileManager.contentsOfDirectory(
                at: url,
                includingPropertiesForKeys: [.isDirectoryKey, .fileSizeKey],
                options: [.skipsHiddenFiles, .skipsSubdirectoryDescendants]
            )
            return contents.filter { url in
                do {
                    let values = try url.resourceValues(forKeys: [.isDirectoryKey])
                    return values.isDirectory ?? false
                } catch {
                    return false
                }
            }
        } catch {
            return []
        }
    }

    func calculateDirectorySize(at url: URL) -> Int64 {
        guard directoryExists(at: url) else { return 0 }

        var totalSize: Int64 = 0

        if let enumerator = fileManager.enumerator(at: url, includingPropertiesForKeys: [.fileSizeKey], options: [.skipsHiddenFiles]) {
            for case let fileURL as URL in enumerator {
                do {
                    let size = try fileURL.resourceValues(forKeys: [.fileSizeKey]).fileSize ?? 0
                    totalSize += Int64(size)
                } catch {
                    continue
                }
            }
        }

        return totalSize
    }

    func moveItem(from sourceURL: URL, to destinationURL: URL) throws {
        if fileManager.fileExists(atPath: destinationURL.path) {
            try fileManager.removeItem(at: destinationURL)
        }
        try fileManager.moveItem(at: sourceURL, to: destinationURL)
    }

    func removeItem(at url: URL) throws {
        try fileManager.removeItem(at: url)
    }

    func readTextFile(at url: URL) -> String? {
        do {
            return try String(contentsOf: url, encoding: .utf8)
        } catch {
            return nil
        }
    }

    func createDirectoryIfNeeded(at url: URL) throws {
        if !directoryExists(at: url) {
            try fileManager.createDirectory(at: url, withIntermediateDirectories: true)
        }
    }
}