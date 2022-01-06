//
//  TorControllerTests.swift
//  TorTests
//
//  Created by Wolf McNally on 1/3/22.
//

import Foundation
import XCTest
import Tor

class TorControllerTests: XCTestCase {
    var controller: TorController!

    static let configuration: TorConfiguration = {
        var homeDirectory: URL!
        #if targetEnvironment(simulator)
        for variable in ["IPHONE_SIMULATOR_HOST_HOME", "SIMULATOR_HOST_HOME"] {
            if let p = getenv(variable) {
                homeDirectory = URL(fileURLWithPath: String(cString: p))
                break
            }
        }
        #else
        homeDirectory = URL(fileURLWithPath: NSHomeDirectory())
        #endif
        precondition(homeDirectory != nil)
        
        let fileManager = FileManager.default
        
        let dataDirectory = fileManager.temporaryDirectory
        let socketDirectory = homeDirectory.appendingPathComponent(".tor")
        try! fileManager.createDirectory(at: socketDirectory, withIntermediateDirectories: true)
        let socketFile = socketDirectory.appendingPathComponent("control_port")

        return TorConfiguration(
            dataDirectory: dataDirectory,
            controlSocket: socketFile,
            options: [.ignoreMissingTorrc, .cookieAuthentication]
        )
    }()
    
    static override func setUp() {
        super.setUp()
        
        let runner = TorRunner(configuration: Self.configuration)
        runner.setLogging { severity, domain, msg in
            print("🔵 [\(severity)]: \(domain): \(msg)")
        }
        runner.setEventLogging { severity, msg in
            print("🟩 [\(severity)]: \(msg)")
        }
        runner.run()
    }
    
    override func setUp() async throws {
        try await super.setUp()
        
        controller = try await TorController(socket: Self.configuration.controlSocket)
    }
    
    func testCookieAuthenticationFailure() async throws {
        do {
            try await controller.authenticate(with: "invalid".utf8Data)
            XCTFail("Authentication should have failed, but succeeded.")
        } catch(let error as TorError) {
            if case let .serverError(code, message) = error {
                XCTAssertEqual(code, .badAuthentication)
                XCTAssertEqual(message, "Authentication failed: Wrong length on authentication cookie." )
            } else {
                XCTFail("Received wrong error: \(error)")
            }
        }
    }
    
    func authenticate() async throws {
        guard let cookie = Self.configuration.cookie else {
            XCTFail("No cookie file found.")
            return
        }
        try await controller.authenticate(with: cookie)
    }
    
    func testCookieAuthenticationSuccess() async throws {
        try await authenticate()
    }
    
    func testAwaitCircuitEstablished() async throws {
        try await authenticate()
        try await controller.untilCircuitEstablished()
    }
    
    func testSessionConfiguration() async throws {
        try await authenticate()
        try await controller.untilCircuitEstablished()
        let sessionConfiguration = try await controller.getSessionConfiguration()
        let session = URLSession(configuration: sessionConfiguration)
        
        // Blockchain Commons SpotBit instance.
        // https://github.com/blockchaincommons/spotbit#test-server
        let url = URL(string: "http://h6zwwkcivy2hjys6xpinlnz2f74dsmvltzsd4xb42vinhlcaoe7fdeqd.onion/status")!
        let (data, resp) = try await session.data(from: url)
        let response = resp as! HTTPURLResponse
        XCTAssertEqual(response.statusCode, 200)
        XCTAssertEqual(data.utf8, "server is running")
    }
    
    func testGetAndCloseCircuits() async throws {
        try await authenticate()
        try await controller.untilCircuitEstablished()
        let circuits = try await controller.getCircuits()
        XCTAssertTrue(!circuits.isEmpty)
        for circuit in circuits {
            for node in circuit.nodes {
                XCTAssertTrue(!node.fingerprint.isEmpty)
                XCTAssert(node.ipv4Address != nil || node.ipv6Address != nil)
            }
        }
        _ = try await controller.closeCircuits(circuits)
    }
    
    func testReset() async throws {
        try await authenticate()
        try await controller.untilCircuitEstablished()
        try await controller.resetConnection()
    }
}
