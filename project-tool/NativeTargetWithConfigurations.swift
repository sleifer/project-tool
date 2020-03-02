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
    var versionsSwiftFilename: String = "versions.swift"

    init(target: PBXNativeTarget) {
        self.target = target
        self.configurations = []
        self.gatherTargets()
    }

    private func gatherTargets() {
        if let configurations = target.getBuildConfigurationList()?.getBuildConfigurations() {
            self.configurations.append(contentsOf: configurations)
        }
    }
}

extension Array where Element == NativeTargetWithConfigurations {
    func makeVersionsSwiftUnique() {
        if self.count > 1 {
            for (index, item) in self.enumerated() {
                let suffix = item.target.name ?? "\(index + 1)"
                let name = "versions \(suffix).swift".replacingOccurrences(of: " ", with: "_")
                item.versionsSwiftFilename = name
            }
        }
    }
}
