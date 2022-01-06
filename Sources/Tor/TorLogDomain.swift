//
//  TorLogDomain.swift
//  Tor
//
//  Created by Wolf McNally on 1/4/22.
//

import Foundation
import WolfBase
import os

public struct TorLogDomain: Enumeration {
    public let rawValue: UInt64
    
    public init(rawValue: UInt64) {
        self.rawValue = rawValue
    }
}

extension TorLogDomain {
    /// Catch-all for miscellaneous events and fatal errors.
    public static let general = Self(rawValue: 1 << 0)
    
    /// The cryptography subsystem.
    public static let crypto = Self(rawValue: 1 << 1)
    
    /// Networking.
    public static let net = Self(rawValue: 1 << 2)
    
    /// Parsing and acting on our configuration.
    public static let config = Self(rawValue: 1 << 3)
    
    /// Reading and writing from the filesystem.
    public static let fs = Self(rawValue: 1 << 4)
    
    /// Other servers' (non)compliance with the Tor protocol.
    public static let `protocol` = Self(rawValue: 1 << 5)
    
    /// Memory management.
    public static let mm = Self(rawValue: 1 << 6)
    
    /// HTTP implementation.
    public static let http = Self(rawValue: 1 << 7)
    
    /// Application (socks) requests.
    public static let app = Self(rawValue: 1 << 8)
    
    /// Communication via the controller protocol.
    public static let control = Self(rawValue: 1 << 9)
    
    /// Building, using, and managing circuits.
    public static let circ = Self(rawValue: 1 << 10)
    
    /// Hidden services.
    public static let rend = Self(rawValue: 1 << 11)
    
    /// Internal errors in this Tor process.
    public static let bug = Self(rawValue: 1 << 12)
    
    /// Learning and using information about Tor servers.
    public static let dir = Self(rawValue: 1 << 13)
    
    /// Learning and using information about Tor servers.
    public static let dirserv = Self(rawValue: 1 << 14)
    
    /// Onion routing protocol.
    public static let or = Self(rawValue: 1 << 15)
    
    /// Generic edge-connection functionality.
    public static let edge = Self(rawValue: 1 << 16)
    public static let exit = edge
    
    /// Bandwidth accounting.
    public static let acct = Self(rawValue: 1 << 17)
    
    /// Router history
    public static let hist = Self(rawValue: 1 << 18)
    
    /// OR handshaking
    public static let handshake = Self(rawValue: 1 << 19)
    
    /// Heartbeat messages
    public static let heartbeat = Self(rawValue: 1 << 20)
    
    /// Abstract channel_t code
    public static let channel = Self(rawValue: 1 << 21)
    
    /// Scheduler
    public static let sched = Self(rawValue: 1 << 22)
    
    /// Guard nodes
    public static let `guard` = Self(rawValue: 1 << 23)
    
    /// Generation and application of consensus diffs.
    public static let consdiff = Self(rawValue: 1 << 24)
    
    /// Denial of Service mitigation.
    public static let dos = Self(rawValue: 1 << 25)
    
    /// Processes
    public static let process = Self(rawValue: 1 << 26)
    
    /// Pluggable Transports.
    public static let pt = Self(rawValue: 1 << 27)
    
    /// Bootstrap tracker.
    public static let btrack = Self(rawValue: 1 << 28)
    
    /// Message-passing backend.
    public static let mesg = Self(rawValue: 1 << 29)
    
    /// This log message is not safe to send to a callback-based logger immediately.  Used as a flag, not a log domain.
    public static let nocb = Self(rawValue: 1 << 62)
}

extension TorLogDomain {
    public var category: String {
        switch(self) {
        case .general: return "general"
        case .crypto: return "crypto"
        case .net: return "net"
        case .config: return "config"
        case .fs: return "fs"
        case .`protocol`: return "protocol"
        case .mm: return "mm"
        case .http: return "http"
        case .app: return "app"
        case .control: return "control"
        case .circ: return "circ"
        case .rend: return "rend"
        case .bug: return "bug"
        case .dir: return "dir"
        case .dirserv: return "dirserv"
        case .or: return "or"
        case .edge: return "edge"
        case .acct: return "acct"
        case .hist: return "hist"
        case .handshake: return "handshake"
        case .heartbeat: return "heartbeat"
        case .channel: return "channel"
        case .sched: return "sched"
        case .`guard`: return "guard"
        case .consdiff: return "consdiff"
        case .dos: return "dos"
        case .process: return "process"
        case .pt: return "pt"
        case .btrack: return "btrack"
        case .mesg: return "mesg"
        default: return "unknown"
        }
    }
}

extension TorLogDomain: CustomStringConvertible {
    public var description: String {
        category
    }
}

extension TorLogDomain {
    private static var logs: [Self: Logger] = [:]
    
    var logger: Logger {
        if Self.logs[self] == nil {
            Self.logs[self] = Logger(subsystem: logSubsystem, category: category)
        }
        return Self.logs[self]!
    }
}
