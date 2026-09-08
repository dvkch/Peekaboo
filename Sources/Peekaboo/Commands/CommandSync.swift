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
        
        for location in config.locations {
            let startDate = Date.now
            print("-- Location: \(location.path.asPath)")
            print("-- Exclusion files: \(location.exclusionFiles.map(\.asPath).joined(separator: ", "))")

            let rclone = Rclone(location: location)
            let rcloneExclusions = Set(try rclone.excludedURLs())

            for tool in activeTools(config: config, baseURL: location.path) {
                do {
                    let toolExclusions = Set((try tool.excludedURLs()))
                    let toAdd = rcloneExclusions.subtracting(toolExclusions)
                    let toDelete = toolExclusions.subtracting(rcloneExclusions)

                    guard !toAdd.isEmpty || !toDelete.isEmpty else {
                        Log.i(tool.name, "Nothing to update")
                        continue
                    }

                    if tool.requiresRoot {
                        try Shell.askForSudo(message: "\(tool.name) requires your password:")
                    }

                    try tool.markURLs(Array(toAdd).sorted(), excluded: true)
                    try tool.markURLs(Array(toDelete).sorted(), excluded: false)
                    Log.i(tool.name, "Updated successfully")
                }
                catch {
                    Log.e(tool.name, "Couldn't update exclusion list: \(error.localizedDescription)")
                }
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
        if config.spotlight.enabled {
            tools.append(Spotlight(baseURL: baseURL))
        }
        return tools
    }
}
