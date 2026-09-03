//
//  CommandSync.swift
//  peekaboo
//
//  Created by syan on 03/09/2026.
//

import Foundation
import ArgumentParser

struct CommandSync: ParsableCommand {
    static var configuration = CommandConfiguration(
        commandName: "sync",
        abstract: "Update exclusion lists"
    )

    mutating func run() throws {
        let config = try Config.readConfig()

        for exclusionFile in config.exclusionFiles {
            print("-- Exclusion file: \(exclusionFile.path.standardizedFileURL.path(percentEncoded: false))")
            print("-- Relative to: \(exclusionFile.relativeTo.standardizedFileURL.path(percentEncoded: false))")

            let rclone = Rclone(excludeFileURL: exclusionFile.path, baseURL: exclusionFile.relativeTo)
            let rcloneExclusions = Set(try rclone.excludedURLs())
            print("Found \(rcloneExclusions.count) excluded items")

            for tool in activeTools(config: config, baseURL: exclusionFile.relativeTo) {
                let toolExclusions = Set((try? tool.excludedURLs()) ?? [])
                try? tool.exclude(urls: Array(rcloneExclusions.subtracting(toolExclusions)))
                try? tool.include(urls: Array(toolExclusions.subtracting(rcloneExclusions)))
            }
        }
    }
}

private extension CommandSync {
    func activeTools(config: Config, baseURL: URL) -> [ExclusionListSource & ExclusionListDestination] {
        var tools: [ExclusionListSource & ExclusionListDestination] = []
        if config.finderTag.enabled {
            tools.append(FinderTag(tagName: config.finderTag.name, baseURL: baseURL))
        }
        if config.timeMachine.enabled {
            tools.append(TimeMachine(baseURL: baseURL))
        }
        return tools
    }
}
