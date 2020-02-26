//
//  RunScriptCatalog.swift
//  project-tool
//
//  Created by Simeon Leifer on 2/26/20.
//  Copyright © 2020 droolingcat.com. All rights reserved.
//

import Foundation

class RunScriptCatalog: Codable, JSONReadWrite {
    typealias HostClass = RunScriptCatalog

    var entries: [RunScriptEntry]

    init() {
        entries = []
    }

    func entry(withName name: String) -> RunScriptEntry? {
        return entries.filter { (entry) -> Bool in
            return entry.name == name
        }.first
    }
}
