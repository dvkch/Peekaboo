//
//  ExclusionListSource.swift
//  peekaboo
//
//  Created by syan on 03/09/2026.
//

import Foundation

protocol ExclusionListSource: ExclusionListTool {
    func excludedURLs() throws -> [FileURL]
    func filterURLsExcludedByDefault(_ urls: [FileURL]) -> [FileURL]
}

