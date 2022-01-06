//
//  TaskExtensions.swift
//  Tor
//
//  Created by Wolf McNally on 1/3/22.
//

import Foundation

func toNanoseconds(seconds: TimeInterval) -> UInt64 {
    precondition(seconds >= 0)
    return UInt64(seconds * 1_000_000_000)
}

extension Task where Failure == Never, Success == Never {
    static func sleep(seconds: TimeInterval) async throws {
        try await Task.sleep(nanoseconds: toNanoseconds(seconds: seconds))
    }
}
