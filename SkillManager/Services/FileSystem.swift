import Foundation

struct TextFilePreview {
    let content: String
    let isTruncated: Bool
}

enum FastTextFileReader {
    final class CachedPreviewBox: NSObject {
        let value: CachedPreview

        init(_ value: CachedPreview) {
            self.value = value
        }
    }

    struct CachedPreview {
        let modificationDate: Date?
        let maxBytes: Int
        let preview: TextFilePreview
    }

    private static let cache = NSCache<NSString, CachedPreviewBox>()

    static func readPreview(at url: URL, maxBytes: Int) -> TextFilePreview? {
        guard maxBytes > 0 else { return nil }

        let cacheKey = url.path as NSString
        let currentModificationDate = try? url.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate

        if let cachedBox = cache.object(forKey: cacheKey) {
            let cached = cachedBox.value
            if cached.maxBytes == maxBytes, cached.modificationDate == currentModificationDate {
                return cached.preview
            }
        }

        do {
            let data = try Data(contentsOf: url, options: [.mappedIfSafe])
            let truncatedData = data.prefix(maxBytes)
            guard let content = String(data: truncatedData, encoding: .utf8) else {
                return nil
            }

            let preview = TextFilePreview(content: content, isTruncated: data.count > maxBytes)
            let cached = CachedPreview(modificationDate: currentModificationDate, maxBytes: maxBytes, preview: preview)
            cache.setObject(CachedPreviewBox(cached), forKey: cacheKey)
            return preview
        } catch {
            return nil
        }
    }
}

actor FileSystem {
    static let shared = FileSystem()

    private let fileManager = FileManager.default
    private let metadataCacheTTL: TimeInterval = 3
    private var metadataCache: [String: (timestamp: Date, values: URLResourceValues)] = [:]
    private var directorySizeCache: [String: (modificationDate: Date?, size: Int64)] = [:]

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
                    print("FileSystem.listDirectories error: \(error.localizedDescription)")
                    return false
                }
            }
        } catch {
            print("FileSystem.listDirectories error: \(error.localizedDescription)")
            return []
        }
    }

    func calculateDirectorySize(at url: URL) -> Int64 {
        guard directoryExists(at: url) else { return 0 }

        let cacheKey = url.path
        let dirModificationDate = modificationDate(at: url)
        if let cached = directorySizeCache[cacheKey],
           cached.modificationDate == dirModificationDate {
            return cached.size
        }

        var totalSize: Int64 = 0

        if let enumerator = fileManager.enumerator(at: url, includingPropertiesForKeys: [.fileSizeKey], options: [.skipsHiddenFiles]) {
            for case let fileURL as URL in enumerator {
                do {
                    let size = try fileURL.resourceValues(forKeys: [.fileSizeKey]).fileSize ?? 0
                    totalSize += Int64(size)
                } catch {
                    print("FileSystem.calculateDirectorySize error: \(error.localizedDescription)")
                    continue
                }
            }
        }

        directorySizeCache[cacheKey] = (modificationDate: dirModificationDate, size: totalSize)
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
            print("FileSystem.readTextFile error: \(error.localizedDescription)")
            return nil
        }
    }

    func readTextFilePreview(at url: URL, maxBytes: Int) -> TextFilePreview? {
        guard maxBytes > 0 else { return nil }

        do {
            let data = try Data(contentsOf: url, options: [.mappedIfSafe])
            let truncatedData = data.prefix(maxBytes)
            guard let content = String(data: truncatedData, encoding: .utf8) else {
                return nil
            }
            return TextFilePreview(content: content, isTruncated: data.count > maxBytes)
        } catch {
            print("FileSystem.readTextFilePreview error: \(error.localizedDescription)")
            return nil
        }
    }

    func modificationDate(at url: URL) -> Date? {
        let key = url.path
        let now = Date()

        if let cached = metadataCache[key], now.timeIntervalSince(cached.timestamp) <= metadataCacheTTL {
            return cached.values.contentModificationDate
        }

        do {
            let values = try url.resourceValues(forKeys: [.contentModificationDateKey])
            metadataCache[key] = (timestamp: now, values: values)
            return values.contentModificationDate
        } catch {
            print("FileSystem.modificationDate error: \(error.localizedDescription)")
            return nil
        }
    }

    func createDirectoryIfNeeded(at url: URL) throws {
        if !directoryExists(at: url) {
            try fileManager.createDirectory(at: url, withIntermediateDirectories: true)
        }
    }
}