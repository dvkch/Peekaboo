//
//  ExclusionListDestination.swift
//  peekaboo
//
//  Created by syan on 03/09/2026.
//

import Foundation

protocol ExclusionListDestination: ExclusionListTool {
    func exclude(urls: [URL]) throws
    func include(urls: [URL]) throws
}
