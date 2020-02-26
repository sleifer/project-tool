//
//  RunScriptBuildSetting.swift
//  project-tool
//
//  Created by Simeon Leifer on 2/27/20.
//  Copyright © 2020 droolingcat.com. All rights reserved.
//

import Foundation

class RunScriptBuildSetting: Codable {
    var key: String
    var value: String?
    var values: [String]?
    var configurations: [String]?
}
