//
//  ExclusionListDestination.swift
//  peekaboo
//
//  Created by syan on 03/09/2026.
//

import Foundation

protocol ExclusionListDestination: ExclusionListTool {
    func exclude(urls: [FileURL]) throws
    func include(urls: [FileURL]) throws
}
