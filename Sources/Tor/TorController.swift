//
//  TorController.swift
//  Tor
//
//  Created by Wolf McNally on 12/28/21.
//

import Foundation
import WolfBase

// https://github.com/torproject/torspec/blob/main/control-spec.txt
// https://raw.githubusercontent.com/torproject/torspec/d3165c9ae0d346288ccb94fbfb831d2686f7abf3/control-spec.txt


public protocol TorObserver {
    var id: UUID { get }
    
    func performCallback(codes: [TorReplyCode], lines: [Data], stop: inout Bool) -> Bool
}

public struct TorCallbackObserver : TorObserver {
    public typealias Callback = (_ codes: [TorReplyCode], _ lines: [Data], _ stop: inout Bool) -> Bool

    public let id: UUID
    public let callback: Callback
    
    public init(callback: @escaping Callback) {
        self.id = UUID()
        self.callback = callback
    }
    
    public func performCallback(codes: [TorReplyCode], lines: [Data], stop: inout Bool) -> Bool {
        callback(codes, lines, &stop)
    }
}

public struct TorContinuationObserver : TorObserver {
    public typealias Callback = (_ continuation: CheckedContinuation<Any, Error>, _ codes: [TorReplyCode], _ lines: [Data], _ stop: inout Bool) -> Bool

    public let id: UUID
    public let continuation: CheckedContinuation<Any, Error>
    public let callback: Callback
    
    public init(continuation: CheckedContinuation<Any, Error>, callback: @escaping Callback) {
        self.id = UUID()
        self.continuation = continuation
        self.callback = callback
    }
    
    public func performCallback(codes: [TorReplyCode], lines: [Data], stop: inout Bool) -> Bool {
        callback(continuation, codes, lines, &stop)
    }
}

public class TorController {
    public typealias StatusEventObserver = (_ type: String, _ severity: String, _ action: String, _ arguments: [String: String]) -> Bool
    public typealias CircuitEstablishedObserver = (_ established: Bool) -> Void
    
    public enum ConnectionType {
        case socket(url: URL)
        case host((host: String, port: UInt16))
    }
    
    private var observers: [TorObserver] = []
    private var connectionType: ConnectionType
    private var channel: DispatchIO!
    private var socketFD: Int32?
    private var _events: Set<String> = []
    private static let controlQueue = DispatchQueue(label: "com.blockchaincommons.tor.control")
    
    private static let crlf = "\r\n"
    private static let crlfData = crlf.utf8Data
    private static let period = "."
    private static let periodData = period.utf8Data
    private static let dataTerminator = crlf + period + crlf
    private static let dataTerminatorData = dataTerminator.utf8Data
    private static let midReplyLineSeparator = "-"
    private static let dataReplyLineSeparator = "+"
    private static let dataReplyLineSeparatorData = dataReplyLineSeparator.utf8Data
    private static let endReplyLineSeparator = " "
    private static let lineSeparators = Set([midReplyLineSeparator, dataReplyLineSeparator, endReplyLineSeparator])

    public init(connectionType: ConnectionType) async throws {
        self.connectionType = connectionType
        try await connect()
    }
    
    deinit {
        if let channel = channel {
            channel.close(flags: .stop)
        }
    }
    
    public convenience init(socket: URL) async throws {
        try await self.init(connectionType: .socket(url: socket))
    }
    
    public convenience init(host: String, port: UInt16) async throws {
        try await self.init(connectionType: .host((host, port)))
    }
    
    public func connect() async throws {
        guard channel == nil else {
            throw TorError.channelAlreadyExists
        }
        
        socketFD = nil
        _events = []
        
        switch connectionType {
        case .socket(let url):
            var controlAddr = sockaddr_un()
            let socketLength = MemoryLayout.size(ofValue: controlAddr)
            let maxPathLength = MemoryLayout.size(ofValue: controlAddr.sun_path) - 1
            
            let path = url.path
            let pathLength = strlen(path)
            if pathLength > maxPathLength {
                throw TorError.invalidParameter
            }
            
            controlAddr.sun_family = sa_family_t(AF_UNIX)
            controlAddr.sun_len = UInt8(socketLength)
            withUnsafeMutablePointer(to: &controlAddr.sun_path) {
                $0.withMemoryRebound(to: CChar.self, capacity: maxPathLength) {
                    _ = strncpy($0, path, pathLength)
                }
            }
            socketFD = socket(AF_UNIX, SOCK_STREAM, 0)
            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                guard withUnsafePointer(to: controlAddr, {
                    $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                        Darwin.connect(socketFD!, $0, socklen_t(socketLength))
                    }
                }) != -1 else {
                    continuation.resume(throwing: TorError.posixError(errno))
                    return
                }
                continuation.resume()
            }
        case .host(let (host, port)):
            var addr = in_addr()
            guard host.withCString({
                inet_aton($0, &addr)
            }) != 0 else {
                throw TorError.posixError(errno)
            }
            
