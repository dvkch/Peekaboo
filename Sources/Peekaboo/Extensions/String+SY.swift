//
//  String+SY.swift
//  peekaboo
//
//  Created by syan on 06/09/2026.
//

import Foundation

extension String {
    /// rclone substitutes Unicode "Control Picture" characters
    /// (U+2400–U+241F) for real C0 control bytes (0x00–0x1F) in any path
    /// it outputs — confirmed against carriage return, tab, and bell,
    /// each shifted by exactly +0x2400. Reversing it here is what makes
    /// a path read back from rclone's output match the real on-disk
    /// filename byte-for-byte again.
    var reversingRcloneControlPictures: String {
        String(String.UnicodeScalarView(unicodeScalars.map { scalar in
            (0x2400...0x2420).contains(scalar.value) ? UnicodeScalar(scalar.value - 0x2400)! : scalar
        }))
    }
    
    func leftPadded(toLength: Int, withPad: String = " ") -> String {
        guard count < toLength else { return self }
        return String(repeating: withPad, count: toLength - count) + self
    }
}
