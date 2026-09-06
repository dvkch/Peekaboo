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
        FinderTag.taggedItems(under: baseURL, tag: tagName)
    }
}

// Logic actually is reversed here. The goal is to have a visible tag that contains all the items
// excluded from rclone/TimeMachine/Spotlight. So excluding an item means adding the tag.
extension FinderTag: ExclusionListDestination {
    func markURLs(_ urls: [FileURL], excluded: Bool) throws {
        for url in urls {
            try setTag(to: url, mark: excluded)
        }
    }
    
    private func setTag(to url: FileURL, mark: Bool) throws {
        guard url.isWritable else {
            Log.d(name, "SKIPPPED - URL is not writable \(url.asPath)")
            return
        }

        var tags = url.tags
        switch tags.setElement(tagName, present: mark) {
        case .added:
            Log.i(name, "ADDED    - \(url.asPath)")
        case .removed:
            Log.i(name, "REMOVED  - \(url.asPath)")
        case .alreadyPresent:
            Log.d(name, "SKIPPPED - Tag already exists for \(url.asPath)")
            return
        case .alreadyAbsent:
            Log.d(name, "SKIPPPED - Tag already absent for \(url.asPath)")
            return
        }
        
        do {
            try url.asNSURL.setResourceValue(tags, forKey: .tagNamesKey)
        }
        catch {
            Log.w(name, "FAILED   - to set tag on \(url.asPath): \(error.localizedDescription)")
        }
    }
}

private extension FinderTag {
    static func taggedItems(under baseURL: FileURL, tag: String) -> [FileURL] {
        var found: [FileURL] = []

        func visit(_ dir: FileURL) {
            let propertyKeys: [URLResourceKey] = [.isDirectoryKey, .isSymbolicLinkKey, .tagNamesKey, .isReadableKey]
            var children: [FileURL] = []

            do {
                children = try FileManager.default.contentsOfDirectory(at: dir.asURL, includingPropertiesForKeys: propertyKeys)
                    .sorted(by: { $0.lastPathComponent < $1.lastPathComponent })
                    .map { FileURL(url: $0) }
            }
            catch {
                Log.w("FinderTag", "Couldn't visit \(dir.asPath), skipping")
                return
            }
                
            for child in children {
                guard !child.isSymbolicLink else { continue }
                
                if child.tags.contains(tag) {
                    found.append(child)
                }
                else if child.isDirectory {
                    // only visit non excluded folders
                    visit(child)
                }
            }
        }

        visit(baseURL)
        return found
    }
}
