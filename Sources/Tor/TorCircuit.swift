//
//  TorCircuit.swift
//  Tor
//
//  Created by Wolf McNally on 12/28/21.
//

import Foundation
import WolfBase

public class TorCircuit: Codable {
    /// Extracts all circuit info from a string which should be the response to a "GETINFO circuit-status".
    /// See https://torproject.gitlab.io/torspec/control-spec.html#getinfo
    public static func circuits(from lines: String) -> [TorCircuit] {
        lines.components(separatedBy: "\r\n").compactMap(TorCircuit.init)
    }
    
    /// The raw data this object is constructed from.
    public let raw: String
    
    /// The circuit ID. Currently only numbers beginning with "1" but Tor spec says, that could change.
    public let circuitID: String?
    
    /// The circuit status.
    public let status: Status?
    
    /// The circuit path as a list of `TorNode` objects.
    public let nodes: [TorNode]
    
    /// Build flags of the circuit.
    public let buildFlags: Set<BuildFlag>
    
    /// Purpose of the circuit.
    public let purpose: Purpose?
    
    /// Circuit hidden service state.
    public let hsState: HSState?
    
    /// The rendevouz query. Should be equal the onion address this circuit was used for minus the `.onion` postfix.
    public let rendQuery: String?
    
    /// The circuit's timestamp at which the circuit was created or cannibalized.
    public let timeCreated: Date?
    
    /// The `reason` field is provided only for `FAILED` and `CLOSED`  events, and only if extended events are enabled.
    public let reason: Reason?
    
    /// The `remoteReason` field is provided only when we receive a `DESTROY` or `TRUNCATE` cell, and only if extended events are enabled. It contains the actual reason given by the remote OR for closing the circuit.
    public let remoteReason: Reason?
    
    /// The `socksUsername` and `socksPassword` fields indicate the credentials that were used by a SOCKS client to connect to Tor’s SOCKS port and initiate this circuit.
    public let socksUsername: String?

    /// The `socksUsername` and `socksPassword` fields indicate the credentials that were used by a SOCKS client to connect to Tor’s SOCKS port and initiate this circuit.
    public let socksPassword: String?
    
    public init?(_ circuitString: String) {
        guard !circuitString.isEmpty else {
            return nil
        }
        self.raw = circuitString

        let nsRange = NSRange(circuitString.startIndex..<circuitString.endIndex, in: circuitString)
        let matches = NSRegularExpression.mainInfo.matches(in: circuitString, options: [], range: nsRange)

        func extract(at index: Int) -> String? {
            guard let firstMatch = matches.first else {
                return nil
            }
            let firstMatchRange = firstMatch.range(at: index)
            guard firstMatchRange.location != NSNotFound else {
                return nil
            }
            return String(circuitString[Range(firstMatchRange, in: circuitString)!])
        }
        
        circuitID = extract(at: 1)
        status = Status(rawValue: extract(at: 2) ?? "")
        
        self.nodes = (extract(at: 3) ?? "").components(separatedBy: ",").compactMap {
            TorNode(longName: $0.trim())
        }
        
        buildFlags = Set(
            (Option.buildFlags.regex
                .extractFirstMatch(in: circuitString, index: 1) ?? "")
                .components(separatedBy: ",")
                .compactMap({ BuildFlag(rawValue: $0) })
            )
        
        purpose = Purpose(rawValue: Option.purpose.regex.extractFirstMatch(in: circuitString, index: 1) ?? "")
        
        hsState = HSState(rawValue: Option.hsState.regex.extractFirstMatch(in: circuitString, index: 1) ?? "")
        
        rendQuery = Option.rendQuery.regex.extractFirstMatch(in: circuitString, index: 1)
        
        timeCreated = Self.timestampFormatter.date(from: Option.timeCreated.regex.extractFirstMatch(in: circuitString, index: 1) ?? "")
        
        reason = Reason(rawValue: Option.reason.regex.extractFirstMatch(in: circuitString, index: 1) ?? "")

        remoteReason = Reason(rawValue: Option.remoteReason.regex.extractFirstMatch(in: circuitString, index: 1) ?? "")
        
        socksUsername = Option.socksUsername.regex.extractFirstMatch(in: circuitString, index: 1)?.trimmingCharacters(in: .doubleQuote)
        
        socksPassword = Option.socksPassword.regex.extractFirstMatch(in: circuitString, index: 1)?.trimmingCharacters(in: .doubleQuote)
    }
    
