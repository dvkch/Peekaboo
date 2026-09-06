//
//  AppError.swift
//  peekaboo
//
//  Created by syan on 03/09/2026.
//

import Foundation

enum AppError {
    case configNotFound(URL)
    case configMalformed(Error)
    case commandFailed(command: String, status: Int32, stderr: String)
    case overlappingBaseURLs(FileURL, FileURL)
    case invalidLocationURLNotDirectory(FileURL)
    case timeMachineMisconfiguration
}

extension AppError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .configNotFound(let configURL): return "Configuration file not found at \(configURL.path(percentEncoded: false))"
        case .configMalformed(let error): return "Invalid configuration: \(error)"
        case .commandFailed(_, let status, let stderr): return "Command failed (\(status)): \(stderr)"
        case .overlappingBaseURLs(let a, let b): return "Overlapping exclusion file base URLs: \"\(a.asPath)\" and \"\(b.asPath)\". Each pair's tools only see their own base URL, so overlapping scopes would let one pair's writes be undone by another's diff."
        case .invalidLocationURLNotDirectory(let url): return "Invalid location: '\(url.asPath)' is not a directory."
        case .timeMachineMisconfiguration: return "TimeMachine configuration file is missing or malformed."
        }
    }
}
