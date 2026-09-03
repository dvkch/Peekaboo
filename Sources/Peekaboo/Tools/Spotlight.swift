//
//  Spotlight.swift
//  peekaboo
//
//  Created by syan on 03/09/2026.
//

import Foundation

struct Spotlight: ExclusionListTool {

    // MARK: Init
    init(baseURL: FileURL) {
        self.baseURL = baseURL
    }

    // MARK: Properties
    let baseURL: FileURL

    var name: String { "Spotlight" }

    private static let sentinelFileName = ".metadata_never_index"
}

// Cannot be implemented as a Source or a Destination. The exclusion list is defined per volume
// in a protected plist that would require restarting the spotlight deamon after any edit.
// - .metadata_never_index doesnt work anymore
// - kMDItemDisableSearchInSpotlight seems only to control visibility in results, not if the item is indexed at all, and applies only to an item, not its descendants
