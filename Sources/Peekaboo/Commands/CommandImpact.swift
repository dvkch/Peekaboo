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

    mutating func run() throws {
        Log.level = logLevel
        let config = try Config.readConfig()

        print("Measuring impact of exclusion files...")
        print("")

        for location in config.locations {
            let startDate = Date.now
            print("-- Location: \(location.path.asPath)")
            print("-- Exclusion files: \(location.exclusionFiles.map(\.asPath).joined(separator: ", "))")
            let rclone = Rclone(location: location)
            let allExcludedPaths = try rclone.excludedURLs()

            let excludedPaths = allExcludedPaths.filter { !$0.isExcludedFromBackup }
            let skippedCount = allExcludedPaths.count - excludedPaths.count
            if skippedCount > 0 {
                print("Skipping \(skippedCount) item(s) already protected independently of Peekaboo")
            }

            var impacts: [FileURL: (fileCount: Int, totalSize: Int64)] = [:]
            let lock = NSLock()

            DispatchQueue.concurrentPerform(iterations: excludedPaths.count) { index in
                let url = excludedPaths[index]
                let d = Date.now
                let result = url.recursiveImpact()
                let t = Date.now.timeIntervalSince(d)
                if t > 10 {
                    Log.w("Slow measure", "\(Int(t))s for \(url.asPath)")
                }
                lock.withLock { impacts[url] = result }
            }

            let bySize = impacts.filter { $0.value.totalSize > CommandImpact.sizeThreshold }.sorted { $0.value.totalSize > $1.value.totalSize }
            let byCount = impacts.filter { $0.value.fileCount > CommandImpact.fileCountThreshold }.sorted { $0.value.fileCount > $1.value.fileCount }

            printRanking(
                bySize,
                title: "Most impactful exclusions by total size",
                total: CommandImpact.formatSize(impacts.values.reduce(0) { $0 + $1.totalSize }),
                line: { CommandImpact.padded(CommandImpact.formatSize($0.value.totalSize), to: CommandImpact.columnWidth) + $0.key.asPath }
            )

            printRanking(
                byCount,
                title: "Most impactful exclusions by file count",
                total: "\(impacts.values.reduce(0) { $0 + $1.fileCount }) files",
                line: { CommandImpact.padded("\($0.value.fileCount)", to: CommandImpact.columnWidth) + $0.key.asPath }
            )
            print("-> Measured in \(Int(Date.now.timeIntervalSince(startDate)))s")
            print("")
        }

        print("Note: sizes reflect the logical size of these items on your live filesystem right")
        print("now, not a guaranteed prediction of Time Machine destination space freed.")
    }
}

private extension CommandImpact {
    static let fileCountThreshold = 1000
    static let sizeThreshold: Int64 = 100 * 1024 * 1024 // 100MB
    static let columnWidth = 8

    static func formatSize(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        formatter.zeroPadsFractionDigits = true
        return formatter.string(fromByteCount: bytes)
    }

    static func padded(_ s: String, to width: Int) -> String {
        s.count >= width ? s + " " : String(repeating: " ", count: width - s.count) + s + " "
    }

    func printRanking<T>(_ items: [T], title: String, total: String, line: (T) -> String) {
        print("\(title) (total: \(total))")
        for item in items {
            print(" " + line(item))
        }
        print("")
    }
}
