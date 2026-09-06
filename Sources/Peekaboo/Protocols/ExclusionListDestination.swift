//
//  ExclusionListDestination.swift
//  peekaboo
//
//  Created by syan on 03/09/2026.
//

import Foundation

protocol ExclusionListDestination: ExclusionListTool {
    func markURLs(_ urls: [FileURL], excluded: Bool) throws
    var markingURLsRequiresRoot: Bool { get }
}
