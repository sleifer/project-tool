//
//  RunScriptEntry.swift
//  project-tool
//
//  Created by Simeon Leifer on 2/26/20.
//  Copyright © 2020 droolingcat.com. All rights reserved.
//

import Foundation

class RunScriptEntry: Codable, Comparable {
    var name: String
    var description: String
    var scriptPhaseTitle: String
    var scriptPhaseScript: String
    var scriptPhaseShell: String
    var scriptPhaseShowEnv: Bool
    var lastNotFirst: Bool?
    var files: [RunScriptFile]?
    var buildSettings: [RunScriptBuildSetting]?

    init() {
        name = ""
        description = ""
        scriptPhaseTitle = ""
        scriptPhaseScript = ""
        scriptPhaseShell = "/bin/sh"
        scriptPhaseShowEnv = false
    }

    static func < (lhs: RunScriptEntry, rhs: RunScriptEntry) -> Bool {
        if lhs.name < rhs.name {
            return true
        }
        return false
    }

    static func == (lhs: RunScriptEntry, rhs: RunScriptEntry) -> Bool {
        if lhs.name == rhs.name {
            return true
        }
        return false
    }
}
