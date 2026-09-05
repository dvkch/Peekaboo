//
//  CommandSync.swift
//  peekaboo
//
//  Created by syan on 03/09/2026.
//

import Foundation
import ArgumentParser

// TODO: uninstall asimov and cleanup its exclusions
struct CommandSync: ParsableCommand {
    static var configuration = CommandConfiguration(
        commandName: "sync",
        abstract: "Update exclusion lists"
    )

    @Option(help: "Log verbosity level.")
    var logLevel: Log.Level = .info

    mutating func run() throws {
        Log.level = logLevel
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

            for tool in activeTools(config: config, baseURL: location.path) {
                let toolExclusions = Set((try? tool.excludedURLs()) ?? [])

                let toAdd = rcloneExclusions.subtracting(toolExclusions)
                try? tool.markURLs(Array(toAdd), excluded: true)
                try? tool.markURLs(Array(toolExclusions.subtracting(rcloneExclusions)), excluded: false)
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
