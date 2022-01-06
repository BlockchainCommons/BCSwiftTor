//
//  StringUtils.swift
//  Tor
//
//  Created by Wolf McNally on 12/28/21.
//

import Foundation

extension StringProtocol {
    var isOnlyDigits: Bool {
        rangeOfCharacter(from: .notADigit) == nil
    }
}
