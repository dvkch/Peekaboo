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
        [.isReadableKey, .isWritableKey, .isDirectoryKey, .isSymbolicLinkKey, .fileResourceTypeKey, .fileSizeKey, .volumeUUIDStringKey, .isHiddenKey, .tagNamesKey]
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
    var volumeUUID: String? {
        (try? asNSURL.resourceValues(forKeys: [.volumeUUIDStringKey]))?[.volumeUUIDStringKey] as? String
    }
    var tags: [String] {
        return (try? asNSURL.resourceValues(forKeys: [.tagNamesKey]))?[.tagNamesKey] as? [String] ?? []
    }
    var isExcludedFromBackup: Bool {
        // True if some mechanism *other than Peekaboo* has already marked this item excluded from backup
        (try? asNSURL.resourceValues(forKeys: [.isExcludedFromBackupKey]))?[.isExcludedFromBackupKey] as? Bool ?? false
    }
    var hasFileProviderDomainID: Bool {
        // to ignore Apple File Provider locations
        getxattr(asPath, "com.apple.file-provider-domain-id", nil, 0, 0, 0) >= 0
    }
    var volumeURL: URL? {
        (try? asNSURL.resourceValues(forKeys: [.volumeURLKey]))?[.volumeURLKey] as? URL
    }
    
    var isExcludedFromSpotlight: Bool {
        (try? Shell.run("tmutil", ["isexcluded", asPath]))?.contains("[Excluded]") ?? false
    }

    var isHiddenOrDescendantOfHidden: Bool {
        var current = asURL
        while current.pathComponents.count > 1 {
            if (try? current.resourceValues(forKeys: [.isHiddenKey]))?.isHidden == true {
                return true
            }
            current.deleteLastPathComponent()
        }
        return false
    }
}

extension FileURL {
    func recursiveImpact() -> (fileCount: Int, totalSize: Int64) {
        guard let ownVolume = volumeUUID else { return (0, 0) }
        var fileCount = 0
        var totalSize: Int64 = 0

        let resourceKeys: [URLResourceKey] = [.isDirectoryKey, .isSymbolicLinkKey, .fileSizeKey, .volumeUUIDStringKey]

        guard let enumerator = FileManager.default.enumerator(
            at: asURL,
            includingPropertiesForKeys: resourceKeys
        ) else { return (0, 0) }
        
        for case let itemURL as URL in enumerator {
            guard let values = try? itemURL.resourceValues(forKeys: Set(resourceKeys)) else { continue }
            guard values.volumeUUIDString == ownVolume else {
                enumerator.skipDescendants()
                continue
            }
            if values.isSymbolicLink == true {
                enumerator.skipDescendants()
                continue
            }
            if values.isDirectory == true && FileURL(url: itemURL).hasFileProviderDomainID {
                enumerator.skipDescendants()
                continue
            }
            if values.isDirectory != true {
                fileCount += 1
                totalSize += Int64(values.fileSize ?? 0)
            }
        }
        return (fileCount, totalSize)
    }
}
