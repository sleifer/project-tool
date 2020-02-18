//
//  GenericVersionState.swift
//  project-tool
//
//  Created by Simeon Leifer on 2/18/20.
//  Copyright © 2020 droolingcat.com. All rights reserved.
//

import Foundation

class GenericVersionState: Codable, JSONReadWrite {
    typealias HostClass = GenericVersionState

    var marketingVersion: String
    var projectVersion: String

    init() {
        marketingVersion = "1.0"
        projectVersion = "1"
    }

    init(marketing: String, project: String) {
        marketingVersion = marketing
        projectVersion = project
    }
}
