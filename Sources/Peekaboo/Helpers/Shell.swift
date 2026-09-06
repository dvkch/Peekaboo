//
//  Shell.swift
//  peekaboo
//
//  Created by syan on 03/09/2026.
//

import Foundation

enum Shell {
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
        
        var stdoutData = Data()
        var stderrData = Data()
        let group = DispatchGroup()
        
        group.enter()
        DispatchQueue.global().async {
            stdoutData = stdoutPipe.fileHandleForReading.readDataToEndOfFile()
            group.leave()
        }
        group.enter()
        DispatchQueue.global().async {
            stderrData = stderrPipe.fileHandleForReading.readDataToEndOfFile()
            group.leave()
        }
        
        try process.run()
        group.wait()
        process.waitUntilExit()
        
        guard process.terminationStatus == 0 else {
            throw AppError.commandFailed(
                command: ([command] + arguments).joined(separator: " "),
                status: process.terminationStatus,
                stderr: String(data: stderrData, encoding: .utf8) ?? ""
            )
        }
        
        return String(data: stdoutData, encoding: .utf8) ?? ""
    }
    
    /// Primes sudo's credential cache, prompting interactively if
    /// needed. Tests non-interactively first (`sudo -nv`) — if a cached
    /// credential is still valid, returns immediately with no prompt.
    ///
    /// Process alone can't make sudo's password prompt work correctly:
    /// the child process isn't automatically the terminal's foreground
    /// process group, and sudo needs that to do its own low-level
    /// terminal control (disabling echo). tcsetpgrp hands it over
    /// explicitly. Terminal control is handed back to our own process
    /// group afterward — without that, later output could end up
    /// running "in the background," a known rough edge of this
    /// technique per the source this is adapted from.
    static func askForSudo(message: String) throws {
        let test = Process()
        test.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        test.arguments = ["sudo", "-nv"]
        test.standardOutput = FileHandle.nullDevice
        test.standardError = FileHandle.nullDevice
        try test.run()
        test.waitUntilExit()
        
        if test.terminationStatus == 0 {
            return
        }
        
        print(message)
        
        let ourProcessGroup = getpgrp()
        defer {
            // Reclaiming the terminal here would normally suspend us via
            // SIGTTOU, since by this point we're no longer its foreground
            // process group — sudo is. Ignoring the signal just for this
            // one call is the standard way to reclaim it safely afterward.
            let previousHandler = signal(SIGTTOU, SIG_IGN)
            tcsetpgrp(STDIN_FILENO, ourProcessGroup)
            signal(SIGTTOU, previousHandler)
        }
        
        let sudo = Process()
        sudo.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        sudo.arguments = ["sudo", "-v"]
        try sudo.run()
        
        guard tcsetpgrp(STDIN_FILENO, sudo.processIdentifier) != -1 else {
            throw AppError.commandFailed(command: "sudo -v", status: -1, stderr: "tcsetpgrp failed")
        }
        
        sudo.waitUntilExit()
        
        guard sudo.terminationStatus == 0 else {
            throw AppError.commandFailed(command: "sudo -v", status: sudo.terminationStatus, stderr: "")
        }
    }
}
