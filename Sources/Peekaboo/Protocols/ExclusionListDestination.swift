//
//  ExclusionListDestination.swift
//  peekaboo
//
//  Created by syan on 03/09/2026.
//

import Foundation

protocol ExclusionListDestination: ExclusionListTool {
    var markingURLsRequiresRoot: Bool { get }
    func markURLs(_ urls: [FileURL], excluded: Bool) throws
}