    public enum Option: String, CaseIterable {
        case buildFlags = "BUILD_FLAGS"
        case purpose = "PURPOSE"
        case hsState = "HS_STATE"
        case rendQuery = "REND_QUERY"
        case timeCreated = "TIME_CREATED"
        case reason = "REASON"
        case remoteReason = "REMOTE_REASON"
        case socksUsername = "SOCKS_USERNAME"
        case socksPassword = "SOCKS_PASSWORD"
        
        static private let regexes: [Option: NSRegularExpression] = {
            var result: [Option: NSRegularExpression] = [:]
            for option in allCases {
                result[option] = try! NSRegularExpression(pattern: "(?:\(option.rawValue)=(.+?)(?:\\s|\\Z))", options: .caseInsensitive)
            }
            return result
        }()
        
        var regex: NSRegularExpression {
            Self.regexes[self]!
        }
    }
    
    static let timestampFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSS"
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = TimeZone(identifier: "UTC")!
        return f
    }()
    
    public enum Status: String, Codable {
        case launched = "LAUNCHED"
        case built = "BUILT"
        case guardWait = "GUARD_WAIT"
        case extended = "EXTENDED"
        case failed = "FAILED"
        case closed = "CLOSED"
    }

    public enum BuildFlag: String, Codable {
        case oneHopTunnel = "ONEHOP_TUNNEL"
        case isInternal = "IS_INTERNAL"
        case needCapacity = "NEED_CAPACITY"
        case needUptime = "NEED_UPTIME"
    }

    public enum Purpose: String, Codable {
        case general = "GENERAL"
        case hsClientIntro = "HS_CLIENT_INTRO"
        case hsClientRend = "HS_CLIENT_REND"
        case hsServiceIntro = "HS_SERVICE_INTRO"
        case hsServiceRend = "HS_SERVICE_REND"
        case testing = "TESTING"
        case controller = "CONTROLLER"
        case measureTimeout = "MEASURE_TIMEOUT"
    }

    public enum HSState: String, Codable {
        case hsciConnecting = "HSCI_CONNECTING"
        case hsciIntroSent = "HSCI_INTRO_SENT"
        case hsciDone = "HSCI_DONE"
        
        case hscrConnecting = "HSCR_CONNECTING"
        case hscrEstablishedIdle = "HSCR_ESTABLISHED_IDLE"
        case hscrEstablishedWaiting = "HSCR_ESTABLISHED_WAITING"
        case hscrJoined = "HSCR_JOINED"
        
        case hssiConnecting = "HSSI_CONNECTING"
        case hssiEstablished = "HSSI_ESTABLISHED"
        
        case hssrConnecting = "HSSR_CONNECTING"
        case hssrJoined = "HSSR_JOINED"
    }

    public enum Reason: String, Codable {
        case `none` = "NONE"
        case torProtocol = "TORPROTOCOL"
        case `internal` = "INTERNAL"
        case requested = "REQUESTED"
        case hibernating = "HIBERNATING"
        case resourceLimit = "RESOURCELIMIT"
        case connectFailed = "CONNECTFAILED"
        case orIdentity = "OR_IDENTITY"
        case orConnClosed = "OR_CONN_CLOSED"
        case timeout = "TIMEOUT"
        case finished = "FINISHED"
        case destroyed = "DESTROYED"
        case noPath = "NOPATH"
        case noSuchService = "NOSUCHSERVICE"
        case measurementExpired = "MEASUREMENT_EXPIRED"
    }
}

extension TorCircuit: CustomStringConvertible {
    public var description: String {
        self.jsonString
    }
}

extension TorCircuit: Equatable {
    public static func ==(lhs: TorCircuit, rhs: TorCircuit) -> Bool {
        return lhs.nodes == rhs.nodes
    }
}
