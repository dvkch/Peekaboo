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
        let keptDirs = try keptURLs(filesOnly: false)
        let keptFiles = try keptURLs(filesOnly: true)

        var excluded: [FileURL] = []

        for dirURL in keptDirs.sorted() {
            let childrenURLs: [FileURL]
            do { childrenURLs = try dirURL.contentsOfDirectory() }
            catch { Log.w(name, "Couldn't visit \(dirURL.asPath), skipping"); continue }

            for childURL in childrenURLs {
                guard !childURL.isSymbolicLink else { continue }

                let isKept = childURL.isDirectory ? keptDirs.contains(childURL) : keptFiles.contains(childURL)
                guard !isKept else { continue }

                guard !childURL.isSpecialFile else { continue }
                if childURL.isDirectory && childURL.hasFileProviderDomainID { continue }
                guard childURL.isReadable else { continue }

                excluded.append(childURL)
            }
        }

        Log.i(name, "Found \(excluded.count) excluded items")
        return excluded
    }
}

private extension Rclone {
    // list the files that are kept by rclone when using our exclusion file
    func keptURLs(filesOnly: Bool) throws -> Set<FileURL> {
        var args = ["lsf", "-R", filesOnly ? "--files-only" : "--dirs-only", "--skip-links", "--skip-specials"]
        for excludeFileURL in excludeFilesURLs {
            args += ["--exclude-from", excludeFileURL.asPath]
        }
        args += [baseURL.asPath]
        let output = try Shell.run("rclone", args)

        var kept: Set<FileURL> = filesOnly ? [] : [baseURL]
        for line in output.split(separator: "\n") {
            let relativePath = String(line).reversingRcloneControlPictures
            kept.insert(FileURL(url: baseURL.asURL.appendingPathComponent(relativePath)))
        }
        return kept
    }
}
