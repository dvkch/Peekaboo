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
}

extension AppError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .configNotFound(let configURL): return "Configuration file not found at \(configURL.path())"
        case .configMalformed(let error): return "Invalidation configuration: \(error)"
        case .commandFailed(let command, let status, let stderr): return "\(command) failed (\(status)): \(stderr)"
        }
    }
}