            var controlAddr = sockaddr_in()
            let socketLength = MemoryLayout.size(ofValue: controlAddr)
            controlAddr.sin_family = sa_family_t(AF_INET)
            controlAddr.sin_port = port.bigEndian
            controlAddr.sin_addr = addr
            controlAddr.sin_len = UInt8(socketLength)
            socketFD = socket(AF_INET, SOCK_STREAM, IPPROTO_TCP)
            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                guard withUnsafePointer(to: controlAddr, {
                    $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                        Darwin.connect(socketFD!, $0, socklen_t(socketLength))
                    }
                }) != -1 else {
                    continuation.resume(throwing: TorError.posixError(errno))
                    return
                }
                continuation.resume()
            }
        }
        
        channel = DispatchIO(
            type: .stream,
            fileDescriptor: socketFD!,
            queue: Self.controlQueue,
            cleanupHandler: { [weak self] error in
                if let self = self {
                    close(self.socketFD!)
                    self.channel = nil
                }
            }
        )
        
        var buffer = Data()
        var lines = [Data]()
        var codes = [TorReplyCode]()
        var dataBlock = false
        
        channel.setLimit(lowWater: 1)
        channel.read(offset: 0, length: Int.max, queue: Self.controlQueue) { [weak self] done, data, error in
            if done, error != noErr {
                print("⛔️ Reading: \(TorError.posixError(error))")
                return
            }
            guard
                let self = self,
                let data = data
            else {
                print("⛔️ Reading: \(TorError.internalError)")
                return
            }
            buffer.append(contentsOf: data)
            while let separatorRange = buffer.range(of: Self.crlfData) {
                let lineLength = separatorRange.startIndex - buffer.startIndex
                let lineRange = buffer.startIndex ..< separatorRange.startIndex
                let remainingRange = buffer.startIndex + lineLength + Self.crlfData.count ..< buffer.endIndex
                let lineData = buffer[lineRange]
                
                buffer = Data(buffer[remainingRange])

                if dataBlock {
                    if lineData == Self.periodData {
                        dataBlock = false
                    } else {
                        if let lastData = lines.last {
                            var lastData = lastData
                            if !lastData.isEmpty {
                                lastData.append(Self.crlfData)
                            }
                            lastData.append(lineData)
                            lines[lines.endIndex - 1] = lastData
                        } else {
                            lines.append(lineData)
                        }
                    }
                    
                    continue
                }
                
                guard lineData.count >= 4 else {
                    continue
                }
                
                let statusCodeString = String(data: lineData[0..<3], encoding: .utf8)!
                guard statusCodeString.isOnlyDigits else {
                    continue
                }
                
                let lineTypeString = String(data: lineData[3..<4], encoding: .utf8)!
                guard Self.lineSeparators.contains(lineTypeString) else {
                    continue
                }
                
                if let statusCode = Int(statusCodeString) {
                    codes.append(TorReplyCode(rawValue: statusCode))
                }
                
                lines.append(lineData[4 ..< lineData.endIndex])
                
                if lineTypeString == Self.dataReplyLineSeparator {
                    dataBlock = true
                } else if lineTypeString == Self.endReplyLineSeparator {
                    let commandCodes = codes
                    let commandLines = lines
                    
                    codes = []
                    lines = []
                    
                    var stoppedObserverIndexes: [Int] = []
                    
                    for (index, observer) in self.observers.enumerated() {
                        var stop = false
                        let handled = observer.performCallback(codes: commandCodes, lines: commandLines, stop: &stop)
                        if stop {
                            stoppedObserverIndexes.append(index)
                        }
                        if handled {
                            break
                        }
                    }
                    stoppedObserverIndexes.reversed().forEach {
                        self.observers.remove(at: $0)
                    }
                }
            }
        }
    }
    
    func sendCommand(_ command: TorCommand, arguments: [String]? = nil, data: Data = Data(), observer: TorContinuationObserver) {
        guard let channel = channel else {
            observer.continuation.resume(throwing: TorError.noConnection)
            return
        }
        
        let argumentsString = ([command.rawValue] + (arguments ?? [])).joined(separator: " ")
        
        //print("❤️ \(argumentsString)")
        
        var commandData = Data()
        if !data.isEmpty {
            commandData += Self.dataReplyLineSeparatorData
        }
        commandData.append(argumentsString.utf8Data)
        commandData.append(Self.crlfData)
        if !data.isEmpty {
            commandData.append(data)
            commandData.append(Self.dataTerminatorData)
        }
        
        commandData.withUnsafeBytes {
            let dispatchData = DispatchData(bytes: $0)
            channel.write(offset: 0, data: dispatchData, queue: Self.controlQueue) { done, data, error in
                if done {
                    guard error == noErr else {
                        observer.continuation.resume(throwing: TorError.posixError(error))
                        return
                    }
                    self.observers.append(observer)
                }
            }
        }
    }
    
    func sendSimpleCommand(_ command: TorCommand, arguments: [String] = []) async throws {
        _ = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Any, Error>) in
            sendCommand(command, arguments: arguments, observer: observeResult(continuation: continuation) { continuation in
                continuation.resume(returning: ())
            })
        }
    }

    public func disconnect() async throws {
        _ = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Any, Error>) in
            sendCommand(.signalShutdown, observer: TorContinuationObserver(continuation: continuation) { continuation, _, _, _ in
                if let socketFD = self.socketFD {
                    Darwin.shutdown(socketFD, SHUT_RDWR)
                }
                self.channel = nil
                continuation.resume(returning: ())
                return true
            })
        }
    }
    
    func observeResult(expectedFailureCodes: Set<TorReplyCode> = [], continuation: CheckedContinuation<Any, Error>, action: @escaping (CheckedContinuation<Any, Error>) -> Void) -> TorContinuationObserver {
        TorContinuationObserver(continuation: continuation)
        { continuation, codes, lines, stop in
            guard
                let code = codes.first,
                let message = lines.first?.utf8
            else {
                return false
            }
            
            guard code == .ok || expectedFailureCodes.contains(code)
            else {
                return false
            }
            
            guard code == .ok && message == "OK" else {
                continuation.resume(throwing: TorError.serverError(code: code, message: message))
                return true
            }
            
            action(continuation)
            
            stop = true
            return true
        }
    }

    public func authenticate(with data: Data) async throws {
        _ = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Any, Error>) in
            sendCommand(.authenticate, arguments: [data.hex], observer: observeResult(expectedFailureCodes: [.badAuthentication], continuation: continuation) { continuation in
                continuation.resume(returning: ())
            })
        }
    }
    
    public func resetConfigurations(_ configs: [(String, String?)]) async throws {
        _ = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Any, Error>) in
            func f(_ s: String?) -> String {
                s == nil ? "" : "=" + s!
            }
            let arguments = configs.map { $0.0 + f($0.1) }
            sendCommand(.resetConf, arguments: arguments, observer: observeResult(expectedFailureCodes: [.badAuthentication], continuation: continuation) { continuation in
                continuation.resume(returning: ())
            })
        }
    }
    
    public func resetConfigurations(_ configs: [String]) async throws {
        try await resetConfigurations(configs.map { ($0, nil) })
    }
    
    public func setConfigurations(_ configs: [String: String]) async throws {
        _ = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Any, Error>) in
            let arguments = configs.map { "\($0.key)=\($0.value)" }
            sendCommand(.setConf, arguments: arguments, observer: observeResult(expectedFailureCodes: [.badAuthentication], continuation: continuation) { continuation in
                continuation.resume(returning: ())
            })
        }
    }
    
    var events: Set<String> {
        get async {
            await withCheckedContinuation { continuation in
                Self.controlQueue.async {
                    continuation.resume(returning: self._events)
                }
            }
        }
    }
    
    public func listen(for events: Set<String>) async throws {
        _ = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Any, Error>) in
            sendCommand(.setEvents, arguments: Array(events), observer: observeResult(expectedFailureCodes: [.unrecognizedEntity], continuation: continuation, action: { continuation in
                self._events = events
                continuation.resume(returning: ())
            }))
        }
    }
    
    public func getInfo(for key: String) async throws -> String? {
        return try await getInfo(for: [key])[key]
    }
    
    public func expectInfo(for key: String) async throws -> String {
        guard let value = try await getInfo(for: key) else {
            throw TorError.internalError
        }
        return value
    }
    
    public func getInfo(for keys: [String]) async throws -> [String: String] {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Any, Error>) in
            sendCommand(.getInfo, arguments: keys, observer: TorContinuationObserver(continuation: continuation) { continuation, codes, lines, stop in
                stop = true
                
                guard lines.count - 1 == keys.count else {
                    continuation.resume(returning: [:])
                    return false
                }
                
                var strings: [String] = []
                for line in lines {
                    guard let string = line.utf8 else {
                        continuation.resume(returning: [:])
                        return false
                    }
                    strings.append(string)
                }
                
                guard codes.last == .ok && strings.last == "OK" else {
                    continuation.resume(returning: [:])
                    return false
                }
                
                var info: [String: String] = [:]
                
                for idx in 0 ..< (strings.count - 1) {
                    guard codes[idx] == .ok else {
                        continue
                    }
                    
                    var components = strings[idx].split(separator: "=")
                    
                    if components.count > 1 {
                        let key = components.first!.trimmingCharacters(in: .doubleQuote)
                        components.removeFirst()
                        let value = components.joined(separator: "=").trimmingCharacters(in: .doubleQuote)
                        if keys.contains(key) {
                            info[key] = value
                        } else {
                            continuation.resume(returning: [:])
                            return false
                        }
                    }
                }
                
                let values: [String: String] = keys.reduce(into: [:], { $0[$1] = info[$1] })
                continuation.resume(returning: values)
                return true
            })
        } as! [String: String]
    }
    
    public func getSessionConfiguration() async throws -> URLSessionConfiguration {
        guard let value = try await getInfo(for: "net/listeners/socks") else {
            throw TorError.noSession
        }
        let components = value.split(separator: ":")
        guard components.count == 2 else {
            throw TorError.noSession
        }
        let h = components[0]
        guard h != "unix" else {
            throw TorError.noSession
        }
        // Replace 127.0.0.1 with localhost, as without this, there's a strange bug
        // triggered: It won't resolve .onion addresses, but *only on real devices*.
        // So, on a real device, there's probably the wrong DNS resolver used, which
        // would mean, DNS queries were leaking, too.
        let host = h == "127.0.0.1" ? "localhost" : h

        guard let port = UInt16(components[1]) else {
            throw TorError.noSession
        }

        let configuration = URLSessionConfiguration.default
        configuration.connectionProxyDictionary = [
            kCFProxyTypeKey: kCFProxyTypeSOCKS,
            kCFStreamPropertySOCKSProxyHost: host,
            kCFStreamPropertySOCKSProxyPort: port
        ]
        return configuration
    }
    
    /// Get a list of all currently available circuits with detailed information about their nodes.
    ///
    /// There's no clear way to determine, which circuit actually was used by a specific request.
    /// Returns an empty list if no circuit could be found.
    public func getCircuits() async throws -> [TorCircuit] {
        let circuitStatus = try await expectInfo(for: "circuit-status")
        let circuits = TorCircuit.circuits(from: circuitStatus)
        
        let ip4Available = try await getInfo(for: "ip-to-country/ipv4-available") == "1"
        let ip6Available = try await getInfo(for: "ip-to-country/ipv6-available") == "1"
        
        for circuit in circuits {
            for node in circuit.nodes {
                let value = try await expectInfo(for: "ns/id/\(node.fingerprint)")
                node.acquireIPAddresses(from: value)

                if ip4Available, let address = node.ipv4Address {
                    node.countryCode = try await getInfo(for: "ip-to-country/\(address)")
                } else if ip6Available, let address = node.ipv6Address {
                    node.countryCode = try await getInfo(for: "ip-to-country/\(address)")
                }
            }
        }
        
        return circuits
    }
    
    /// Resets the Tor connection: Sends "SIGNAL RELOAD" and "SIGNAL NEWNYM" to the Tor thread.
    ///
    /// See https://torproject.gitlab.io/torspec/control-spec.html#signal
    ///
    public func resetConnection() async throws {
        try await sendSimpleCommand(.signalReload)
        try await sendSimpleCommand(.signalNewnym)
    }
    
    /// Try to close a circuits identified by its ID.
    ///
    /// - Returns: `true` if the ID was successfully closed, or `false` if it was not, usually because it no longer exists.
    public func closeCircuit(id: String) async throws -> Bool {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Any, Error>) in
            sendCommand(.closeCircuit, arguments: [id], observer: TorContinuationObserver(continuation: continuation) { continuation, codes, lines, stop in
                stop = true
                continuation.resume(returning: codes.first == .ok)
                return true
            })
        } as! Bool
    }

    /// Try to close the circuit.
    ///
    /// - Returns: `true` if the circuit was successfully closed, or `false` if it was not, usually because it no longer exists.
    public func closeCircuit(_ circuit: TorCircuit) async throws -> Bool {
        guard let circuitID = circuit.circuitID else {
            return false
        }
        return try await closeCircuit(id: circuitID)
    }

    /// Try to close a list of circuits identified by their IDs.
    ///
    /// - Returns: A list of successfullly closed circuits.
    public func closeCircuits(ids: [String]) async throws -> [String] {
        try await ids.asyncFilter {
            try await closeCircuit(id: $0)
        }
    }
    
    /// Try to close a list of given circuits.
    ///
    /// The given circuits are invalid afterwards, as you just closed them. You should throw them away on completion.
    ///
    /// - Returns: A list of the successfully closed circuits.
    public func closeCircuits(_ circuits: [TorCircuit]) async throws -> [TorCircuit] {
        try await circuits.asyncFilter {
            try await closeCircuit($0)
        }
    }
    
    public func untilCircuitEstablished(timeout: TimeInterval = 40, sleepInterval: TimeInterval = 2) async throws {
        var elapsedTime: TimeInterval = 0
        var established = false
        while !established && elapsedTime < timeout {
            established = try await isCircuitEstablished()
            if established {
                break
            }
            try await Task.sleep(seconds: sleepInterval)
            elapsedTime += sleepInterval
        }
        guard established else {
            throw TorError.circuitNotEstablished
        }
    }
    
    public func isCircuitEstablished() async throws -> Bool {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Any, Error>) in
            let event = "STATUS_CLIENT"
            
            let observerID = addStatusEventObserver { type, severity, action, arguments in
                guard type == event else {
                    return false
                }

                switch action {
                case "CIRCUIT_ESTABLISHED", "CIRCUIT_NOT_ESTABLISHED":
                    return true
                default:
                    return false
                }
            }
            
            Task {
                do {
                    var events = await events
                    if !events.contains(event) {
                        events.insert(event)
                        try await listen(for: events)
                    }
                    let value = try await getInfo(for: "status/circuit-established")
                    removeObserver(id: observerID)
                    continuation.resume(returning: value == "1")
                } catch {
                    removeObserver(id: observerID)
                    continuation.resume(throwing: error)
                }
            }
        } as! Bool
    }
    
    public func addStatusEventObserver(_ callback: @escaping (_ type: String, _ severity: String, _ action: String, _ arguments: [String : String]) -> Bool) -> UUID {
        addObserver(TorCallbackObserver { codes, lines, stop in
            guard
                codes.first == .asynchronousEventNotification,
                let replyString = lines.first?.utf8,
                replyString.hasPrefix("STATUS_")
            else {
                return false
            }
            
            let components = replyString.split(separator: " ").map { String($0) }
            guard components.count >= 3 else {
                return false
            }
            
            var arguments: [String: String] = [:]
            if components.count > 3 {
                for argument in components[3 ..< components.count] {
                    let keyValuePair = argument.split(separator: "=")
                    guard keyValuePair.count == 2 else {
                        continue
                    }
                    arguments[String(keyValuePair[0])] = String(keyValuePair[1])
                }
            }
            
            return callback(components[0], components[1], components[2], arguments)
        })
    }

    @discardableResult
    public func addObserver(_ observer: TorObserver) -> UUID {
        Self.controlQueue.sync {
            self.observers.append(observer)
            return observer.id
        }
    }
    
    public func removeObserver(id: UUID) {
        Self.controlQueue.sync {
            if let index = self.observers.firstIndex(where: {$0.id == id}) {
                self.observers.remove(at: index)
            }
        }
    }
}
