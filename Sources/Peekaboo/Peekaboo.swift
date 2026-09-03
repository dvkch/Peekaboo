//
//  Peekaboo.swift
//  peekaboo
//
//  Created by syan on 03/09/2026.
//

import ArgumentParser

@main
struct Peekaboo: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "peekaboo",
        abstract: "Keeps Finder tags and Time Machine exclusions in sync with rclone exclude patterns files.",
        subcommands: [
            CommandSync.self,
            CommandCleanup.self
        ]
    )
}
