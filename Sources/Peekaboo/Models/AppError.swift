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
}

extension AppError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .configNotFound(let configURL): return "Configuration file not found at \(configURL.path(percentEncoded: false))"
        case .configMalformed(let error): return "Invalidation configuration: \(error)"
        case .commandFailed(let command, let status, let stderr): return "\(command) failed (\(status)): \(stderr)"
        case .overlappingBaseURLs(let a, let b): return "Overlapping exclusion file base URLs: \"\(a.asPath)\" and \"\(b.asPath)\". Each pair's tools only see their own base URL, so overlapping scopes would let one pair's writes be undone by another's diff."
        }
    }
}
