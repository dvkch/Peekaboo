//
//  TimeMachine.swift
//  peekaboo
//
//  Created by syan on 03/09/2026.
//

import Foundation

struct TimeMachine: ExclusionListTool {

    // MARK: Init
    init(baseURL: URL) {
        self.baseURL = baseURL
    }

    // MARK: Properties
    let baseURL: URL
    var name: String { "TimeMachine" }
}

extension TimeMachine: ExclusionListSource {
    func excludedURLs() throws -> [URL] {
        let base = baseURL.standardizedFileURL.path()
        return TimeMachine.currentSkipPaths()
            .map { URL(filePath: $0) }
            .filter {
                let p = $0.standardizedFileURL.path()
                return p == base || p.hasPrefix(base + "/")
            }
    }
}

extension TimeMachine: ExclusionListDestination {
    func exclude(urls: [URL]) throws {
        guard !urls.isEmpty else { return }
        var paths = TimeMachine.currentSkipPaths()

        for url in urls {
            let path = url.standardizedFileURL.path()
            guard !paths.contains(path) else { continue }
            paths.append(path)
            print("ADD    [\(name)]: \(path)")
        }

        try TimeMachine.writeSkipPaths(paths)
    }

    func include(urls: [URL]) throws {
        guard !urls.isEmpty else { return }
        let toRemove = Set(urls.map { $0.standardizedFileURL.path() })
        var paths = TimeMachine.currentSkipPaths()
        paths.removeAll { toRemove.contains($0) }

        for url in urls {
            print("REMOVE [\(name)]: \(url.standardizedFileURL.path())")
        }

        try TimeMachine.writeSkipPaths(paths)
    }
}

private extension TimeMachine {
    static let plistPath = "/Library/Preferences/com.apple.TimeMachine.plist"

    /// Reads SkipPaths directly from the plist — no subprocess needed,
    /// same reason `defaults read` never needed sudo: this file is
    /// world-readable, only writes are privileged.
    static func currentSkipPaths() -> [String] {
        guard let data = FileManager.default.contents(atPath: plistPath),
              let plist = try? PropertyListSerialization.propertyList(from: data, options: [], format: nil) as? [String: Any],
              let skipPaths = plist["SkipPaths"] as? [String]
        else { return [] }
        return skipPaths
    }

    static func writeSkipPaths(_ paths: [String]) throws {
        try Shell.run("sudo", ["defaults", "write", plistPath, "SkipPaths", "-array"] + paths)
    }
}

extension TimeMachine {
    static func listTimeMachineBackups() -> [String] {
        (try? Shell.run("tmutil", ["listbackups"]))?
            .split(separator: "\n")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty } ?? []
    }

    static func delete(url: URL, fromExistingBackup backupName: String) throws {
        try Shell.run("sudo", ["tmutil", "delete", "-p", url.standardizedFileURL.path(), backupName])
    }
}
