//
//  TimeMachine.swift
//  peekaboo
//
//  Created by syan on 03/09/2026.
//

import Foundation

struct TimeMachine: ExclusionListTool {

    // MARK: Init
    init(baseURL: FileURL) {
        self.baseURL = baseURL
    }

    // MARK: Properties
    let baseURL: FileURL
    var name: String { "TimeMachine" }
}

extension TimeMachine: ExclusionListSource {
    func excludedURLs() throws -> [FileURL] {
        let base = baseURL.asPath
        return try store().read().filter {
            let p = $0.asPath
            return p == base || p.hasPrefix(base)
        }
    }
    
    func filterURLsExcludedByDefault(_ urls: [FileURL]) -> [FileURL] {
        return urls.filter { !$0.isExcludedFromBackup }
    }
}

extension TimeMachine: ExclusionListDestination {
    var requiresRoot: Bool { true }
    
    func markURLs(_ urls: [FileURL], excluded: Bool) throws {
        guard !urls.isEmpty else { return }
        var skippedPaths = try store().read()
        var changed = false

        for url in urls {
            guard url.asPath == baseURL.asPath || url.asPath.hasPrefix(baseURL.asPath) else {
                Log.w(name, "SKIPPED - \(url.asPath) is outside \(baseURL.asPath), refusing to touch")
                continue
            }

            switch skippedPaths.setElement(url, present: excluded) {
            case .added:
                Log.i(name, "ADDED    - \(url.asPath)")
                changed = true
            case .removed:
                Log.i(name, "REMOVED  - \(url.asPath)")
                changed = true
            case .alreadyPresent:
                Log.d(name, "SKIPPPED - Already excluded: \(url.asPath)")
            case .alreadyAbsent:
                Log.d(name, "SKIPPPED - Wasn't excluded: \(url.asPath)")
            }
        }

        guard changed else { return }
        try store().write(Set(skippedPaths))
    }
    
    func applyMarkedURLs() throws {}
}

private extension TimeMachine {
    func store() -> PlistStore {
        PlistStore(
            plistURL: FileURL(path: "/Library/Preferences/com.apple.TimeMachine.plist"),
            arrayKey: "SkipPaths",
            toolName: "TimeMachine",
            requiresRootToRead: false
        )
    }
}
