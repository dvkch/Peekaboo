//
//  Log.swift
//  peekaboo
//
//  Created by syan on 05/09/2026.
//

import Foundation
import ArgumentParser

struct Log {
    enum Level: String, CaseIterable, ExpressibleByArgument {
        case debug   = "debug"
        case info    = "info"
        case warning = "warning"
        case error   = "error"
        
        fileprivate var intLevel: Int {
            switch self {
            case .debug:   return 0
            case .info:    return 1
            case .warning: return 2
            case .error:   return 3
            }
        }
        
        fileprivate var title: String {
            return rawValue.first!.uppercased()
        }
    }

    static var level: Level = .info
    
    static func log(_ level: Level, tag: String, _ message: String) {
        guard level.intLevel >= Log.level.intLevel else { return }
        print("[\(level.title)] \(tag): \(message)")
    }
    
    static func d(_ tag: String, _ message: String) {
        log(.debug, tag: tag, message)
    }
    
    static func i(_ tag: String, _ message: String) {
        log(.info, tag: tag, message)
    }
    
    static func w(_ tag: String, _ message: String) {
        log(.warning, tag: tag, message)
    }
    
    static func e(_ tag: String, _ message: String) {
        log(.error, tag: tag, message)
    }
}
