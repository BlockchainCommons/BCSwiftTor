//
//  TorSeverity.swift
//  Tor
//
//  Created by Wolf McNally on 12/28/21.
//

import Foundation
import os
import WolfBase

public enum TorSeverity {
    case debug
    case info
    case notice
    case warning
    case error
    case unknown(Int32)
}

extension TorSeverity: CustomStringConvertible {
    public var description: String {
        switch self {
        case .debug:
            return "debug"
        case .info:
            return "info"
        case .notice:
            return "notice"
        case .warning:
            return "warning"
        case .error:
            return "error"
        case .unknown(let severity):
            return "unknown(\(severity))"
        }
    }
}

extension TorSeverity {
    public static func fromOSLogType(_ type: OSLogType) -> TorSeverity {
        switch type {
        case .debug:
            return .debug
        case .info:
            return .info
        case .`default`:
            return .notice
        case .fault:
            return .warning
        case .error:
            return .error
        default:
            return .unknown(Int32(type.rawValue))
        }
    }
    
    public var osLogType: OSLogType {
        switch self {
        case .debug:
            return .debug
        case .notice, .info:
            return .info
        case .warning:
            return .error
        case .error:
            return .fault
        case .unknown:
            return .`default`
        }
    }
}

extension TorSeverity {
    public static func fromLogPriority(_ priority: Int32) -> TorSeverity {
        switch priority {
        case LOG_DEBUG:
            return .debug
        case LOG_INFO:
            return .info
        case LOG_NOTICE:
            return .notice
        case LOG_WARNING:
            return .warning
        case LOG_ERR:
            return .error
        default:
            return .unknown(priority)
        }
    }
    
    public var logPriority: Int32 {
        switch self {
        case .debug:
            return LOG_DEBUG
        case .info:
            return LOG_INFO
        case .notice:
            return LOG_NOTICE
        case .warning:
            return LOG_WARNING
        case .error:
            return LOG_ERR
        case .unknown(let priority):
            return priority
        }
    }
}

extension TorSeverity {
    public static func fromEventLogSeverity(_ severity: Int32) -> TorSeverity {
        switch UInt32(bitPattern: severity) {
        case TorUtils.EVENT_LOG_DEBUG:
            return .debug
        case TorUtils.EVENT_LOG_MSG:
            return .info
        case TorUtils.EVENT_LOG_WARN:
            return .warning
        case TorUtils.EVENT_LOG_ERR:
            return .error
        default:
            return .unknown(severity)
        }
    }
    
    public var eventLogSeverity: UInt32 {
        switch self {
        case .debug, .unknown:
            return TorUtils.EVENT_LOG_DEBUG
        case .info, .notice:
            return TorUtils.EVENT_LOG_MSG
        case .warning:
            return TorUtils.EVENT_LOG_WARN
        case .error:
            return TorUtils.EVENT_LOG_ERR
        }
    }
}
