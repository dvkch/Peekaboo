//
//  FileURL.swift
//  peekaboo
//
//  Created by syan on 03/09/2026.
//

import Foundation

struct FileURL {
    private let url: URL
    
    init(url: URL) {
        // does `standardizedFileURL` resets the `resourceValues` cache obtained via `contentsOfDirectory`?
        self.url = url.standardizedFileURL
    }
    
    init(path: String) {
        self.url = URL(filePath: (path as NSString).expandingTildeInPath).standardizedFileURL
    }
    
    var asURL: URL { url }
    var asPath: String { url.path(percentEncoded: false) }
    var asNSURL: NSURL { url as NSURL }
}

extension FileURL: Hashable, Equatable, Comparable {
    static func < (lhs: FileURL, rhs: FileURL) -> Bool {
        return lhs.asPath < rhs.asPath
    }
}

extension FileURL {
    func contentsOfDirectory() throws -> [FileURL] {
        return try FileManager().contentsOfDirectory(at: asURL, includingPropertiesForKeys: FileURL.urlResourceKeys)
            .map { FileURL(url: $0) }
            .sorted()
    }
}

extension FileURL {
    static var urlResourceKeys: [URLResourceKey] {
        [.isReadableKey, .isWritableKey, .isDirectoryKey, .isSymbolicLinkKey, .fileResourceTypeKey, .fileSizeKey, .volumeURLKey, .tagNamesKey]
    }

    var isReadable: Bool {
        FileManager.default.isReadableFile(atPath: asPath)
    }
    var isWritable: Bool {
        FileManager.default.isWritableFile(atPath: asPath)
    }
    var isDirectory: Bool {
        (try? asNSURL.resourceValues(forKeys: [.isDirectoryKey]))?[.isDirectoryKey] as? Bool ?? false
    }
    var isSymbolicLink: Bool {
        (try? asNSURL.resourceValues(forKeys: [.isSymbolicLinkKey]))?[.isSymbolicLinkKey] as? Bool ?? false
    }
    var isSpecialFile: Bool {
        let type = try? url.resourceValues(forKeys: [.fileResourceTypeKey]).fileResourceType
        switch type {
        case .namedPipe, .socket, .characterSpecial, .blockSpecial:
            return true
        default:
            return false
        }
    }
    var fileSize: Int64 {
        Int64((try? asNSURL.resourceValues(forKeys: [.fileSizeKey]))?[.fileSizeKey] as? Int ?? 0)
    }
    var volumeURL: URL? {
        (try? asNSURL.resourceValues(forKeys: [.volumeURLKey]))?[.volumeURLKey] as? URL
    }
    var tags: [String] {
        return (try? asNSURL.resourceValues(forKeys: [.tagNamesKey]))?[.tagNamesKey] as? [String] ?? []
    }
    var isExcludedFromBackup: Bool {
        // True if some mechanism *other than Peekaboo* has already marked this item excluded from backup
        (try? asNSURL.resourceValues(forKeys: [.isExcludedFromBackupKey]))?[.isExcludedFromBackupKey] as? Bool ?? false
    }
}

extension FileURL {
    func recursiveImpact() -> (fileCount: Int, totalSize: Int64) {
        guard let ownVolume = volumeURL else { return (0, 0) }

        var fileCount = 0
        var totalSize: Int64 = 0

        func visit(_ item: FileURL) {
            guard !item.isSymbolicLink else { return }
            guard item.volumeURL == ownVolume else { return }

            if item.isDirectory {
                guard let children = try? item.contentsOfDirectory() else { return }
                for child in children { visit(child) }
            } else {
                fileCount += 1
                totalSize += item.fileSize
            }
        }

        visit(self)
        return (fileCount, totalSize)
    }
}
