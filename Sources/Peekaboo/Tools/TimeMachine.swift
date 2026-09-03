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
        return TimeMachine.currentSkipPaths().filter {
            let p = $0.asPath
            return p == base || p.hasPrefix(base + "/")
        }
    }
}

extension TimeMachine: ExclusionListDestination {
    // TODO: when updating skip paths, we need to only update the ones whose prefix is our baseURL

    func exclude(urls: [FileURL]) throws {
        guard !urls.isEmpty else { return }
        var excludedURLs = Set(TimeMachine.currentSkipPaths())
        for url in urls {
            if excludedURLs.contains(url) { continue }
            excludedURLs.insert(url)
            print("ADD    [\(name)]: \(url.asPath)")
        }
        try TimeMachine.writeSkipPaths(excludedURLs)
    }
    
    func include(urls: [FileURL]) throws {
        guard !urls.isEmpty else { return }
        var excludedURLs = TimeMachine.currentSkipPaths()
        for url in urls {
            excludedURLs.remove(url)
            print("REMOVE [\(name)]: \(url.asPath)")
        }
        try TimeMachine.writeSkipPaths(excludedURLs)
    }
}

private extension TimeMachine {
    static let plistPath = "/Library/Preferences/com.apple.TimeMachine.plist"

    /// Reads SkipPaths directly from the plist — no subprocess needed,
    /// same reason `defaults read` never needed sudo: this file is
    /// world-readable, only writes are privileged.
    static func currentSkipPaths() -> Set<FileURL> {
        guard let data = FileManager.default.contents(atPath: plistPath),
              let plist = try? PropertyListSerialization.propertyList(from: data, options: [], format: nil) as? [String: Any],
              let skipPaths = plist["SkipPaths"] as? [String]
        else { return [] }
        return Set(skipPaths.map { FileURL(path: $0) })
    }

    static func writeSkipPaths(_ paths: Set<FileURL>) throws {
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
        try Shell.run("sudo", ["tmutil", "delete", "-p", url.asPath, backupName])
    }
}
