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
        return try TimeMachine.readSkippedPaths().filter {
            let p = $0.asPath
            return p == base || p.hasPrefix(base)
        }
    }
}

extension TimeMachine: ExclusionListDestination {
    var markingURLsRequiresRoot: Bool { true }
    
    func markURLs(_ urls: [FileURL], excluded: Bool) throws {
        guard !urls.isEmpty else { return }
        var skippedPaths = try TimeMachine.readSkippedPaths()
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
        try TimeMachine.writeSkippedPaths(Set(skippedPaths))
    }
}

private extension TimeMachine {
    static let plistURL = FileURL(path: "/Library/Preferences/com.apple.TimeMachine.plist")
    
    static func readSkippedPaths() throws(AppError) -> [FileURL] {
        do {
            let plistData = try Data(contentsOf: plistURL.asURL)
            let plistContent = try PropertyListSerialization.propertyList(from: plistData, options: [], format: nil)
            guard let plistMap = plistContent as? [String: Any] else { throw AppError.timeMachineMisconfiguration }
            guard let skipPaths = plistMap["SkipPaths"] as? [String] else { throw AppError.timeMachineMisconfiguration }
            return skipPaths.map { FileURL(path: $0) }
        }
        catch {
            Log.e("TimeMachine", "Unable to read TimeMachine plist: \(error.localizedDescription)")
            throw .timeMachineMisconfiguration
        }
    }
    
    static func writeSkippedPaths(_ paths: Set<FileURL>) throws(AppError) {
        do {
            let plistData = try Data(contentsOf: plistURL.asURL)
            let plistContent = try PropertyListSerialization.propertyList(from: plistData, options: [], format: nil)
            guard var plistMap = plistContent as? [String: Any] else { throw AppError.timeMachineMisconfiguration }
            plistMap["SkipPaths"] = paths.map(\.asPath).sorted()
            let data = try PropertyListSerialization.data(fromPropertyList: plistMap, format: .binary, options: 0)
            try Shell.runWithInput(data, "sudo", ["tee", plistURL.asPath])
        }
        catch {
            Log.e("TimeMachine", "Unable to update TimeMachine plist: \(error.localizedDescription)")
            throw .timeMachineMisconfiguration
        }
    }
}

extension TimeMachine {
    static func listTimeMachineBackups() throws -> [String] {
        try Shell.run("tmutil", ["listbackups"])
            .split(separator: "\n")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
    }

    static func delete(url: FileURL, fromExistingBackup backupName: String) throws {
        Log.w("TimeMachine", "Deleting \(url.asPath) from \(backupName)...")
        // TODO: reenable, but this is a test for now
        // try Shell.run("sudo", ["tmutil", "delete", "-p", url.asPath, backupName])
    }
}
