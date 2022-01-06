//
//  TorRunner.swift
//  Tor
//
//  Created by Wolf McNally on 1/5/22.
//

import Foundation

public class TorRunner {
    public let configuration: TorConfiguration
    public private(set) var minLogSeverity: TorSeverity!
    public private(set) var maxLogSeverity: TorSeverity!
    public private(set) var logCallback: TorLogCB!
    public private(set) var eventsCallback: TorLogEventCB!

    public init(configuration: TorConfiguration) {
        self.configuration = configuration
    }
    
    public func setLogging(minLogSeverity: TorSeverity = .debug, maxLogSeverity: TorSeverity = .error, callback: @escaping TorLogCB) {
        self.minLogSeverity = minLogSeverity
        self.maxLogSeverity = maxLogSeverity
        self.logCallback = callback
    }
    
    public func setEventLogging(callback: @escaping TorLogEventCB) {
        self.eventsCallback = callback
    }
    
    private var isLogging: Bool {
        return logCallback != nil
    }
    
    private var isEventLogging: Bool {
        return eventsCallback != nil
    }
    
    private func resetLogging() {
        if isLogging {
            TorLogging.installTorLogging(minSeverity: minLogSeverity, maxSeverity: maxLogSeverity, callback: logCallback)
        }

        if isEventLogging {
            TorLogging.installEventLogging(callback: eventsCallback)
        }
    }

    public func run() {
        resetLogging()

        let thread = TorThread(configuration: configuration)
        thread.start()
        RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.5))
        
        resetLogging()
    }
}
