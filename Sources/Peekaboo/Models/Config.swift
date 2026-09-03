//
//  Config.swift
//  peekaboo
//
//  Created by syan on 03/09/2026.
//

import Foundation

struct Config: Decodable {
    
    // MARK: Paths
    static let configPath = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(".config/peekaboo.json")

    // MARK: Init
    static func readConfig() throws(AppError) -> Config {
        guard let configData = try? Data(contentsOf: configPath) else {
            throw .configNotFound(configPath)
        }

        let config: Config
        do {
            config = try JSONDecoder().decode(Config.self, from: configData)
        } catch {
            throw .configMalformed(error)
        }

        try config.validateNonOverlappingBaseURLs()
        return config
    }

    // MARK: Structs
    struct Location: Decodable {
        let path: FileURL
        let exclusionFiles: [FileURL]
        
        enum CodingKeys: String, CodingKey {
            case path = "path"
            case exclusionFiles = "exclusion_files"
        }
        
        init(from decoder: any Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)

            let pathString = try container.decode(String.self, forKey: .path)
            let exclusionFilesStrings = try container.decode([String].self, forKey: .exclusionFiles)

            self.path = FileURL(path: pathString)
            self.exclusionFiles = exclusionFilesStrings.map { FileURL(path: $0) }
        }
    }
    
    struct FinderTag: Decodable {
        let enabled: Bool
        let name: String
        
        enum CodingKeys: String, CodingKey {
            case enabled = "enabled"
            case name = "name"
        }
    }
    
    struct TimeMachine: Decodable {
        let enabled: Bool

        enum CodingKeys: String, CodingKey {
            case enabled = "enabled"
        }
    }
    
    // MARK: Properties
    let locations: [Location]
    let finderTag: FinderTag
    let timeMachine: TimeMachine
    
    enum CodingKeys: String, CodingKey {
        case locations = "locations"
        case finderTag = "finder_tag"
        case timeMachine = "time_machine"
    }
}

extension Config {
    /// Ensures no two exclusion files' base URLs are nested inside each
    /// other (or identical). Each pair's tools only see their own base
    /// URL's slice of the world — if two pairs' base URLs overlapped, one
    /// pair's writes could be silently undone by the other pair's diff on
    /// the very next run.
    func validateNonOverlappingBaseURLs() throws(AppError) {
        let locations = self.locations.map { $0.path }
        
        for i in locations.indices {
            for j in locations.indices where j != i {
                let a = locations[i]
                let b = locations[j]
                if a == b || a.asPath.hasPrefix(b.asPath + "/") {
                    throw .overlappingBaseURLs(a, b)
                }
            }
        }
    }
}
