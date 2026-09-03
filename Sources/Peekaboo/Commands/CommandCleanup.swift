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
        commandName: "Cleanup",
        abstract: "Cleanup excluded files from TimeMachine backups"
    )
    
    mutating func run() throws {
        guard let config = try? Config.readConfig() else {
            print("Configuration file couldn't be read properly.")
            return
        }
        
        let timeMachineBackups = TimeMachine.listTimeMachineBackups()
        
        print("Cleaning up TimeMachine backups according to rclone exclusion files")
        print("")
        print("This requires your password:")
        try Shell.run("sudo", ["-v"])
        print("")

        for exclusionFile in config.exclusionFiles {
            print("-- Exclusion file: \(exclusionFile.path)")
            print("-- Relative to: \(exclusionFile.relativeTo)")
            let rclone = Rclone(excludeFileURL: exclusionFile.path, baseURL: exclusionFile.relativeTo)
            let excludedPaths = try rclone.excludedURLs()
            print("Found \(excludedPaths.count) excluded items")
            
            for excludedPath in excludedPaths {
                for backup in timeMachineBackups {
                    print("Deleting \(excludedPath.standardizedFileURL.path()) from \(backup)...")
                    // TODO: reenable, but this is a test for now
                    // try TimeMachine.delete(url: excludedPath, fromExistingBackup: backup)
                }
            }
        }
    }
}

