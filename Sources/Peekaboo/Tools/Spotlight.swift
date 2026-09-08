//
//  Spotlight.swift
//  peekaboo
//
//  Created by syan on 03/09/2026.
//

import Foundation

struct Spotlight: ExclusionListTool {

    // MARK: Init
    init(baseURL: FileURL) {
        self.baseURL = baseURL
        self.volumeURL = FileURL(url: baseURL.volumeURL!)
    }

    // MARK: Properties
    let baseURL: FileURL
    private let volumeURL: FileURL

    var name: String { "Spotlight" }
}

extension Spotlight: ExclusionListSource {
    func excludedURLs() throws -> [FileURL] {
        let base = baseURL.asPath
        return try store().read().filter {
            let p = $0.asPath
            return p == base || p.hasPrefix(base)
        }
    }
    
    func removeURLsExcludedByDefault(_ urls: [FileURL]) -> [FileURL] {
        return urls.filter { !$0.isNoIndex }
    }
}

extension Spotlight: ExclusionListDestination {
    var requiresRoot: Bool { true }

    func markURLs(_ urls: [FileURL], excluded: Bool) throws {
        guard !urls.isEmpty else { return }
        var exclusions = try store().read()
        var changed = false

        for url in urls {
            guard url.asPath == baseURL.asPath || url.asPath.hasPrefix(baseURL.asPath) else {
                Log.w(name, "SKIPPED  - \(url.asPath) is outside \(baseURL.asPath), refusing to touch")
                continue
            }
            
            switch exclusions.setElement(url, present: excluded) {
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
        try store().write(Set(exclusions))
    }
    
    func applyMarkedURLs() throws {
        // mds must be relaunched for a plist edit to actually take effect.
        // launchctl stop/start doesn't work — mds appears to just stay
        // alive under launchd's KeepAlive without re-reading anything —
        // and launchctl kickstart is blocked outright by SIP. Plain
        // SIGTERM via pkill is the only mechanism confirmed to work: mds
        // exits cleanly, launchd relaunches it, and it picks up the change.
        try Shell.run("sudo", ["pkill", "mds"])
    }
}

private extension Spotlight {
    func plistURL() throws(AppError) -> FileURL {
        var baseURL = volumeURL
        if baseURL.asPath == "/" {
            baseURL = FileURL(path: "/System/Volumes/Data")
        }
        return FileURL(url: baseURL.asURL.appendingPathComponent(".Spotlight-V100/VolumeConfiguration.plist"))
    }

    func store() throws(AppError) -> PlistExclusionsStore {
        return PlistExclusionsStore(plistURL: try plistURL(), arrayKey: "Exclusions", toolName: name, requiresRootToRead: true, relativeTo: volumeURL)
    }
}
