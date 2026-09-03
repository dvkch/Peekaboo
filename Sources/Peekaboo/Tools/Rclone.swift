//
//  Rclone.swift
//  peekaboo
//
//  Created by syan on 03/09/2026.
//

import Foundation

struct Rclone: ExclusionListTool {

    // MARK: Init
    init(excludeFileURL: URL, baseURL: URL) {
        self.excludeFileURL = excludeFileURL
        self.baseURL = baseURL
    }

    // MARK: Properties
    let excludeFileURL: URL
    let baseURL: URL

    var name: String { "Rclone" }
}

extension Rclone: ExclusionListSource {
    // walk each kept directory and check for ignored files in it
    func excludedURLs() throws -> [URL] {
        let keptDirs = try keptRelativePaths(filesOnly: false)
        let keptFiles = try keptRelativePaths(filesOnly: true)

        var excluded: [URL] = []
        let fm = FileManager.default

        for reldir in keptDirs.sorted() {
            let dirURL = reldir.isEmpty ? baseURL : baseURL.appendingPathComponent(reldir)

            guard let children = try? fm.contentsOfDirectory(
                at: dirURL,
                includingPropertiesForKeys: [.isDirectoryKey, .isSymbolicLinkKey]
            ) else { continue }

            for child in children.sorted(by: { $0.lastPathComponent < $1.lastPathComponent }) {
                let values = try? child.resourceValues(forKeys: [.isDirectoryKey, .isSymbolicLinkKey])
                guard values?.isSymbolicLink != true else { continue }

                let childRel = reldir.isEmpty ? child.lastPathComponent : "\(reldir)/\(child.lastPathComponent)"
                let stillKept = (values?.isDirectory == true)
                    ? keptDirs.contains(childRel)
                    : keptFiles.contains(childRel)

                guard !stillKept else { continue }
                excluded.append(child)
            }
        }

        return excluded
    }
}

private extension Rclone {
    // list the files that are kept by rclone when using our exclusion file
    func keptRelativePaths(filesOnly: Bool) throws -> Set<String> {
        let output = try Shell.run("rclone", [
            "lsf",
            "-R",
            filesOnly ? "--files-only" : "--dirs-only",
            "--exclude-from", excludeFileURL.path(percentEncoded: false),
            baseURL.path(percentEncoded: false)
        ])

        var kept: Set<String> = filesOnly ? [] : [""]
        for line in output.split(separator: "\n") {
            var path = String(line)
            if path.hasSuffix("/") { path.removeLast() }
            kept.insert(path)
        }
        return kept
    }
}
