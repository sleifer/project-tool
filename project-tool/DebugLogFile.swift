//
//  DebugLogFile.swift
//  project-tool
//
//  Created by Simeon Leifer on 7/25/18.
//  Copyright © 2018 droolingcat.com. All rights reserved.
//

import Foundation

let logPathUrl = URL(fileURLWithPath: "~/Desktop/debug.txt".expandingTildeInPath)

func debugLog(_ value: String) {
    let log = ">>> \(value)\n"
    try! log.appendToURL(fileURL: logPathUrl)
}

func debugLog(_ value: [String], multiline: Bool = true) {
    let items: String
    if multiline == true {
        items = value.map { (str) -> String in
            return "[\(str)]"
            }.joined(separator: ",\n")
    } else {
        items = value.map { (str) -> String in
            return "[\(str)]"
            }.joined(separator: ", ")
    }
    let log = ">>> \(items)\n"
    try! log.appendToURL(fileURL: logPathUrl)
}

func debugLog(_ value: [String: String], multiline: Bool = true) {
    let items: String
    if multiline == true {
        items = value.map { (key, value) -> String in
            return "[\(key)]: [\(value)]"
            }.joined(separator: ",\n")
    } else {
        items = value.map { (key, value) -> String in
            return "[\(key)]: [\(value)]"
            }.joined(separator: ", ")
    }
    let log = ">>> \(items)\n"
    try! log.appendToURL(fileURL: logPathUrl)
}
