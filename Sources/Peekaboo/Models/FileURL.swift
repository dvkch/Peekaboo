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
}

extension FileURL: Hashable, Equatable {}
