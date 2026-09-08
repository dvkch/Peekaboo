//
//  CommandImpact.swift
//  peekaboo
//
//  Created by syan on 07/09/2026.
//

import Foundation
import ArgumentParser

struct CommandImpact: ParsableCommand {
    static var configuration = CommandConfiguration(
        commandName: "impact",
        abstract: "Measure the size and file count of currently excluded items"
    )

    @Option(help: "Log verbosity level.")
    var logLevel: Log.Level = .info
    
    @Option(help: "Minimum item total size to include in the report")
    var minSizeMB: UInt64 = 100
    
    @Option(help: "Minimum item descendants count to include in the report")
    var minFileCount = 1000

    mutating func run() throws {
        Log.level = logLevel
        let config = try Config.readConfig()
        let sizeThreshold = minSizeMB * 1024 * 1024
        let columnWidth = 8

        print("Measuring impact of exclusion files...")
        print("")

        for location in config.locations {
            let startDate = Date.now
            print("-- Location: \(location.path.asPath)")
            print("-- Exclusion files: \(location.exclusionFiles.map(\.asPath).joined(separator: ", "))")
            let rclone = Rclone(location: location)
            let allExcludedPaths = try rclone.excludedURLs()

            var impacts: [FileURL: (fileCount: Int, totalSize: Int64)] = [:]
            let lock = NSLock()

            DispatchQueue.concurrentPerform(iterations: allExcludedPaths.count) { index in
                let url = allExcludedPaths[index]
                let d = Date.now
                let result = url.recursiveImpact()
                let t = Date.now.timeIntervalSince(d)
                if t > 10 {
                    Log.w("Slow measure", "\(Int(t))s for \(url.asPath)")
                }
                lock.withLock { impacts[url] = result }
            }

            let bySize = impacts.filter { $0.value.totalSize > sizeThreshold }.sorted { $0.value.totalSize > $1.value.totalSize }
            let byCount = impacts.filter { $0.value.fileCount > minFileCount }.sorted { $0.value.fileCount > $1.value.fileCount }
            let bySizeTotal = impacts.values.reduce(0) { $0 + $1.totalSize }
            let byCountTotal = impacts.values.reduce(0) { $0 + $1.fileCount }

            print("Most impactful exclusions by total size (\(bySizeTotal.formattedSize) total)")
            for item in bySize {
                let value = item.value.totalSize.formattedSize.leftPadded(toLength: columnWidth)
                print(" \(value) \(item.key.asPath)")
            }
            print("")

            print("Most impactful exclusions by file count (\(byCountTotal) files total)")
            for item in byCount {
                let value = String(item.value.fileCount).leftPadded(toLength: columnWidth)
                print(" \(value) \(item.key.asPath)")
            }
            print("")

            print("-> Measured in \(Int(Date.now.timeIntervalSince(startDate)))s")
            print("")
        }

        print("Note: sizes reflect the logical size of these items on your live filesystem right")
        print("now, not a guaranteed prediction of Time Machine destination space freed.")
    }
}
