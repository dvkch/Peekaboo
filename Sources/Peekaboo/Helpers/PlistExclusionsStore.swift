//
//  PlistStore.swift
//  peekaboo
//
//  Created by syan on 07/09/2026.
//

import Foundation

/// Reads and writes one array-of-paths key inside a plist, leaving every
/// other key in that plist untouched. TimeMachine's SkipPaths and
/// Spotlight's Exclusions both boil down to exactly this same operation —
/// only the plist's location and the array's key name actually differ.
struct PlistExclusionsStore {
    let plistURL: FileURL
    let arrayKey: String
    let toolName: String
    let requiresRootToRead: Bool
    var relativeTo: FileURL? = nil

    private func readPlistMap() throws -> [String: Any] {
        let plistData = if requiresRootToRead {
            try Shell.runCapturingData("sudo", ["cat", plistURL.asPath])
        } else {
            try Data(contentsOf: plistURL.asURL)
        }
        let plistContent = try PropertyListSerialization.propertyList(from: plistData, options: [], format: nil)
        guard let plistMap = plistContent as? [String: Any] else { throw AppError.plistMisconfiguration(toolName) }
        return plistMap
    }
    
    func read() throws(AppError) -> [FileURL] {
        do {
            guard let values = try readPlistMap()[arrayKey] else { return [] } // key can legitimately be missing
            guard let valuesArray = values as? [String] else { throw AppError.plistMisconfiguration(toolName) }
            return valuesArray.map { string in
                guard let relativeTo else { return FileURL(path: string) }
                let cleaned = string.hasPrefix("/") ? String(string.dropFirst()) : string
                return FileURL(url: relativeTo.asURL.appendingPathComponent(cleaned))
            }
        }
        catch {
            Log.e(toolName, "Unable to read plist: \(error.localizedDescription)")
            throw .plistMisconfiguration(toolName)
        }
    }

    func write(_ paths: Set<FileURL>) throws(AppError) {
        do {
            var plistMap = try readPlistMap()
            let stringValues: [String]
            if let relativeTo {
                let prefix = relativeTo.asPath.hasSuffix("/") ? String(relativeTo.asPath.dropLast()) : relativeTo.asPath
                stringValues = paths.map { url -> String in
                    let full = url.asPath
                    guard full.hasPrefix(prefix) else { return full } // shouldn't happen; safety fallback
                    return String(full.dropFirst(prefix.count))
                }.sorted()
            } else {
                stringValues = paths.map(\.asPath).sorted()
            }
            plistMap[arrayKey] = stringValues
            let data = try PropertyListSerialization.data(fromPropertyList: plistMap, format: .binary, options: 0)
            try Shell.runWithInput(data, "sudo", ["tee", plistURL.asPath])
        }
        catch {
            Log.e(toolName, "Unable to update plist: \(error.localizedDescription)")
            throw .plistMisconfiguration(toolName)
        }
    }
}
