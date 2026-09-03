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
    static func readConfig() throws -> Config? {
        guard let configData = try? Data(contentsOf: configPath) else {
            return nil
        }

        return try JSONDecoder().decode(Config.self, from: configData)
    }
    
    // MARK: Structs
    struct ExclusionFile: Decodable {
        let path: URL
        let relativeTo: URL
        
        enum CodingKeys: String, CodingKey {
            case path = "path"
            case relativeTo = "relative_to"
        }
        
        init(from decoder: any Decoder) throws {
            let container: KeyedDecodingContainer<Config.ExclusionFile.CodingKeys> = try decoder.container(keyedBy: Config.ExclusionFile.CodingKeys.self)

            let pathString = try container.decode(String.self, forKey: Config.ExclusionFile.CodingKeys.path)
            let relativeToString = try container.decode(String.self, forKey: Config.ExclusionFile.CodingKeys.relativeTo)

            self.path = URL(fileURLWithPath: (pathString as NSString).expandingTildeInPath).standardizedFileURL
            self.relativeTo = URL(fileURLWithPath: (relativeToString as NSString).expandingTildeInPath).standardizedFileURL
        }
    }
    
    struct FinderTag: Decodable {
        let enabled: Bool
        let name: String
    }
    
    struct TimeMachine: Decodable {
        let enabled: Bool
    }
    
    // MARK: Properties
    let exclusionFiles: [ExclusionFile]
    let finderTag: FinderTag
    let timeMachine: TimeMachine
}
