//
//  FinderTag.swift
//  peekaboo
//
//  Created by syan on 03/09/2026.
//

import Foundation

struct FinderTag: ExclusionListTool {

    // MARK: Init
    init(tagName: String, baseURL: FileURL) {
        self.tagName = tagName
        self.baseURL = baseURL
    }

    // MARK: Properties
    let tagName: String
    let baseURL: FileURL

    var name: String { "FinderTag(\(tagName))" }
}

extension FinderTag: ExclusionListSource {
    func excludedURLs() throws -> [FileURL] {
        return NSMetadataQuery.paths(predicateFormat: "kMDItemUserTags == %@", arguments: [tagName], baseURL: baseURL)
    }
}

// Logic actually is reversed here. The goal is to have a visible tag that contains all the items
// excluded from rclone/TimeMachine/Spotlight. So excluding an item means adding the tag.
extension FinderTag: ExclusionListDestination {
    func exclude(urls: [FileURL]) throws {
        for url in urls {
            do {
                try FinderTag.addTag(tagName, to: url)
                print("ADD    [\(name)]: \(url.asPath)")
            } catch {
                print("  (failed to tag \(url.asPath): \(error))")
            }
        }
    }

    func include(urls: [FileURL]) throws {
        for url in urls {
            do {
                try FinderTag.removeTag(tagName, from: url)
                print("REMOVE [\(name)]: \(url.asPath)")
            } catch {
                print("  (failed to untag \(url.asPath): \(error))")
            }
        }
    }
}

private extension FinderTag {
    static func addTag(_ tag: String, to url: FileURL) throws {
        var existing = currentTags(for: url)
        guard !existing.contains(tag) else { return }
        existing.append(tag)
        try url.asNSURL.setResourceValue(existing, forKey: .tagNamesKey)
    }

    static func removeTag(_ tag: String, from url: FileURL) throws {
        var existing = currentTags(for: url)
        guard let index = existing.firstIndex(of: tag) else { return }
        existing.remove(at: index)
        try url.asNSURL.setResourceValue(existing, forKey: .tagNamesKey)
    }

    static func currentTags(for url: FileURL) -> [String] {
        (try? url.asNSURL.resourceValues(forKeys: [.tagNamesKey]))?[.tagNamesKey] as? [String] ?? []
    }
}
