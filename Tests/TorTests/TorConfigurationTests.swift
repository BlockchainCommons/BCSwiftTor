//
//  TorTests.swift
//  TorTests
//
//  Created by Wolf McNally on 12/26/21.
//

import Foundation
import XCTest
import Tor

class TorConfigurationTests: XCTestCase {
    func testVersionNumbers() throws {
        XCTAssertEqual(TorUtils.lzmaVersion, "5.2.5")
        XCTAssertEqual(TorUtils.openSSLVersion, "OpenSSL 1.1.1l  24 Aug 2021")
        XCTAssertEqual(TorUtils.libEventsVersion, "2.1.12-stable")
        XCTAssertEqual(TorUtils.torVersion, "tor 0.4.6.9-dev")
        XCTAssertEqual(TorUtils.dependencyVersions, [
            "LZMA": TorUtils.lzmaVersion,
            "OpenSSL": TorUtils.openSSLVersion,
            "LibEvent": TorUtils.libEventsVersion,
            "Tor": TorUtils.torVersion
        ])
    }
    
    func testConfiguration() {
        let config = TorConfiguration(
            dataDirectory: URL(fileURLWithPath: "/a/b"),
            controlSocket: URL(fileURLWithPath: "/c/d/"),
            socksURL: URL(fileURLWithPath: "/e/f"),
            options: [.cookieAuthentication],
            additionalOptions: ["b": "foo", "a": "bar"])
        XCTAssertEqual(config.arguments, ["tor", "--DataDirectory", "/a/b", "--ControlSocket", "/c/d", "--ControlPort", "auto", "--ControlPortWriteToFile", "/a/b/controlPort", "--CookieAuthentication", "1", "--SocksPort", "unix:/e/f", "--a", "bar", "--b", "foo"])
    }
    
    func testNode() throws {
        let node = TorNode(longName: "fingerprint~nickname")!
        node.acquireIPAddresses(from: "192.145.80.54 ::ffff:c091:5036")
        node.countryCode = "us"
        XCTAssertEqual(node.description, #"{"countryCode":"us","fingerprint":"fingerprint","ipv4Address":"192.145.80.54","ipv6Address":"::ffff:c091:5036","nickName":"nickname"}"#)
        XCTAssertEqual(node.localizedCountryName(for: Locale(identifier: "us")), "United States")
    }
    
    func testCircuits() throws {
        let circuitStatus = "\r\n1 BUILT $B56B9FE93F83B4FA69234B17A060E8A8E7446D19~Paphos,$C34D6ACA7CE7F54CFE833C378BAD8870F5A7FA80~skibidibopmmdada,$F98CE40031795D3704365019EA9F8AC56AE2994B~torproxy01 BUILD_FLAGS=NEED_CAPACITY PURPOSE=GENERAL TIME_CREATED=2022-01-04T08:59:59.764875\r\n2 BUILT $B56B9FE93F83B4FA69234B17A060E8A8E7446D19~Paphos,$312B310556ABF14377AB70F59C7B4FF9EF853699~PornHubPremium,$22F74E176F803499D4F80D9CE7D325883A8C0E45~MakeSecure BUILD_FLAGS=NEED_CAPACITY PURPOSE=GENERAL TIME_CREATED=2022-01-04T09:00:00.766274\r\n3 BUILT $B56B9FE93F83B4FA69234B17A060E8A8E7446D19~Paphos,$46A1E8E9C074D762BE896BE14C50E4B25FD5A9C9~blackbanana,$937881D3E049BB4E09FE2C742E76ED60C7B6AA3D~DFRI11 BUILD_FLAGS=IS_INTERNAL,NEED_CAPACITY,NEED_UPTIME PURPOSE=GENERAL TIME_CREATED=2022-01-04T09:00:01.768051\r\n4 EXTENDED $B56B9FE93F83B4FA69234B17A060E8A8E7446D19~Paphos BUILD_FLAGS=IS_INTERNAL,NEED_CAPACITY,NEED_UPTIME PURPOSE=GENERAL TIME_CREATED=2022-01-04T09:00:02.769850\r\n5 EXTENDED BUILD_FLAGS=IS_INTERNAL,NEED_CAPACITY,NEED_UPTIME PURPOSE=GENERAL TIME_CREATED=2022-01-04T09:00:06.219428"
        let circuits = TorCircuit.circuits(from: circuitStatus)
        
        XCTAssertEqual(circuits.count, 5)
        
        XCTAssertEqual(circuits[0].circuitID, "1")
        XCTAssertEqual(circuits[0].status, .built)
        XCTAssertEqual(circuits[0].buildFlags, [.needCapacity])
        XCTAssertEqual(circuits[0].purpose, .general)
        XCTAssertEqual(circuits[0].nodes.count, 3)
        XCTAssertEqual(circuits[0].nodes[0].fingerprint, "$B56B9FE93F83B4FA69234B17A060E8A8E7446D19")
        XCTAssertEqual(circuits[0].nodes[0].nickName, "Paphos")

        XCTAssertEqual(circuits[2].nodes.count, 3)
        XCTAssertEqual(circuits[2].nodes[1].fingerprint, "$46A1E8E9C074D762BE896BE14C50E4B25FD5A9C9")
        XCTAssertEqual(circuits[2].nodes[1].nickName, "blackbanana")

        XCTAssertEqual(circuits[3].circuitID, "4")
        XCTAssertEqual(circuits[3].status, .extended)
        XCTAssertEqual(circuits[3].buildFlags, [.isInternal, .needCapacity, .needUptime])
    }
}
