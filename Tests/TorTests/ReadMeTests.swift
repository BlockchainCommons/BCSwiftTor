//
//  File.swift
//  
//
//  Created by Wolf McNally on 1/6/22.
//

import Foundation
import XCTest
import Tor

//class ReadMeTests: XCTestCase {
//    var controller: TorController!
//
//    // Configure the controller. Socket files have length limitations, so find a file system path
//    // that's short enough to accomodate the socket file we use to communicate with the Tor thread.
//    static let configuration: TorConfiguration = {
//        var homeDirectory: URL!
//        #if targetEnvironment(simulator)
//        for variable in ["IPHONE_SIMULATOR_HOST_HOME", "SIMULATOR_HOST_HOME"] {
//            if let p = getenv(variable) {
//                homeDirectory = URL(fileURLWithPath: String(cString: p))
//                break
//            }
//        }
//        #else
//        homeDirectory = URL(fileURLWithPath: NSHomeDirectory())
//        #endif
//        precondition(homeDirectory != nil)
//
//        let fileManager = FileManager.default
//
//        let dataDirectory = fileManager.temporaryDirectory
//        let socketDirectory = homeDirectory.appendingPathComponent(".tor")
//        try! fileManager.createDirectory(at: socketDirectory, withIntermediateDirectories: true)
//        let socketFile = socketDirectory.appendingPathComponent("control_port")
//
//        return TorConfiguration(
//            dataDirectory: dataDirectory,
//            controlSocket: socketFile,
//            options: [.ignoreMissingTorrc, .cookieAuthentication]
//        )
//    }()
//
//    // Run once for every all tests in this suite. Start the Tor thread with logging back to the app.
//    static override func setUp() {
//        super.setUp()
//
//        let runner = TorRunner(configuration: Self.configuration)
//        runner.setLogging(minLogSeverity: .notice) { severity, domain, msg in
//            print("🔵 [\(severity)]: \(domain): \(msg)")
//        }
//        runner.run()
//    }
//
//    // Run once for each test this suite. Create a new Tor controller object.
//    override func setUp() async throws {
//        try await super.setUp()
//
//        controller = try await TorController(socket: Self.configuration.controlSocket)
//    }
//
//    // Authenticate to the Tor process using the cookie that it writes to the file system.
//    func authenticate() async throws {
//        guard let cookie = Self.configuration.cookie else {
//            XCTFail("No cookie file found.")
//            return
//        }
//        try await controller.authenticate(with: cookie)
//    }
//
//    func testRetrieveURL() async throws {
//        // Authenticate and then wait until a circuit is established
//        try await authenticate()
//        try await controller.untilCircuitEstablished()
//
//        // Create a URL session that communicates using the socket that's been set up.
//        let sessionConfiguration = try await controller.getSessionConfiguration()
//        let session = URLSession(configuration: sessionConfiguration)
//
//        // Use the URLSession to retrieve data from an Onion address URL via Tor.
//
//        // Blockchain Commons SpotBit instance.
//        // https://github.com/blockchaincommons/spotbit#test-server
//        let url = URL(string: "http://h6zwwkcivy2hjys6xpinlnz2f74dsmvltzsd4xb42vinhlcaoe7fdeqd.onion/status")!
//        let (data, resp) = try await session.data(from: url)
//        let response = resp as! HTTPURLResponse
//        XCTAssertEqual(response.statusCode, 200)
//        XCTAssertEqual(data.utf8, "server is running")
//    }
//}
