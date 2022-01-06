//
//  TorReplyCode.swift
//  Tor
//
//  Created by Wolf McNally on 1/3/22.
//

import Foundation
import WolfBase

public struct TorReplyCode: Enumeration {
    public let rawValue: Int
    
    public init(rawValue: Int) {
        self.rawValue = rawValue
    }
}

extension TorReplyCode {
    public static let ok                               = TorReplyCode(rawValue: 250)
    public static let operationWasUnnecessary          = TorReplyCode(rawValue: 251)
    public static let resourceExhaused                 = TorReplyCode(rawValue: 451)
    public static let syntaxErrorProtocol              = TorReplyCode(rawValue: 500)
    public static let unrecognizedCommand              = TorReplyCode(rawValue: 510)
    public static let unimplementedCommand             = TorReplyCode(rawValue: 511)
    public static let syntaxErrorInCommandArgument     = TorReplyCode(rawValue: 512)
    public static let unrecognizedCommandArgument      = TorReplyCode(rawValue: 513)
    public static let authenticationRequired           = TorReplyCode(rawValue: 514)
    public static let badAuthentication                = TorReplyCode(rawValue: 515)
    public static let unspecifiedTorError              = TorReplyCode(rawValue: 550)
    public static let internalError                    = TorReplyCode(rawValue: 551)
    public static let unrecognizedEntity               = TorReplyCode(rawValue: 552)
    public static let invalidConfigurationValue        = TorReplyCode(rawValue: 553)
    public static let invalidDescriptor                = TorReplyCode(rawValue: 554)
    public static let unmanagedEntity                  = TorReplyCode(rawValue: 555)
    public static let asynchronousEventNotification    = TorReplyCode(rawValue: 650)
}
