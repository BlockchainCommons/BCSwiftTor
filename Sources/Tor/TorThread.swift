//
//  TorThread.swift
//  Tor
//
//  Created by Wolf McNally on 12/27/21.
//

import Foundation
import TorBase

public typealias TorUtils = TorBase.TorUtils

public class TorThread: Thread {
    public private(set) static var activeThread: TorThread?
    public let arguments: [String]
    
    public init(arguments: [String]) {
        precondition(Self.activeThread == nil, "There can only be one TorThread per process.")
        self.arguments = arguments
        super.init()
        self.name = "Tor"
        Self.activeThread = self
    }
    
    public convenience init(configuration: TorConfiguration) {
        self.init(arguments: configuration.arguments)
    }
    
    public override func main() {
        print("❤️ Starting Tor Thread. Arguments: \(arguments)")
        
//        TorLogging.installTorLogging { severity, domain, msg in
//            print("👍🏼 [\(severity)]: \(domain): \(msg)")
//        }
//
//        TorLogging.installEventLogging { severity, msg in
//            print("🎉 \(descriptionForOSLogType(severity)): \(msg)")
//        }
        
        TorUtils.runTorMain(arguments: arguments)
    }
}

