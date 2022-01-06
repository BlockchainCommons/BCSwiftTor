//
//  AsyncSequenceExtensions.swift
//  Tor
//
//  Created by Wolf McNally on 1/3/22.
//

import Foundation

// https://www.swiftbysundell.com/articles/async-and-concurrent-forEach-and-map/

extension Sequence {
    func asyncMap<T>(
        _ transform: (Element) async throws -> T
    ) async rethrows -> [T] {
        var values = [T]()

        for element in self {
            try await values.append(transform(element))
        }

        return values
    }
    
    func asyncFilter(
        _ isIncluded: (Element) async throws -> Bool
    ) async rethrows -> [Element] {
        var values = [Element]()
        
        for element in self {
            if try await isIncluded(element) {
                values.append(element)
            }
        }
        
        return values
    }
}
