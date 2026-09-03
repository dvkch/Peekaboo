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

        do {
            return try JSONDecoder().decode(Config.self, from: configData)
        }
        catch {
            throw .configMalformed(error)
        }
    }
    
    // MARK: Structs
    struct ExclusionFile: Decodable {
        let path: FileURL
        let relativeTo: FileURL
        
        enum CodingKeys: String, CodingKey {
            case path = "path"
            case relativeTo = "relative_to"
        }
        
        init(from decoder: any Decoder) throws {
            let container: KeyedDecodingContainer<Config.ExclusionFile.CodingKeys> = try decoder.container(keyedBy: Config.ExclusionFile.CodingKeys.self)

            let pathString = try container.decode(String.self, forKey: Config.ExclusionFile.CodingKeys.path)
            let relativeToString = try container.decode(String.self, forKey: Config.ExclusionFile.CodingKeys.relativeTo)

            self.path = FileURL(path: pathString)
            self.relativeTo = FileURL(path: relativeToString)
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
    let exclusionFiles: [ExclusionFile]
    let finderTag: FinderTag
    let timeMachine: TimeMachine
    
    enum CodingKeys: String, CodingKey {
        case exclusionFiles = "exclusion_files"
        case finderTag = "finder_tag"
        case timeMachine = "time_machine"
    }
}
