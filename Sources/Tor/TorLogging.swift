//
//  TorLogging.swift
//  Tor
//
//  Created by Wolf McNally on 12/28/21.
//

import Foundation
import os
import WolfBase

let logSubsystem = "com.blockchaincommons.Tor"

public typealias TorLogCB = (_ severity: TorSeverity, _ domain: TorLogDomain, _ msg: String) -> Void
public typealias TorLogEventCB = (_ severity: TorSeverity, _ msg: String) -> Void

var userTorLogCallback: TorLogCB?
var userEventLogCallback: TorLogEventCB?

private let eventLogger = Logger(subsystem: logSubsystem, category: "libevent")

private func torLogCallback(logPriority: Int32, domain: UInt64, msg: Optional<UnsafePointer<Int8>>) {
    guard domain & TorLogDomain.nocb.rawValue == 0 else {
        return
    }
    let severity = TorSeverity.fromLogPriority(logPriority)
    let domain = TorLogDomain(rawValue: domain)
    let msg = msg != nil ? String(cString: msg!).trim() : "nil"
    if let userTorLogCallback = userTorLogCallback {
        userTorLogCallback(severity, domain, msg)
    } else {
        let type = severity.osLogType
        domain.logger.log(level: type, "\(msg, privacy: .public)")
    }
}

private func eventLogCallback(eventLogSeverity: Int32, msg: Optional<UnsafePointer<Int8>>) {
    let severity = TorSeverity.fromEventLogSeverity(eventLogSeverity)
    let msg = msg != nil ? String(cString: msg!).trim() : "nil"
    if let userEventLogCallback = userEventLogCallback {
        userEventLogCallback(severity, msg)
    } else {
        let type = severity.osLogType
        eventLogger.log(level: type, "\(msg, privacy: .public)")
    }
}

public enum TorLogging {
    public static func installTorLogging(minSeverity: TorSeverity = .debug, maxSeverity: TorSeverity = .error, callback: TorLogCB? = nil) {
        userTorLogCallback = callback
        TorUtils.installTorLogging(minLogPriority: minSeverity.logPriority, maxLogPriority: maxSeverity.logPriority, callback: torLogCallback)
    }
    
    public static func installEventLogging(callback: TorLogEventCB? = nil) {
        userEventLogCallback = callback
        TorUtils.setEventLogCallback(eventLogCallback)
        TorUtils.setEventDebugLogging(isEnabled: true)
    }
}
