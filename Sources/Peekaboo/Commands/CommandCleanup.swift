//
//  CommandCleanup.swift
//  peekaboo
//
//  Created by syan on 03/09/2026.
//

import Foundation
import ArgumentParser

struct CommandCleanup: ParsableCommand {
    static var configuration = CommandConfiguration(
        commandName: "cleanup",
        abstract: "Cleanup excluded files from TimeMachine backups"
    )
    
    @Option(help: "Log verbosity level.")
    var logLevel: Log.Level = .info

    mutating func run() throws {
        Log.level = logLevel
        let config = try Config.readConfig()

        let timeMachineBackups = TimeMachine.listTimeMachineBackups()
        
        print("Cleaning up TimeMachine backups according to rclone exclusion files")
        print("")
        print("This requires your password:")
        try Shell.run("sudo", ["-v"])
        print("")

        for location in config.locations {
            print("-- Location: \(location.path.asPath)")
            print("-- Exclusion files: \(location.exclusionFiles.map(\.asPath).joined(separator: ", "))")
            let rclone = Rclone(location: location)
            let excludedPaths = try rclone.excludedURLs()
            
            for excludedPath in excludedPaths {
                for backup in timeMachineBackups {
                    try TimeMachine.delete(url: excludedPath, fromExistingBackup: backup)
                }
            }
        }
    }
}

