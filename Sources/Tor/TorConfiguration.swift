//
//  TorConfiguration.swift
//  Tor
//
//  Created by Wolf McNally on 12/27/21.
//

import Foundation
import CryptoKit

public struct TorConfiguration {
    public struct Options: OptionSet {
        public let rawValue: Int
        
        public init(rawValue: Int) {
            self.rawValue = rawValue
        }
        
        public static let ignoreMissingTorrc = Options(rawValue: 1 << 0)
        public static let cookieAuthentication = Options(rawValue: 1 << 1)
        public static let autoControlPort = Options(rawValue: 1 << 2)
        public static let avoidDiskWrites = Options(rawValue: 1 << 3)
        public static let clientOnly = Options(rawValue: 1 << 4)
    }
    
    public let dataDirectory: URL
    public let controlPortFile: URL
    public let lockFile: URL
    public let cookieFile: URL
    public let controlSocket: URL
    public let hiddenServiceDirectory: URL?
    public let serviceAuthDirectory: URL?
    public let socksURL: URL?
    public let clientAuthDirectory: URL?
    public let geoipFile: URL?
    public let geoip6File: URL?
    public let options: Options
    
    public let arguments: [String]

    public init(dataDirectory: URL, controlSocket: URL, hiddenServiceDirectory: URL? = nil, socksURL: URL? = nil, clientAuthDirectory: URL? = nil, geoipFile: URL? = nil, geoip6File: URL? = nil, options: Options = [], additionalOptions: [String: String]? = nil) {
        self.dataDirectory = checkFileURL(dataDirectory)!
        self.controlPortFile = dataDirectory.appendingPathComponent("controlPort")
        self.lockFile = dataDirectory.appendingPathComponent("lock")
        self.cookieFile = dataDirectory.appendingPathComponent("control_auth_cookie")
        self.controlSocket = checkFileURL(controlSocket)!
        self.hiddenServiceDirectory = checkFileURL(hiddenServiceDirectory)
        if let hiddenServiceDirectory = hiddenServiceDirectory {
            self.serviceAuthDirectory = hiddenServiceDirectory.appendingPathComponent("authorized_clients")
        } else {
            self.serviceAuthDirectory = nil
        }
        self.socksURL = checkFileURL(socksURL)
        self.clientAuthDirectory = checkFileURL(clientAuthDirectory)
        self.geoipFile = checkFileURL(geoipFile)
        self.geoip6File = checkFileURL(geoip6File)
        self.options = options
        
        var arguments = ["tor"]
        
        arguments.append(contentsOf: ["--DataDirectory", dataDirectory.path])

        arguments.append(contentsOf: ["--ControlSocket", controlSocket.path])

        arguments.append(contentsOf: ["--ControlPort", "auto", "--ControlPortWriteToFile", controlPortFile.path])

        if options.contains(.ignoreMissingTorrc) {
            arguments.append(contentsOf: ["--allow-missing-torrc", "--ignore-missing-torrc"])
        }
        
        if options.contains(.avoidDiskWrites) {
            arguments.append(contentsOf: ["--AvoidDiskWrites", "1"])
        }
        
        if options.contains(.clientOnly) {
            arguments.append(contentsOf: ["--ClientOnly", "1"])
        }
                
        if options.contains(.cookieAuthentication) {
            arguments.append(contentsOf: ["--CookieAuthentication", "1"])
        }
                        
        if let socksURL = socksURL {
            arguments.append(contentsOf: ["--SocksPort", "unix:\(socksURL.path)"])
        }
        
        if let clientAuthDirectory = clientAuthDirectory {
            arguments.append(contentsOf: ["--ClientOnionAuthDir", clientAuthDirectory.path])
        }
        
        if let hiddenServiceDirectory = hiddenServiceDirectory {
            arguments.append(contentsOf: ["--HiddenServiceDir", hiddenServiceDirectory.path])
        }
        
        if let geoipFile = geoipFile {
            arguments.append(contentsOf: ["--GeoIPFile", geoipFile.path])
        }
        
        if let geoip6File = geoip6File {
            arguments.append(contentsOf: ["--GeoIPv6File", geoip6File.path])
        }
        
        if let additionalOptions = additionalOptions {
            for (key, value) in additionalOptions.sorted(by: { $0.0 < $1.0 }) {
                arguments.append(contentsOf: ["--\(key)", value])
            }
        }

        self.arguments = arguments
    }
    
    public var isLocked: Bool {
        return FileManager.default.fileExists(atPath: lockFile.path)
    }
    
    public var cookie: Data? {
        return try? Data(contentsOf: cookieFile)
    }
}
