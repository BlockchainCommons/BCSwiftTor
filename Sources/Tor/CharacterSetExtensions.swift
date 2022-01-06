//
//  CharacterSetExtensions.swift
//  Tor
//
//  Created by Wolf McNally on 12/27/21.
//

import Foundation

extension CharacterSet {
    static let doubleQuote = CharacterSet(charactersIn: "\"")
    static let longNameDivider = CharacterSet(charactersIn: "~=")
    static let notADigit = CharacterSet.decimalDigits.inverted
}
