//
//  TorNode.swift
//  Tor
//
//  Created by Wolf McNally on 12/27/21.
//

import Foundation

public class TorNode: Codable {
    /// The fingerprint aka. ID of a Tor node.
    public var fingerprint: String
    
    /// The nickname of a Tor node.
    public var nickName: String?
    
    /// The IPv4 address of a Tor node.
    public var ipv4Address: String?
    
    /// The IPv6 address of a Tor node.
    public var ipv6Address: String?
    
    /// The country code of a Tor node's country.
    public var countryCode: String?
    
    /// The localized country name of a Tor node's country.
    public func localizedCountryName(for locale: Locale = Locale.current) -> String? {
        guard let countryCode = countryCode else {
            return nil
        }
        return locale.localizedString(forRegionCode: countryCode)
    }
    
    /// Create a `TORNode` object from a "LongName" node string which should contain the fingerprint and the nickname.
    ///
    /// - Parameter longname: A "LongName" identifying a Tor node.
    ///
    /// - SeeAlso: [Tor Spec](https://torproject.gitlab.io/torspec/control-spec.html#general-use-tokens)
    public init?(longName: String) {
        let components = longName.components(separatedBy: .longNameDivider)
        guard !components.isEmpty else {
            return nil
        }
        self.fingerprint = components[0]
        guard !self.fingerprint.isEmpty else {
            return nil
        }
        if components.count > 1 {
            if !components[1].isEmpty {
                self.nickName = components[1]
            }
        }
    }
    
    /// Acquires IPv4 and IPv6 addresses from the given string.
    ///
    /// - Parameter response: Should be the response of a `ns/id/<fingerprint>` call.
    ///
    /// - SeeAlso: [Tor Spec](https://torproject.gitlab.io/torspec/control-spec.html#getinfo)
    public func acquireIPAddresses(from response: String) {
        self.ipv4Address = NSRegularExpression.ipv4.extractFirstMatch(in: response)
        self.ipv6Address = NSRegularExpression.ipv6.extractFirstMatch(in: response)
    }
}

extension TorNode: Hashable {
    public static func ==(lhs: TorNode, rhs: TorNode) -> Bool {
        lhs.fingerprint == rhs.fingerprint
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(fingerprint)
    }
}

extension TorNode: CustomStringConvertible {
    public var description: String {
        self.jsonString
    }
}
