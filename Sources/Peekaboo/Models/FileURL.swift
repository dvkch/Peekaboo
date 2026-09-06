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
        self.url = url.standardizedFileURL
    }
    
    init(path: String) {
        self.url = URL(filePath: (path as NSString).expandingTildeInPath).standardizedFileURL
    }
    
    var asURL: URL { url }
    var asPath: String { url.path(percentEncoded: false) }
    var asNSURL: NSURL { url as NSURL }
    var isReadable: Bool {
        FileManager.default.isReadableFile(atPath: asPath)
    }
    var isWritable: Bool {
        FileManager.default.isWritableFile(atPath: asPath)
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
    var tags: [String] {
        return (try? asNSURL.resourceValues(forKeys: [.tagNamesKey]))?[.tagNamesKey] as? [String] ?? []
    }
    var isSymbolicLink: Bool {
        (try? asNSURL.resourceValues(forKeys: [.isSymbolicLinkKey]))?[.isSymbolicLinkKey] as? Bool ?? false
    }
    var isDirectory: Bool {
        (try? asNSURL.resourceValues(forKeys: [.isDirectoryKey]))?[.isDirectoryKey] as? Bool ?? false
    }
    var isEmptyDirectory: Bool {
        guard isDirectory else { return false }
        do {
            return try FileManager.default.contentsOfDirectory(atPath: asPath).count == 0
        }
        catch {
            return false
        }
    }
}

extension FileURL: Hashable, Equatable, Comparable {
    static func < (lhs: FileURL, rhs: FileURL) -> Bool {
        return lhs.asPath < rhs.asPath
    }
}
