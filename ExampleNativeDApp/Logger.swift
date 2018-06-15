//
//  Logger.swift
//  ExampleNativeDApp
//
//  Created by Josh Pyles on 6/14/18.
//  Copyright © 2018 Out There Labs. All rights reserved.
//

import Foundation
import Sentry

struct Logger {
    
    static func log(error: Error?, context: String?) {
        if let error = error {
            let event = Event(level: .error)
            let nsError = error as NSError
            event.message = "\(nsError.domain) \(nsError.code)"
            event.extra = [:]
            event.extra?["localizedDescription"] = error.localizedDescription
            event.extra?["debugDescription"] = nsError.debugDescription
            event.extra?["errorContext"] = context
            Client.shared?.send(event: event)
        } else if let context = context {
            let event = Event(level: .debug)
            event.message = context
            Client.shared?.send(event: event)
        }
    }
    
}
