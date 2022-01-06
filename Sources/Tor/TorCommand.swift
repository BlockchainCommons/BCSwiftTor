//
//  TorCommand.swift
//  Tor
//
//  Created by Wolf McNally on 1/4/22.
//

import Foundation
import WolfBase

public struct TorCommand: Enumeration {
    public let rawValue: String
    
    public init(rawValue: String) {
        self.rawValue = rawValue
    }
}

extension TorCommand {
    public static let authenticate      = TorCommand(rawValue: "AUTHENTICATE")
    public static let signalShutdown    = TorCommand(rawValue: "SIGNAL SHUTDOWN")
    public static let resetConf         = TorCommand(rawValue: "RESETCONF")
    public static let setConf           = TorCommand(rawValue: "SETCONF")
    public static let setEvents         = TorCommand(rawValue: "SETEVENTS")
    public static let getInfo           = TorCommand(rawValue: "GETINFO")
    public static let signalReload      = TorCommand(rawValue: "SIGNAL RELOAD")
    public static let signalNewnym      = TorCommand(rawValue: "SIGNAL NEWNYM")
    public static let closeCircuit      = TorCommand(rawValue: "CLOSECIRCUIT")
}
