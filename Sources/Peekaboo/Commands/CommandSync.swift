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
        
        if config.timeMachine.enabled {
            print("Time Machine sync requires your password:")
            try Shell.run("sudo", ["-v"])
            print("")
        }

        for location in config.locations {
            let startDate = Date.now
            print("-- Location: \(location.path.asPath)")
            print("-- Exclusion files: \(location.exclusionFiles.map(\.asPath).joined(separator: ", "))")

            let rclone = Rclone(location: location)
            let rcloneExclusions = Set(try rclone.excludedURLs())
            print("Found \(rcloneExclusions.count) excluded items")

            for tool in activeTools(config: config, baseURL: location.path) {
                let toolExclusions = Set((try? tool.excludedURLs()) ?? [])

                let toAdd = rcloneExclusions.subtracting(toolExclusions)
                let writable = toAdd.filter(\.isWritable)
                let unwritable = toAdd.subtracting(writable)

                for url in unwritable {
                    print("  (skipping \(url.asPath) — no write access, likely a protected system directory)")
                }

                try? tool.exclude(urls: Array(writable))
                try? tool.include(urls: Array(toolExclusions.subtracting(rcloneExclusions)))
            }
            print("-> Synced in \(Int(Date.now.timeIntervalSince(startDate)))s")
            print("")
        }
    }
}

private extension CommandSync {
    func activeTools(config: Config, baseURL: FileURL) -> [ExclusionListSource & ExclusionListDestination] {
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
