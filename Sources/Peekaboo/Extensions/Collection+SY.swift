//
//  Collection+SY.swift
//  peekaboo
//
//  Created by syan on 05/09/2026.
//

import Foundation

extension Array where Element: Equatable {
    enum UpdateResult {
        case added, removed, alreadyPresent, alreadyAbsent
    }

    mutating func setElement(_ element: Element, present: Bool) -> UpdateResult {
        if present {
            if contains(element) {
                return .alreadyPresent
            }
            append(element)
            return .added
        }
        else {
            if !contains(element) {
                return .alreadyAbsent
            }
            removeAll(where: { $0 == element })
            return .removed
        }
    }
}
