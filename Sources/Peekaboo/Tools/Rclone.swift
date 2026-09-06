//
//  Rclone.swift
//  peekaboo
//
//  Created by syan on 03/09/2026.
//

import Foundation

struct Rclone: ExclusionListTool {

    // MARK: Init
    init(location: Config.Location) {
        self.baseURL = location.path
        self.excludeFilesURLs = location.exclusionFiles
    }

    // MARK: Properties
    let baseURL: FileURL
    let excludeFilesURLs: [FileURL]

    var name: String { "Rclone" }
}

extension Rclone: ExclusionListSource {
    // walk each kept directory and check for ignored files in it
    func excludedURLs() throws -> [FileURL] {
        let keptDirs = try keptRelativePaths(filesOnly: false)
        let keptFiles = try keptRelativePaths(filesOnly: true)

        var excluded: [FileURL] = []
        let fm = FileManager.default

        for reldir in keptDirs.sorted() {
            let dirURL = reldir.isEmpty ? baseURL.asURL : baseURL.asURL.appendingPathComponent(reldir)

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

                let childURL = FileURL(url: child)
                guard !childURL.isSpecialFile else { continue }
                guard childURL.isReadable else { continue }
                // should we?
                // guard !childURL.isEmptyDirectory else { continue }

                excluded.append(childURL)
            }
        }

        Log.i(name, "Found \(excluded.count) excluded items")
        return excluded
    }
}

private extension Rclone {
    // list the files that are kept by rclone when using our exclusion file
    func keptRelativePaths(filesOnly: Bool) throws -> Set<String> {
        var args = ["lsf", "-R", filesOnly ? "--files-only" : "--dirs-only", "--skip-links", "--skip-specials"]
        for excludeFileURL in self.excludeFilesURLs {
            args += ["--exclude-from", excludeFileURL.asPath]
        }
        args += [baseURL.asPath]
        let output = try Shell.run("rclone", args)

        var kept: Set<String> = filesOnly ? [] : [""]
        for line in output.split(separator: "\n") {
            var path = String(line)
            if path.hasSuffix("/") { path.removeLast() }
            kept.insert(path)
        }
        return kept
    }
}
