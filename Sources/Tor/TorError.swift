//
//  TorError.swift
//  Tor
//
//  Created by Wolf McNally on 12/29/21.
//

import Foundation

public enum TorError: Error {
    case channelAlreadyExists
    case invalidParameter
    case noConnection
    case internalError
    case posixError(Int32)
    case serverError(code: TorReplyCode, message: String)
    case circuitNotEstablished
    case noSession
}

extension TorError: CustomStringConvertible {
    public var description: String {
        switch self {
        case .channelAlreadyExists:
            return "Channel already exists."
        case .invalidParameter:
            return "Invalid parameter."
        case .noConnection:
            return "No connection to Tor server."
        case .internalError:
            return "Internal error."
        case .posixError(let code):
            return "POSIX error \(code)."
        case .serverError(let code, let message):
            return "\(code) \(message)"
        case .circuitNotEstablished:
            return "Circuit not established."
        case .noSession:
            return "No URL session available."
        }
    }
}
