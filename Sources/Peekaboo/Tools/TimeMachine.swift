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
        NSMetadataQuery.paths(
            predicateFormat: "com_apple_backup_excludeItem = %@",
            arguments: ["com.apple.backupd"],
            baseURL: baseURL
        )
    }
}

extension TimeMachine: ExclusionListDestination {
    func exclude(url: URL) throws {
        try TimeMachine.setExcluded(true, url: url)
    }

    func include(url: URL) throws {
        try TimeMachine.setExcluded(false, url: url)
    }
}

private extension TimeMachine {
    static func setExcluded(_ excluded: Bool, url: URL) throws {
        var url = url
        var resourceValues = URLResourceValues()
        resourceValues.isExcludedFromBackup = excluded
        try url.setResourceValues(resourceValues)
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
