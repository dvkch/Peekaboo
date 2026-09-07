//
//  Numeric+SY.swift
//  peekaboo
//
//  Created by syan on 07/09/2026.
//

import Foundation

extension Int64 {
    var formattedSize: String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        formatter.zeroPadsFractionDigits = true
        return formatter.string(fromByteCount: self)
    }
}
