//
//  URLExtensions.swift
//  Tor
//
//  Created by Wolf McNally on 1/3/22.
//

import Foundation

func checkFileURL(_ url: URL?) -> URL? {
    guard let url = url else {
        return nil
    }
    precondition(url.isFileURL)
    return url
}
