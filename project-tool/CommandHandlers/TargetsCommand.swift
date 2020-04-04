//
//  TargetsCommand.swift
//  project-tool
//
//  Created by Simeon Leifer on 4/4/20.
//  Copyright © 2020 droolingcat.com. All rights reserved.
//

import Cocoa
import CommandLineCore

class TargetsCommand: Command {
    required init() {
    }

    func run(cmd: ParsedCommand, core: CommandCore) {
        if let proj = Helpers.findXcodeProject(FileManager.default.currentDirectoryPath, ignoreWorkspaces: true) {
            let targets = Helpers.findProjectTargets(proj)
            print("Targets:")
            for target in targets.sorted() {
                print(target)
            }
        } else {
            print("Could not locate Xcode project.")
        }
    }

    static func commandDefinition() -> SubcommandDefinition {
        var command = SubcommandDefinition()
        command.name = "targets"
        command.synopsis = "List project targets."

        return command
    }
}
