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
        return TimeMachine.readSkippedPaths().filter {
            let p = $0.asPath
            return p == base || p.hasPrefix(base + "/")
        }
    }
}

extension TimeMachine: ExclusionListDestination {
    func markURLs(_ urls: [FileURL], excluded: Bool) throws {
        guard !urls.isEmpty else { return }
        var skippedPaths = TimeMachine.readSkippedPaths()
        var changed = false

        for url in urls {
            guard url.asPath == baseURL.asPath || url.asPath.hasPrefix(baseURL.asPath + "/") else {
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
        try TimeMachine.writeSkippedPaths(Set(skippedPaths))
    }
}

private extension TimeMachine {
    static let plistPath = "/Library/Preferences/com.apple.TimeMachine.plist"

    /// Reads SkipPaths directly from the plist — no subprocess needed,
    /// same reason `defaults read` never needed sudo: this file is
    /// world-readable, only writes are privileged.
    static func readSkippedPaths() -> [FileURL] {
        guard let data = FileManager.default.contents(atPath: plistPath),
              let plist = try? PropertyListSerialization.propertyList(from: data, options: [], format: nil) as? [String: Any],
              let skipPaths = plist["SkipPaths"] as? [String]
        else { return [] }
        return skipPaths.map { FileURL(path: $0) }
    }

    static func writeSkippedPaths(_ paths: Set<FileURL>) throws {
        try Shell.run("sudo", ["defaults", "write", plistPath, "SkipPaths", "-array"] + paths.map(\.asPath).sorted())
    }
}

extension TimeMachine {
    static func listTimeMachineBackups() -> [String] {
        (try? Shell.run("tmutil", ["listbackups"]))?
            .split(separator: "\n")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty } ?? []
    }

    static func delete(url: FileURL, fromExistingBackup backupName: String) throws {
        Log.w("TimeMachine", "Deleting \(url.asPath) from \(backupName)...")
        // TODO: reenable, but this is a test for now
        // try Shell.run("sudo", ["tmutil", "delete", "-p", url.asPath, backupName])
    }
}
