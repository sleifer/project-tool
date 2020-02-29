//
//  NativeTargetWithConfigurations.swift
//  project-tool
//
//  Created by Simeon Leifer on 2/29/20.
//  Copyright © 2020 droolingcat.com. All rights reserved.
//

import Foundation
import ProjectWalker

class NativeTargetWithConfigurations {
    var target: PBXNativeTarget
    var configurations: [XCBuildConfiguration]
    var infoPlistFileUrl: URL?
    var versionSystemState: VersionSystemState = .unknown
    var marketingVersion: String = "1.0"
    var projectVersion: String = "1"
    var runScriptState: RunScriptState = .unknown
    var derivedSourceState: DerivedSourceState = .unknown

    init(target: PBXNativeTarget) {
        self.target = target
        configurations = []
        gatherTargets()
    }

    private func gatherTargets() {
        if  let configurations = target.getBuildConfigurationList()?.getBuildConfigurations() {
            self.configurations.append(contentsOf: configurations)
        }
    }
}
