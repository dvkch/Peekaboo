//
//  Shell.swift
//  peekaboo
//
//  Created by syan on 03/09/2026.
//

import Foundation

enum Shell {
    enum ShellError: Error, CustomStringConvertible {
        case commandFailed(command: String, status: Int32, stderr: String)

        var description: String {
            switch self {
            case .commandFailed(let command, let status, let stderr):
                return "\(command) failed (\(status)): \(stderr)"
            }
        }
    }

    /// Runs `command` (resolved via PATH) with `arguments` and returns its
    /// stdout. Throws if the process exits non-zero.
    @discardableResult
    static func run(_ command: String, _ arguments: [String]) throws -> String {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        process.arguments = [command] + arguments

        let stdoutPipe = Pipe()
        let stderrPipe = Pipe()
        process.standardOutput = stdoutPipe
        process.standardError = stderrPipe

        try process.run()
        let stdoutData = stdoutPipe.fileHandleForReading.readDataToEndOfFile()
        let stderrData = stderrPipe.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()

        guard process.terminationStatus == 0 else {
            throw ShellError.commandFailed(
                command: ([command] + arguments).joined(separator: " "),
                status: process.terminationStatus,
                stderr: String(data: stderrData, encoding: .utf8) ?? ""
            )
        }

        return String(data: stdoutData, encoding: .utf8) ?? ""
    }
}
