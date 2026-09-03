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
        guard let config = try? Config.readConfig() else {
            print("Configuration file couldn't be read properly.")
            return
        }

        for exclusionFile in config.exclusionFiles {
            print("-- Exclusion file: \(exclusionFile.path.path())")
            print("-- Relative to: \(exclusionFile.relativeTo.path())")

            let rclone = Rclone(excludeFileURL: exclusionFile.path, baseURL: exclusionFile.relativeTo)
            let rcloneExcludedURLs = Set(try rclone.excludedURLs())
            print("Found \(rcloneExcludedURLs.count) excluded items")

            for tool in activeTools(config: config, baseURL: exclusionFile.relativeTo) {
                sync(rcloneExcludedURLs: rcloneExcludedURLs, with: tool)
            }
        }
    }
}

private extension CommandSync {
    func activeTools(config: Config, baseURL: URL) -> [ExclusionListSource & ExclusionListDestination] {
        var destinations: [ExclusionListSource & ExclusionListDestination] = []

        if config.finderTag.enabled {
            destinations.append(FinderTag(tagName: config.finderTag.name, baseURL: baseURL))
        }
        if config.timeMachine.enabled {
            destinations.append(TimeMachine(baseURL: baseURL))
        }

        return destinations
    }

    /// Brings one destination in line with what rclone currently wants
    /// excluded: adds what's missing, removes what's stale.
    func sync(rcloneExcludedURLs: Set<URL>, with tool: ExclusionListSource & ExclusionListDestination) {
        let toolExcludedURLs = Set((try? tool.excludedURLs()) ?? [])

        let toAdd = rcloneExcludedURLs.subtracting(toolExcludedURLs)
        let toRemove = toolExcludedURLs.subtracting(rcloneExcludedURLs)

        for url in toAdd.sorted(by: { $0.path() < $1.path() }) {
            do {
                try tool.exclude(url: url)
                print("ADD    [\(tool.name)]: \(url.path())")
            } catch {
                print("  (failed to exclude \(url.path()) via \(tool.name): \(error))")
            }
        }

        for url in toRemove.sorted(by: { $0.path() < $1.path() }) {
            do {
                try tool.include(url: url)
                print("REMOVE [\(tool.name)]: \(url.path())")
            } catch {
                print("  (failed to re-include \(url.path()) via \(tool.name): \(error))")
            }
        }
    }
}
