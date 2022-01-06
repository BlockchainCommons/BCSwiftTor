//
//  RegularExpressionExtensions.swift
//  Tor
//
//  Created by Wolf McNally on 12/27/21.
//

import Foundation

extension NSRegularExpression {
    /// Regular expression to identify and extract a valid IPv6 address.
    /// See: https://nbviewer.jupyter.org/github/rasbt/python_reference/blob/master/tutorials/useful_regex.ipynb
    static let ipv4 = try! NSRegularExpression(pattern: "(?:(?:25[0-5]|2[0-4]\\d|[01]?\\d\\d?)\\.){3}(?:25[0-5]|2[0-4]\\d|[01]?\\d\\d?)", options: [])
    
    /// See: https://nbviewer.jupyter.org/github/rasbt/python_reference/blob/master/tutorials/useful_regex.ipynb
    static let ipv6 = try! NSRegularExpression(pattern: "((([\\da-f]{1,4}:){7}([\\da-f]{1,4}|:))|(([\\da-f]{1,4}:){6}(:[\\da-f]{1,4}|((25[0-5]|2[0-4]\\d|1\\d\\d|[1-9]?\\d)(\\.(25[0-5]|2[0-4]\\d|1\\d\\d|[1-9]?\\d)){3})|:))|(([\\da-f]{1,4}:){5}(((:[\\da-f]{1,4}){1,2})|:((25[0-5]|2[0-4]\\d|1\\d\\d|[1-9]?\\d)(\\.(25[0-5]|2[0-4]\\d|1\\d\\d|[1-9]?\\d)){3})|:))|(([\\da-f]{1,4}:){4}(((:[\\da-f]{1,4}){1,3})|((:[\\da-f]{1,4})?:((25[0-5]|2[0-4]\\d|1\\d\\d|[1-9]?\\d)(\\.(25[0-5]|2[0-4]\\d|1\\d\\d|[1-9]?\\d)){3}))|:))|(([\\da-f]{1,4}:){3}(((:[\\da-f]{1,4}){1,4})|((:[\\da-f]{1,4}){0,2}:((25[0-5]|2[0-4]\\d|1\\d\\d|[1-9]?\\d)(\\.(25[0-5]|2[0-4]\\d|1\\d\\d|[1-9]?\\d)){3}))|:))|(([\\da-f]{1,4}:){2}(((:[\\da-f]{1,4}){1,5})|((:[\\da-f]{1,4}){0,3}:((25[0-5]|2[0-4]\\d|1\\d\\d|[1-9]?\\d)(\\.(25[0-5]|2[0-4]\\d|1\\d\\d|[1-9]?\\d)){3}))|:))|(([\\da-f]{1,4}:){1}(((:[\\da-f]{1,4}){1,6})|((:[\\da-f]{1,4}){0,4}:((25[0-5]|2[0-4]\\d|1\\d\\d|[1-9]?\\d)(\\.(25[0-5]|2[0-4]\\d|1\\d\\d|[1-9]?\\d)){3}))|:))|(:(((:[\\da-f]{1,4}){1,7})|((:[\\da-f]{1,4}){0,5}:((25[0-5]|2[0-4]\\d|1\\d\\d|[1-9]?\\d)(\\.(25[0-5]|2[0-4]\\d|1\\d\\d|[1-9]?\\d)){3}))|:)))(%.+)?", options: [.caseInsensitive])
    
    /// Regular expression to identify and extract ID, status and circuit path consisting of "LongNames".
    ///
    /// Syntax of node "LongNames": https://torproject.gitlab.io/torspec/control-spec.html#general-use-tokens
    static let mainInfo = try! NSRegularExpression(pattern: "(\\w+)\\s+(LAUNCHED|BUILT|GUARD_WAIT|EXTENDED|FAILED|CLOSED)\\s+((?:\\$[\\da-f]+[=~]\\w+(?:,|\\s|\\Z))+)?", options: [.caseInsensitive])
    
    func extractFirstMatch(in string: String, index: Int = 0) -> String? {
        let nsRange = NSRange(string.startIndex..<string.endIndex, in: string)
        let myMatches = matches(in: string, options: [], range: nsRange)
        guard
            let firstMatch = myMatches.first,
                firstMatch.numberOfRanges > 0,
            let range = Range(firstMatch.range(at: index), in: string)
        else {
            return nil
        }
        return String(string[range])
    }
}
